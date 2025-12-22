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
      const confirmationCount = report.confirmations || report.confirmation_count || 0;

      // Si alcanza 3 confirmaciones, marcar como verificado por la comunidad
      if (confirmationCount >= 3) {
        await db.collection('reports').doc(reportId).update({
          'verification_status': 'community_verified',
          'confidence': 0.9,
        });

        // Actualizar estado de estación/tren con agregación completa
        if (report.scope === 'station' && report.stationId) {
          await updateStationStatus(report.stationId, report);
        } else if (report.scope === 'train' && report.stationId) {
          // Actualizar estado de tren cuando alcanza 3 confirmaciones
          await updateTrainStatusAggregated(report.stationId, report);
        }

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

// Cloud Function: Generar datos iniciales de trenes basados en horarios
// DESHABILITADO: Los datos se construirán desde los reportes de usuarios
// Si necesitas datos iniciales, descomenta y ejecuta manualmente
/*
exports.generateInitialTrainData = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    try {
      const now = new Date();
      const hour = now.getHours();
      const minute = now.getMinutes();
      
      // Determinar frecuencia según hora
      let frequencyMinutes;
      if ((hour >= 6 && hour <= 9) || (hour >= 16 && hour <= 19)) {
        frequencyMinutes = 5; // Hora pico
      } else {
        frequencyMinutes = 10; // Hora valle
      }
      
      // Obtener estaciones para calcular posiciones
      const stationsSnapshot = await db.collection('stations').get();
      const stationsByLine = {
        linea1: [],
        linea2: []
      };
      
      stationsSnapshot.docs.forEach(doc => {
        const station = { id: doc.id, ...doc.data() };
        if (station.linea === 'linea1') {
          stationsByLine.linea1.push(station);
        } else if (station.linea === 'linea2') {
          stationsByLine.linea2.push(station);
        }
      });
      
      // Ordenar estaciones por nombre (asumiendo orden lógico)
      stationsByLine.linea1.sort((a, b) => a.nombre.localeCompare(b.nombre));
      stationsByLine.linea2.sort((a, b) => a.nombre.localeCompare(b.nombre));
      
      // Generar trenes para cada línea y dirección
      const trains = [];
      const lines = ['linea1', 'linea2'];
      const directions = ['norte', 'sur'];
      
      for (const line of lines) {
        const stations = stationsByLine[line];
        if (stations.length === 0) continue;
        
        for (const direction of directions) {
          const trainId = `${line}_${direction}_001`;
          
          // Calcular posición estimada basada en horario
          const minutesSinceHourStart = minute;
          const positionInCycle = (minutesSinceHourStart % frequencyMinutes) / frequencyMinutes;
          
          // Calcular segmento actual (simplificado)
          const totalStations = stations.length;
          const segmentIndex = Math.floor(positionInCycle * (totalStations - 1));
          const segmentPosition = (positionInCycle * (totalStations - 1)) % 1;
          
          const fromStation = stations[Math.min(segmentIndex, totalStations - 1)];
          const toStation = stations[Math.min(segmentIndex + 1, totalStations - 1)];
          
          // Interpolar posición entre estaciones
          const fromLat = fromStation.ubicacion.latitude;
          const fromLon = fromStation.ubicacion.longitude;
          const toLat = toStation.ubicacion.latitude;
          const toLon = toStation.ubicacion.longitude;
          
          const currentLat = fromLat + (toLat - fromLat) * segmentPosition;
          const currentLon = fromLon + (toLon - fromLon) * segmentPosition;
          
          trains.push({
            id: trainId,
            linea: line,
            direccion: direction,
            ubicacion_actual: new admin.firestore.GeoPoint(currentLat, currentLon),
            velocidad: 35, // Velocidad promedio estimada
            estado: 'normal',
            aglomeracion: 2, // Moderado por defecto
            confidence: 'low', // CRÍTICO: Marcar como baja confianza
            is_estimated: true, // Flag para indicar que es estimado
            ultima_actualizacion: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Guardar en Firestore
      const batch = db.batch();
      for (const train of trains) {
        const trainRef = db.collection('trains').doc(train.id);
        batch.set(trainRef, train, { merge: true });
      }
      await batch.commit();
      
      console.log(`Generated ${trains.length} estimated trains`);
      return null;
    } catch (error) {
      console.error('Error generating initial train data:', error);
      return null;
    }
  });
*/

// Cloud Function: Actualizar estadísticas comunitarias
exports.updateCommunityStats = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    try {
      const statsRef = db.collection('community_stats').doc('founder_week');
      
      // Contar reportes de últimos 7 días
      const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
      );
      
      const reportsSnapshot = await db.collection('reports')
        .where('creado_en', '>=', sevenDaysAgo)
        .get();
      
      // Contar estaciones activas (con al menos 1 reporte)
      const activeStations = new Set();
      reportsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        if (data.tipo === 'estacion' && data.objetivo_id) {
          activeStations.add(data.objetivo_id);
        }
      });
      
      // Contar participantes únicos
      const participants = new Set();
      reportsSnapshot.docs.forEach(doc => {
        if (doc.data().usuario_id) {
          participants.add(doc.data().usuario_id);
        }
      });
      
      await statsRef.set({
        total_reports: reportsSnapshot.size,
        active_stations: activeStations.size,
        participants: participants.size,
        last_updated: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      
      console.log(`Updated community stats: ${reportsSnapshot.size} reports, ${activeStations.size} stations, ${participants.size} participants`);
      return null;
    } catch (error) {
      console.error('Error updating community stats:', error);
      return null;
    }
  });

