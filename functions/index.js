const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// Cloud Function: Procesar ubicación del usuario
exports.processUserLocation = functions.firestore
  .document('users/{userId}/location_history/{locationId}')
  .onCreate(async (snap, context) => {
    const locationData = snap.data();
    const userId = context.params.userId;
    
    // Obtener todas las estaciones
    const stationsSnapshot = await db.collection('stations').get();
    const stations = stationsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    // Encontrar estación más cercana
    let nearestStation = null;
    let minDistance = Infinity;
    
    const userLat = locationData.ubicacion.latitude;
    const userLon = locationData.ubicacion.longitude;
    
    for (const station of stations) {
      const stationLat = station.ubicacion.latitude;
      const stationLon = station.ubicacion.longitude;
      
      const distance = calculateDistance(
        userLat,
        userLon,
        stationLat,
        stationLon
      );
      
      if (distance < minDistance && distance < 0.5) { // 500 metros
        minDistance = distance;
        nearestStation = station;
      }
    }
    
    // Si el usuario está cerca de una estación, actualizar contador de usuarios
    if (nearestStation) {
      await db.collection('stations').doc(nearestStation.id).update({
        'usuarios_cercanos': admin.firestore.FieldValue.increment(1),
        'ultima_actualizacion': admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    return null;
  });

// Cloud Function: Calcular posiciones de trenes basado en usuarios
exports.calculateTrainPositions = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    // Obtener todos los usuarios con ubicación reciente (últimos 5 minutos)
    const fiveMinutesAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 5 * 60 * 1000)
    );
    
    const usersSnapshot = await db.collection('users')
      .where('ultima_ubicacion_timestamp', '>=', fiveMinutesAgo)
      .get();
    
    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    // Agrupar usuarios por estación cercana
    const stationGroups = {};
    
    for (const user of users) {
      if (!user.ultima_ubicacion) continue;
      
      const userLat = user.ultima_ubicacion.latitude;
      const userLon = user.ultima_ubicacion.longitude;
      
      // Encontrar estación más cercana
      const stationsSnapshot = await db.collection('stations').get();
      let nearestStation = null;
      let minDistance = Infinity;
      
      stationsSnapshot.docs.forEach(doc => {
        const station = { id: doc.id, ...doc.data() };
        const stationLat = station.ubicacion.latitude;
        const stationLon = station.ubicacion.longitude;
        
        const distance = calculateDistance(
          userLat,
          userLon,
          stationLat,
          stationLon
        );
        
        if (distance < minDistance && distance < 0.5) {
          minDistance = distance;
          nearestStation = station;
        }
      });
      
      if (nearestStation) {
        if (!stationGroups[nearestStation.id]) {
          stationGroups[nearestStation.id] = [];
        }
        stationGroups[nearestStation.id].push(user);
      }
    }
    
    // Actualizar contadores de usuarios por estación
    const batch = db.batch();
    for (const [stationId, users] of Object.entries(stationGroups)) {
      const stationRef = db.collection('stations').doc(stationId);
      batch.update(stationRef, {
        'usuarios_cercanos': users.length,
        'ultima_actualizacion': admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    await batch.commit();
    
    // Calcular posiciones estimadas de trenes basado en densidad de usuarios
    const trainsSnapshot = await db.collection('trains').get();
    const updatePromises = trainsSnapshot.docs.map(async (trainDoc) => {
      const train = { id: trainDoc.id, ...trainDoc.data() };
      
      // Lógica simplificada: si hay muchos usuarios en una estación,
      // es probable que un tren esté llegando
      // En producción, esto debería ser más sofisticado
      
      return trainDoc.ref.update({
        'ultima_actualizacion': admin.firestore.FieldValue.serverTimestamp()
      });
    });
    
    await Promise.all(updatePromises);
    
    return null;
  });

// Función auxiliar: Calcular distancia entre dos puntos (Haversine)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radio de la Tierra en km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  return distance;
}

function toRad(degrees) {
  return (degrees * Math.PI) / 180;
}

// Cloud Function: Procesar nuevo reporte
exports.processNewReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;

    try {
      // 1. VERIFICACIÓN AUTOMÁTICA
      await verifyReportAutomatically(report, reportId);

      // 2. ACTUALIZAR ESTADO DE ESTACIÓN/TREN
      await updateStationStatus(report);

      // 3. NOTIFICACIONES A USUARIOS AFECTADOS
      await sendRelevantNotifications(report);

      // 4. CALCULAR IMPACTO EN RUTAS
      await updateRouteEstimates(report);

      return null;
    } catch (error) {
      console.error('Error processing new report:', error);
      return null;
    }
  });

