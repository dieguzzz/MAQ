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