// ============================================
// SISTEMA DE VALIDACIONES ETA MEJORADO
// ============================================

// Cloud Function: Procesar creación de reporte mejorado
exports.onReportCreated = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    try {
      const report = snapshot.data();
      const reportId = context.params.reportId;
      
      // 1. Calcular puntos base
      let basePoints = 0;
      let bonusPoints = 0;
      
      if (report.scope === 'station') {
        basePoints = 15; // Reporte de estación básico
        bonusPoints = (report.stationIssues?.length || 0) * 5;
      } else if (report.scope === 'train') {
        // Sistema nuevo: 10 base por copiar panel + 5 por cada problema
        // +20 puntos adicionales se otorgan cuando se valida la llegada
        basePoints = 10; // Reporte de tren (copiar del panel)
        bonusPoints = (report.trainIssues?.length || 0) * 5;
      }
      
      // 2. Actualizar reporte con puntos
      await snapshot.ref.update({
        basePoints: basePoints,
        bonusPoints: bonusPoints,
        totalPoints: basePoints + bonusPoints,
        confidence: calculateInitialConfidence(report)
      });
      
      // 3. Si es reporte de tren con ETA, programar validación
      if (report.scope === 'train' && report.etaBucket && report.etaBucket !== 'unknown') {
        await scheduleETAValidation(reportId, report);
      }
      
      // 4. Actualizar estadísticas de usuario
      await updateUserStats(report.userId, basePoints + bonusPoints);
      
      // 5. Actualizar estado de estación si aplica (con agregación completa)
      if (report.scope === 'station' && report.stationId) {
        await updateStationStatus(report.stationId, report);
      }
      
      // 6. Actualizar estado de tren si aplica (con agregación completa)
      if (report.scope === 'train' && report.stationId) {
        // Nota: Para trenes, necesitamos el trainId. Por ahora usamos stationId como referencia
        // TODO: Mejorar cuando tengamos trainId en los reportes
        await updateTrainStatusAggregated(report.stationId, report);
      }
      
      console.log(`Report ${reportId} processed: ${basePoints + bonusPoints} points`);
      return { success: true, points: basePoints + bonusPoints };
    } catch (error) {
      console.error('Error processing report:', error);
      return null;
    }
  });

