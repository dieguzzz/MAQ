(function () {
  const { db, firebase } = window.Dashboard;
  const state = window.Dashboard.state;

  function _getMillisFromPossibleTimestamp(value) {
    if (!value) return null;
    if (typeof value === 'number') return value;
    if (value.toMillis && typeof value.toMillis === 'function') return value.toMillis();
    if (value.toDate && typeof value.toDate === 'function') return value.toDate().getTime();
    if (value instanceof Date) return value.getTime();
    return null;
  }

  async function loadStats() {
    try {
      // Usuarios
      const usersSnapshot = await db.collection('users').get();
      const totalUsers = usersSnapshot.size;
      document.getElementById('totalUsers').textContent = totalUsers;
      document.getElementById('usersChange').textContent =
        `Anterior: ${state.statsCache.users} | Cambio: ${totalUsers - state.statsCache.users >= 0 ? '+' : ''}${totalUsers - state.statsCache.users}`;
      state.statsCache.users = totalUsers;

      // Reportes de hoy (excluyendo falsos/eliminados)
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayTs = firebase.firestore.Timestamp.fromDate(today);

      // IMPORTANTE: el app escribe reportes con `createdAt` (modelo simplificado) y el dashboard/test con `creado_en`.
      // Si consultamos solo `creado_en` y la query "no falla", pero la mayoría de docs no tienen ese campo,
      // el resultado queda en 0. Por eso hacemos UNION de ambas consultas.
      const byId = new Map();

      async function tryQueryByField(fieldName) {
        try {
          const snap = await db.collection('reports')
            .where(fieldName, '>=', todayTs)
            .limit(2000)
            .get();
          snap.docs.forEach(d => byId.set(d.id, d));
        } catch (e) {
          // Si falla por índices/permisos, no bloqueamos todo: lo reportamos y seguimos.
          console.warn(`No se pudo consultar reports por ${fieldName}:`, e);
        }
      }

      await Promise.all([
        tryQueryByField('creado_en'),
        tryQueryByField('createdAt'),
      ]);

      // Fallback final: si no conseguimos nada por queries (por ejemplo, índices), traer una ventana acotada y filtrar.
      if (byId.size === 0) {
        try {
          const fallbackSnap = await db.collection('reports')
            .orderBy('createdAt', 'desc')
            .limit(300)
            .get();
          fallbackSnap.docs.forEach(d => {
            const data = d.data();
            const createdAtMs = _getMillisFromPossibleTimestamp(data.createdAt) ?? _getMillisFromPossibleTimestamp(data.creado_en);
            if (createdAtMs && createdAtMs >= today.getTime()) byId.set(d.id, d);
          });
        } catch (e) {
          console.warn('Fallback de reportsToday falló:', e);
        }
      }

      const activeReportsToday = Array.from(byId.values()).filter(doc => {
        const data = doc.data();
        const estado = data.estado || data.status || 'activo';
        return estado !== 'falso' && estado !== 'deleted';
      });

      const reportsToday = activeReportsToday.length;
      document.getElementById('reportsToday').textContent = reportsToday;
      document.getElementById('reportsChange').textContent =
        `Anterior: ${state.statsCache.reports} | Cambio: ${reportsToday - state.statsCache.reports >= 0 ? '+' : ''}${reportsToday - state.statsCache.reports}`;
      state.statsCache.reports = reportsToday;

      // Estaciones activas
      const activeStationsSet = new Set();
      activeReportsToday.forEach(doc => {
        const data = doc.data();
        const tipo = (data.tipo || data.scope || 'estacion').toLowerCase();
        const objetivoId = data.objetivo_id || data.stationId;
        // Compat: scope del modelo simplificado es 'station' / 'train'
        const isStation = tipo === 'estacion' || tipo === 'station';
        if (isStation && objetivoId) activeStationsSet.add(objetivoId);
      });
      const activeStations = activeStationsSet.size;
      document.getElementById('activeStations').textContent = activeStations;
      document.getElementById('stationsChange').textContent =
        `Anterior: ${state.statsCache.stations} | Cambio: ${activeStations - state.statsCache.stations >= 0 ? '+' : ''}${activeStations - state.statsCache.stations}`;
      state.statsCache.stations = activeStations;

      // Trenes
      const trainsSnapshot = await db.collection('trains').get();
      const activeTrains = trainsSnapshot.size;
      document.getElementById('activeTrains').textContent = activeTrains;
      document.getElementById('trainsChange').textContent =
        `Anterior: ${state.statsCache.trains} | Cambio: ${activeTrains - state.statsCache.trains >= 0 ? '+' : ''}${activeTrains - state.statsCache.trains}`;
      state.statsCache.trains = activeTrains;

      // Confianza promedio (stations)
      const stationsSnapshot = await db.collection('stations').get();
      let totalConfidence = 0;
      let stationsWithConfidence = 0;
      stationsSnapshot.docs.forEach(doc => {
        const confidence = doc.data().confidence;
        if (confidence) {
          stationsWithConfidence++;
          if (confidence === 'high') totalConfidence += 3;
          else if (confidence === 'medium') totalConfidence += 2;
          else totalConfidence += 1;
        }
      });
      const avgConfidence = stationsWithConfidence > 0 ? (totalConfidence / stationsWithConfidence).toFixed(1) : '0';
      document.getElementById('avgConfidence').textContent = avgConfidence;
      document.getElementById('confidenceChange').textContent = `${stationsWithConfidence} estaciones con datos`;

      // Prioritarios hoy
      const priorityReportsToday = activeReportsToday.filter(doc => doc.data().prioridad === true).length;
      document.getElementById('priorityReports').textContent = priorityReportsToday;
      document.getElementById('priorityChange').textContent = 'Reportes urgentes hoy';

      // Verificación hoy
      let verifiedCount = 0;
      activeReportsToday.forEach(doc => {
        const verificationStatus = doc.data().verification_status || 'pending';
        if (verificationStatus === 'verified' || verificationStatus === 'community_verified') verifiedCount++;
      });
      const verificationRate = reportsToday > 0 ? ((verifiedCount / reportsToday) * 100).toFixed(1) + '%' : '0%';
      document.getElementById('verificationRate').textContent = verificationRate;
      document.getElementById('verificationChange').textContent = `${verifiedCount} de ${reportsToday} verificados`;
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  }

  window.loadStats = loadStats;
})();