// Verificar reporte automáticamente si hay reportes similares
async function verifyReportAutomatically(report, reportId) {
  try {
    const objetivoId = report.objetivo_id;
    const estadoPrincipal = report.estado_principal;
    const createdAt = report.creado_en.toDate();
    const tenMinutesAgo = new Date(createdAt.getTime() - 10 * 60 * 1000);

    // Buscar reportes similares
    const similarReports = await db.collection('reports')
      .where('objetivo_id', '==', objetivoId)
      .where('estado_principal', '==', estadoPrincipal)
      .where('creado_en', '>', admin.firestore.Timestamp.fromDate(tenMinutesAgo))
      .where('estado', '==', 'activo')
      .get();

    // Si hay 2 o más reportes similares, marcar como verificado
    if (similarReports.docs.length >= 2) {
      await db.collection('reports').doc(reportId).update({
        'verification_status': 'verified',
        'confidence': 0.8,
      });
    }
  } catch (error) {
    console.error('Error in automatic verification:', error);
  }
}

// Actualizar estado de estación/tren basado en reportes
async function updateStationStatus(report) {
  try {
    const objetivoId = report.objetivo_id;
    const tipo = report.tipo;
    const estadoPrincipal = report.estado_principal;
    const verificationStatus = report.verification_status;

    // Solo actualizar si está verificado por la comunidad
    if (verificationStatus !== 'community_verified') {
      return;
    }

    if (tipo === 'estacion') {
      // Obtener reportes recientes verificados (últimos 15 min)
      const fifteenMinutesAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 15 * 60 * 1000)
      );

      const recentReports = await db.collection('reports')
        .where('objetivo_id', '==', objetivoId)
        .where('verification_status', 'in', ['verified', 'community_verified'])
        .where('creado_en', '>', fifteenMinutesAgo)
        .where('estado', '==', 'activo')
        .get();

      if (recentReports.docs.length > 0) {
        // Calcular estado consenso (el más común)
        const estados = recentReports.docs.map(doc => doc.data().estado_principal);
        const estadoConsenso = getMostCommon(estados);

        if (estadoConsenso) {
          // Mapear estadoPrincipal a estadoActual
          let estadoActual = null;
          switch (estadoConsenso) {
            case 'normal':
              estadoActual = 'normal';
              break;
            case 'moderado':
              estadoActual = 'moderado';
              break;
            case 'lleno':
              estadoActual = 'lleno';
              break;
            case 'cerrado':
              estadoActual = 'cerrado';
              break;
          }

          if (estadoActual) {
            await db.collection('stations').doc(objetivoId).update({
              'estado_actual': estadoActual,
              'ultima_actualizacion': admin.firestore.FieldValue.serverTimestamp(),
              'report_count': recentReports.docs.length,
            });
          }
        }
      }
    } else if (tipo === 'tren') {
      // Similar para trenes
      const fifteenMinutesAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 15 * 60 * 1000)
      );

      const recentReports = await db.collection('reports')
        .where('objetivo_id', '==', objetivoId)
        .where('verification_status', 'in', ['verified', 'community_verified'])
        .where('creado_en', '>', fifteenMinutesAgo)
        .where('estado', '==', 'activo')
        .get();

      if (recentReports.docs.length > 0) {
        const estados = recentReports.docs.map(doc => doc.data().estado_principal);
        const estadoConsenso = getMostCommon(estados);

        if (estadoConsenso) {
          let estadoTren = null;
          switch (estadoConsenso) {
            case 'asientos_disponibles':
            case 'de_pie_comodo':
              estadoTren = 'normal';
              break;
            case 'sardina':
              estadoTren = 'retrasado';
              break;
            case 'lento':
            case 'detenido':
              estadoTren = 'detenido';
              break;
          }

          if (estadoTren) {
            await db.collection('trains').doc(objetivoId).update({
              'estado': estadoTren,
              'ultima_actualizacion': admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      }
    }
  } catch (error) {
    console.error('Error updating station/train status:', error);
  }
}

// Enviar notificaciones relevantes
async function sendRelevantNotifications(report) {
  try {
    const objetivoId = report.objetivo_id;
    const tipo = report.tipo;
    const estadoPrincipal = report.estado_principal;
    const prioridad = report.prioridad || false;

    // Solo notificar reportes críticos o prioritarios
    const isCritical = prioridad || 
      estadoPrincipal === 'lleno' || 
      estadoPrincipal === 'cerrado' || 
      estadoPrincipal === 'detenido' ||
      estadoPrincipal === 'sardina';

    if (!isCritical) {
      return; // No notificar reportes normales
    }

    // Obtener usuarios que tienen esta estación como favorita
    // (esto requeriría un campo en users con estaciones favoritas)
    
    // Obtener usuarios cercanos (dentro de 5 km)
    const reportLocation = report.ubicacion;
    const usersSnapshot = await db.collection('users')
      .where('ultima_ubicacion', '!=', null)
      .get();

    const nearbyUsers = [];
    for (const userDoc of usersSnapshot.docs) {
      const user = userDoc.data();
      if (!user.ultima_ubicacion) continue;

      const distance = calculateDistance(
        reportLocation.latitude,
        reportLocation.longitude,
        user.ultima_ubicacion.latitude,
        user.ultima_ubicacion.longitude
      );

      if (distance <= 5) { // 5 km
        nearbyUsers.push({
          id: userDoc.id,
          fcmToken: user.fcm_token,
          nombre: user.nombre,
        });
      }
    }

    // Enviar notificaciones push
    const messaging = admin.messaging();
    const messages = nearbyUsers
      .filter(user => user.fcmToken)
      .map(user => ({
        token: user.fcmToken,
        notification: {
          title: tipo === 'estacion' ? '🚨 Alerta en Estación' : '🚨 Alerta en Tren',
          body: `Nuevo reporte: ${getEstadoText(estadoPrincipal)}`,
        },
        data: {
          type: 'report',
          reportId: report.id || '',
          objetivoId: objetivoId,
          tipo: tipo,
        },
      }));

    if (messages.length > 0) {
      await messaging.sendAll(messages);
      console.log(`Sent ${messages.length} notifications for report ${report.id || 'unknown'}`);
    }
  } catch (error) {
    console.error('Error sending notifications:', error);
  }
}

// Actualizar estimaciones de rutas
async function updateRouteEstimates(report) {
  try {
    // Esta función actualizaría los tiempos estimados de rutas
    // que pasan por la estación/tren afectado
    // Por ahora, solo loggear
    console.log('Route estimates would be updated for:', report.objetivo_id);
  } catch (error) {
    console.error('Error updating route estimates:', error);
  }
}

// Función auxiliar: obtener el valor más común en un array
function getMostCommon(arr) {
  if (arr.length === 0) return null;
  
  const counts = {};
  arr.forEach(item => {
    counts[item] = (counts[item] || 0) + 1;
  });
  
  let maxCount = 0;
  let mostCommon = null;
  for (const [item, count] of Object.entries(counts)) {
    if (count > maxCount) {
      maxCount = count;
      mostCommon = item;
    }
  }
  
  return mostCommon;
}

// Función auxiliar: obtener texto del estado
function getEstadoText(estadoPrincipal) {
  const estados = {
    'normal': 'Normal',
    'moderado': 'Moderado',
    'lleno': 'Lleno',
    'retraso': 'Retraso',
    'cerrado': 'Cerrado',
    'asientos_disponibles': 'Asientos Disponibles',
    'de_pie_comodo': 'De Pie Cómodo',
    'sardina': 'Sardina',
    'express': 'Express',
    'lento': 'Lento',
    'detenido': 'Detenido',
  };
  return estados[estadoPrincipal] || estadoPrincipal;
}

// Cloud Function: Procesar confirmación de reporte
exports.processReportConfirmation = functions.firestore
  .document('reports/{reportId}/confirmations/{userId}')
  .onCreate(async (snap, context) => {
    const reportId = context.params.reportId;
    const userId = context.params.userId;

    try {
      // Obtener el reporte
      const reportDoc = await db.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) return null;

      const report = reportDoc.data();
      const confirmationCount = report.confirmation_count || 0;

      // Si alcanza 3 confirmaciones, marcar como verificado por la comunidad
      if (confirmationCount >= 3) {
        await db.collection('reports').doc(reportId).update({
          'verification_status': 'community_verified',
          'confidence': 0.9,
        });

        // Actualizar estado de estación/tren
        await updateStationStatus(report);

        // Notificar al creador del reporte
        const creatorId = report.usuario_id;
        if (creatorId) {
          const creatorDoc = await db.collection('users').doc(creatorId).get();
          if (creatorDoc.exists) {
            const creator = creatorDoc.data();
            if (creator.fcm_token) {
              const messaging = admin.messaging();
              await messaging.send({
                token: creator.fcm_token,
                notification: {
                  title: '🎉 ¡Tu reporte fue verificado!',
                  body: '3 usuarios confirmaron tu reporte. ¡Gracias por ayudar a la comunidad!',
                },
                data: {
                  type: 'report_verified',
                  reportId: reportId,
                },
              });
            }
          }
        }
      }

      return null;
    } catch (error) {
      console.error('Error processing confirmation:', error);
      return null;
    }
  });