// Función auxiliar: Programar validación ETA
async function scheduleETAValidation(reportId, report) {
  try {
    // El etaExpectedAt ya viene calculado desde el cliente
    // Solo necesitamos programar la notificación push
    if (!report.etaExpectedAt) {
      console.log(`No etaExpectedAt for report ${reportId}, skipping validation scheduling`);
      return;
    }

    const expectedArrival = report.etaExpectedAt.toDate();
    const now = new Date();
    
    // Calcular cuándo enviar la notificación (etaBucket + 1 minuto de tolerancia)
    const timingConfig = {
      '1-2': 1.5, // minutos (punto medio)
      '3-5': 4.0,
      '6-8': 7.0,
      '9+': 10.0,
    };
    
    const bucketMinutes = timingConfig[report.etaBucket] || 4.0;
    const notificationDelay = (bucketMinutes + 1) * 60 * 1000; // +1 minuto de tolerancia
    const notificationTime = new Date(now.getTime() + notificationDelay);
    
    // Crear tarea programada para notificación
    // Nota: Firebase no tiene programación nativa, usaremos un enfoque alternativo
    // Guardar en una colección de notificaciones pendientes que se procesa periódicamente
    await db.collection('pendingValidations').add({
      reportId: reportId,
      userId: report.userId,
      stationId: report.stationId,
      etaBucket: report.etaBucket,
      expectedArrival: report.etaExpectedAt,
      notificationTime: admin.firestore.Timestamp.fromDate(notificationTime),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending'
    });
    
    // Marcar reporte como que necesita validación
    await db.collection('reports').doc(reportId).update({
      'needsValidation': true,
      'validationStatus': 'pending'
    });
    
    console.log(`Validation scheduled for report ${reportId}, notification at ${notificationTime}`);
  } catch (error) {
    console.error(`Error scheduling ETA validation for report ${reportId}:`, error);
  }
}

// Cloud Function: Procesar respuesta de validación ETA
exports.processValidationResponse = functions.https.onCall(async (data, context) => {
  // Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Debes iniciar sesión');
  }
  
  const userId = context.auth.uid;
  const { reportId, result, actualArrivalTime } = data;
  
  try {
    // 1. Verificar que el usuario puede validar este reporte
    const reportDoc = await db.collection('reports').doc(reportId).get();
    if (!reportDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Reporte no encontrado');
    }
    
    const report = reportDoc.data();
    
    if (report.userId !== userId) {
      throw new functions.https.HttpsError('permission-denied', 'No puedes validar este reporte');
    }
    
    // Verificar que el reporte necesita validación (nuevo modelo simplificado)
    if (report.scope !== 'train' || !report.etaBucket || report.etaBucket === 'unknown') {
      throw new functions.https.HttpsError('failed-precondition', 'Este reporte no requiere validación');
    }
    
    if (report.arrivalTime) {
      throw new functions.https.HttpsError('failed-precondition', 'Validación ya procesada');
    }
    
    // 2. Calcular puntos por validación y error del panel
    let validationPoints = 20; // Base por validar
    let timeErrorMinutes = null;
    let precisionBonus = 0;
    
    if (result === 'arrived' && actualArrivalTime && report.etaExpectedAt) {
      const expectedArrival = report.etaExpectedAt.toDate();
      const actualArrival = new Date(actualArrivalTime);
      
      timeErrorMinutes = Math.round((actualArrival - expectedArrival) / (1000 * 60));
      const absError = Math.abs(timeErrorMinutes);
      
      // Sistema de puntos por precisión del panel:
      // ±1 min = +15 puntos (panel preciso)
      // ±2-3 min = +5 puntos (error pequeño)
      // Mayor error = +0 puntos (pero igual ayuda al sistema)
      if (absError <= 1) {
        precisionBonus = 15;
      } else if (absError <= 3) {
        precisionBonus = 5;
      }
      
      validationPoints += precisionBonus;
      
      // Actualizar calibración de la estación si es reporte del panel
      if (report.isPanelTime === true && report.stationId) {
        await updateStationPanelCalibration(report.stationId, timeErrorMinutes, report.etaBucket);
      }
    } else if (result === 'not_arrived') {
      validationPoints = 15;
    } else if (result === 'cant_confirm') {
      validationPoints = 0;
    }
    
    // 3. Actualizar reporte con arrivalTime y puntos
    const batch = db.batch();
    
    const reportRef = db.collection('reports').doc(reportId);
    const updates = {
      'arrivalTime': actualArrivalTime ? 
        admin.firestore.Timestamp.fromDate(new Date(actualArrivalTime)) : null,
      'bonusPoints': admin.firestore.FieldValue.increment(precisionBonus),
      'totalPoints': admin.firestore.FieldValue.increment(validationPoints),
    };
    
    batch.update(reportRef, updates);
    
    // Crear registro en subcolección de validaciones ETA
    if (actualArrivalTime && report.etaExpectedAt) {
      const validationRef = reportRef.collection('eta_validations').doc(userId);
      batch.set(validationRef, {
        userId: userId,
        result: result,
        answeredAt: admin.firestore.FieldValue.serverTimestamp(),
        actualArrival: admin.firestore.Timestamp.fromDate(new Date(actualArrivalTime)),
        expectedArrival: report.etaExpectedAt,
        deltaMinutes: timeErrorMinutes,
        pointsAwarded: validationPoints
      });
    }
    
    // 4. Actualizar estadísticas del usuario
    const userRef = db.collection('users').doc(userId);
    batch.update(userRef, {
      'gamification.puntos': admin.firestore.FieldValue.increment(validationPoints),
    });
    
    await batch.commit();
    
    return {
      success: true,
      pointsAwarded: validationPoints,
      accuracy: accuracyBucket,
      totalPoints: report.totalPoints + validationPoints
    };
  } catch (error) {
    console.error('Error processing validation:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Función auxiliar: Calcular confianza inicial
function calculateInitialConfidence(report) {
  let confidence = 0.5; // Base
  
  if (report.scope === 'station' && report.stationIssues?.length > 0) {
    confidence += 0.1;
  }
  
  if (report.scope === 'train' && report.etaBucket && report.etaBucket !== 'unknown') {
    confidence += 0.1;
  }
  
  return Math.min(1.0, confidence);
}

// Función auxiliar: Actualizar estadísticas de usuario
async function updateUserStats(userId, points) {
  try {
    await db.collection('users').doc(userId).update({
      'gamification.puntos': admin.firestore.FieldValue.increment(points),
      'gamification.reportes_count': admin.firestore.FieldValue.increment(1),
    });
  } catch (error) {
    console.error(`Error updating user stats for ${userId}:`, error);
  }
}

// Función auxiliar: Actualizar estado de estación con agregación de múltiples reportes
async function updateStationStatus(stationId, newReport) {
  try {
    const stationRef = db.collection('stations').doc(stationId);
    const now = admin.firestore.Timestamp.now();
    const thirtyMinutesAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 60 * 1000)
    );

    // Obtener todos los reportes activos de la estación de los últimos 30 minutos
    const reportsSnapshot = await db.collection('reports')
      .where('stationId', '==', stationId)
      .where('scope', '==', 'station')
      .where('status', '==', 'active')
      .get();

    // Filtrar reportes de los últimos 30 minutos y que tengan datos relevantes
    const recentReports = reportsSnapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(report => {
        const createdAt = report.createdAt?.toDate();
        return createdAt && createdAt >= thirtyMinutesAgo.toDate() &&
               (report.stationOperational || report.stationCrowd);
      });

    if (recentReports.length === 0) {
      // No hay reportes recientes, usar solo el nuevo reporte si tiene datos
      if (!newReport.stationOperational || !newReport.stationCrowd) return;
      
      await stationRef.update({
        'estado_actual': mapOperationalToEstado(newReport.stationOperational, newReport.stationCrowd),
        'aglomeracion': newReport.stationCrowd,
        'confidence': 'low',
        'ultima_actualizacion': now,
        'is_estimated': false,
      });
      return;
    }

    // Calcular estado agregado
    const estados = recentReports
      .map(r => mapOperationalToEstado(r.stationOperational, r.stationCrowd))
      .filter(e => e !== null);

    if (estados.length === 0) return;

    let estadoActual;
    if (estados.length === 1) {
      estadoActual = estados[0];
    } else if (estados.length <= 4) {
      // Moda (más común)
      estadoActual = getMostCommon(estados);
    } else {
      // Promedio ponderado por confirmaciones
      estadoActual = getWeightedAverageEstado(recentReports, estados);
    }

    // Calcular aglomeracion promedio
    const crowdLevels = recentReports
      .filter(r => r.stationCrowd)
      .map(r => r.stationCrowd);
    const aglomeracion = crowdLevels.length > 0
      ? Math.round(crowdLevels.reduce((a, b) => a + b, 0) / crowdLevels.length)
      : 1;
    const aglomeracionClamped = Math.max(1, Math.min(5, aglomeracion));

    // Calcular confidence
    const reportCountScore = Math.min(0.4, recentReports.length / 10);
    const totalConfirmations = recentReports.reduce((sum, r) => sum + (r.confirmations || 0), 0);
    const confirmationScore = Math.min(0.3, totalConfirmations / 20);
    
    // Recency score (reportes más recientes pesan más)
    let recencyScore = 0;
    const nowDate = new Date();
    for (const report of recentReports) {
      const ageMinutes = (nowDate - report.createdAt.toDate()) / (1000 * 60);
      const weight = Math.max(0, (30 - ageMinutes) / 30);
      recencyScore += weight;
    }
    recencyScore = Math.min(0.3, recencyScore / recentReports.length);

    const confidenceValue = Math.min(1.0, reportCountScore + confirmationScore + recencyScore);
    const confidence = confidenceValue >= 0.7 ? 'high' : confidenceValue >= 0.4 ? 'medium' : 'low';

    // Actualizar estación
    await stationRef.update({
      'estado_actual': estadoActual,
      'aglomeracion': aglomeracionClamped,
      'confidence': confidence,
      'ultima_actualizacion': now,
      'is_estimated': false,
    });

    console.log(`Station ${stationId} status updated from ${recentReports.length} reports`);
  } catch (error) {
    console.error(`Error updating station status for ${stationId}:`, error);
  }
}

// Función auxiliar: Mapear operational + crowd a estado
function mapOperationalToEstado(operational, crowd) {
  if (!operational) return null;
  
  if (operational === 'no') return 'cerrado';
  if (operational === 'partial') return 'moderado';
  if (operational === 'yes') {
    if (!crowd) return 'normal';
    if (crowd <= 2) return 'normal';
    if (crowd === 3) return 'moderado';
    return 'lleno'; // crowd >= 4
  }
  return null;
}

// Función auxiliar: Obtener promedio ponderado por confirmaciones
function getWeightedAverageEstado(reports, estados) {
  const weights = {};
  
  for (let i = 0; i < reports.length && i < estados.length; i++) {
    const report = reports[i];
    const estado = estados[i];
    const weight = 1.0 + (report.confirmations || 0) * 0.5;
    weights[estado] = (weights[estado] || 0) + weight;
  }

  let maxWeight = 0;
  let maxEstado = estados[0];
  for (const [estado, weight] of Object.entries(weights)) {
    if (weight > maxWeight) {
      maxWeight = weight;
      maxEstado = estado;
    }
  }

  return maxEstado;
}

// Función auxiliar: Actualizar estado de tren con agregación de múltiples reportes
async function updateTrainStatusAggregated(stationId, newReport) {
  try {
    // Nota: Por ahora usamos stationId para buscar reportes de trenes
    // En el futuro, deberíamos tener trainId en los reportes
    const now = admin.firestore.Timestamp.now();
    const thirtyMinutesAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 60 * 1000)
    );

    // Obtener todos los reportes activos de trenes de los últimos 30 minutos
    // Filtrar por stationId y scope === 'train'
    const reportsSnapshot = await db.collection('reports')
      .where('stationId', '==', stationId)
      .where('scope', '==', 'train')
      .where('status', '==', 'active')
      .get();

    // Filtrar reportes de los últimos 30 minutos y que tengan datos relevantes
    const recentReports = reportsSnapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(report => {
        const createdAt = report.createdAt?.toDate();
        return createdAt && createdAt >= thirtyMinutesAgo.toDate() &&
               (report.trainStatus || report.trainCrowd);
      });

    if (recentReports.length === 0) {
      // No hay reportes recientes, no actualizar
      return;
    }

    // Calcular estado agregado (normal/slow/stopped)
    const estados = recentReports
      .map(r => mapTrainStatusToEstado(r.trainStatus, r.trainCrowd))
      .filter(e => e !== null);

    if (estados.length === 0) return;

    let estadoTren;
    if (estados.length === 1) {
      estadoTren = estados[0];
    } else if (estados.length <= 4) {
      // Moda (más común)
      estadoTren = getMostCommon(estados);
    } else {
      // Promedio ponderado por confirmaciones
      estadoTren = getWeightedAverageTrainEstado(recentReports, estados);
    }

    // Calcular aglomeracion promedio
    const crowdLevels = recentReports
      .filter(r => r.trainCrowd)
      .map(r => r.trainCrowd);
    const aglomeracion = crowdLevels.length > 0
      ? Math.round(crowdLevels.reduce((a, b) => a + b, 0) / crowdLevels.length)
      : 1;
    const aglomeracionClamped = Math.max(1, Math.min(5, aglomeracion));

    // Calcular confidence (similar a estaciones)
    const reportCountScore = Math.min(0.4, recentReports.length / 10);
    const totalConfirmations = recentReports.reduce((sum, r) => sum + (r.confirmations || 0), 0);
    const confirmationScore = Math.min(0.3, totalConfirmations / 20);
    
    // Recency score (reportes más recientes pesan más)
    let recencyScore = 0;
    const nowDate = new Date();
    for (const report of recentReports) {
      const ageMinutes = (nowDate - report.createdAt.toDate()) / (1000 * 60);
      const weight = Math.max(0, (30 - ageMinutes) / 30);
      recencyScore += weight;
    }
    recencyScore = Math.min(0.3, recencyScore / recentReports.length);

    const confidenceValue = Math.min(1.0, reportCountScore + confirmationScore + recencyScore);
    const confidence = confidenceValue >= 0.7 ? 'high' : confidenceValue >= 0.4 ? 'medium' : 'low';

    // Buscar trenes que correspondan a esta estación
    // Por ahora, actualizamos todos los trenes de la misma línea
    // TODO: Mejorar cuando tengamos mejor asociación tren-estación
    const trainLine = newReport.trainLine || recentReports[0]?.trainLine;
    if (trainLine) {
      const trainsSnapshot = await db.collection('trains')
        .where('linea', '==', trainLine)
        .get();

      const batch = db.batch();
      trainsSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          'estado': estadoTren,
          'aglomeracion': aglomeracionClamped,
          'confidence': confidence,
          'ultima_actualizacion': now,
          'is_estimated': false,
        });
      });

      await batch.commit();
      console.log(`Train status updated for ${trainsSnapshot.size} trains from ${recentReports.length} reports`);
    }
  } catch (error) {
    console.error(`Error updating train status:`, error);
  }
}

// Función auxiliar: Mapear trainStatus + trainCrowd a estado de tren
function mapTrainStatusToEstado(trainStatus, trainCrowd) {
  if (!trainStatus) return null;
  
  if (trainStatus === 'stopped') return 'detenido';
  if (trainStatus === 'slow') return 'retrasado';
  if (trainStatus === 'normal') return 'normal';
  
  return null;
}

// Función auxiliar: Obtener promedio ponderado por confirmaciones para trenes
function getWeightedAverageTrainEstado(reports, estados) {
  const weights = {};
  
  for (let i = 0; i < reports.length && i < estados.length; i++) {
    const report = reports[i];
    const estado = estados[i];
    const weight = 1.0 + (report.confirmations || 0) * 0.5;
    weights[estado] = (weights[estado] || 0) + weight;
  }

  let maxWeight = 0;
  let maxEstado = estados[0];
  for (const [estado, weight] of Object.entries(weights)) {
    if (weight > maxWeight) {
      maxWeight = weight;
      maxEstado = estado;
    }
  }

  return maxEstado;
}

// Función auxiliar: Actualizar calibración del panel por estación
async function updateStationPanelCalibration(stationId, errorMinutes, etaBucket) {
  try {
    const stationRef = db.collection('stations').doc(stationId);
    const calibrationRef = stationRef.collection('panelCalibration').doc('latest');
    
    const calibrationDoc = await calibrationRef.get();
    const now = admin.firestore.Timestamp.now();
    
    if (calibrationDoc.exists) {
      const data = calibrationDoc.data();
      const totalReports = (data.totalReports || 0) + 1;
      const currentAvgError = data.avgError || 0.0;
      
      // Calcular nuevo error promedio
      const newAvgError = ((currentAvgError * (totalReports - 1)) + errorMinutes) / totalReports;
      
      // Calcular precisión (porcentaje de reportes con error ≤ 1 minuto)
      const accurateReports = (data.accurateReports || 0) + (Math.abs(errorMinutes) <= 1 ? 1 : 0);
      const accuracy = (accurateReports / totalReports) * 100;
      
      // Calcular precisión por hora del día
      const hourOfDay = new Date().getHours();
      const hourKey = `hour_${hourOfDay}`;
      const hourData = data.byHour || {};
      const hourReports = (hourData[hourKey]?.reports || 0) + 1;
      const hourAvgError = hourData[hourKey]?.avgError || 0.0;
      const newHourAvgError = ((hourAvgError * (hourReports - 1)) + errorMinutes) / hourReports;
      const hourAccurate = (hourData[hourKey]?.accurate || 0) + (Math.abs(errorMinutes) <= 1 ? 1 : 0);
      const hourAccuracy = (hourAccurate / hourReports) * 100;
      
      hourData[hourKey] = {
        reports: hourReports,
        avgError: newHourAvgError,
        accurate: hourAccurate,
        accuracy: hourAccuracy,
      };
      
      await calibrationRef.update({
        totalReports: totalReports,
        avgError: newAvgError,
        accurateReports: accurateReports,
        accuracy: accuracy,
        lastUpdated: now,
        lastError: errorMinutes,
        byHour: hourData,
      });
    } else {
      // Crear nueva calibración
      const hourOfDay = new Date().getHours();
      const hourKey = `hour_${hourOfDay}`;
      
      await calibrationRef.set({
        totalReports: 1,
        avgError: errorMinutes,
        accurateReports: Math.abs(errorMinutes) <= 1 ? 1 : 0,
        accuracy: Math.abs(errorMinutes) <= 1 ? 100.0 : 0.0,
        lastUpdated: now,
        lastError: errorMinutes,
        createdAt: now,
        byHour: {
          [hourKey]: {
            reports: 1,
            avgError: errorMinutes,
            accurate: Math.abs(errorMinutes) <= 1 ? 1 : 0,
            accuracy: Math.abs(errorMinutes) <= 1 ? 100.0 : 0.0,
          },
        },
      });
    }
    
    console.log(`Panel calibration updated for station ${stationId}: error ${errorMinutes} min, accuracy ${Math.abs(errorMinutes) <= 1 ? 'high' : 'low'}`);
  } catch (error) {
    console.error(`Error updating station panel calibration for ${stationId}:`, error);
    // No lanzar error, solo loggear - la calibración es opcional
  }
}

