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

  // Gráficos del Overview
  let activityChart = null;
  let statusChart = null;

  async function loadOverviewCharts(period = '24h') {
    try {
      const now = new Date();
      let startDate;

      switch (period) {
        case '24h':
          startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
          break;
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      }

      // Cargar datos de actividad por hora
      await loadActivityChart(startDate, now);

      // Cargar distribución de estados
      await loadStatusChart();

    } catch (error) {
      console.error('Error loading overview charts:', error);
    }
  }

  async function loadActivityChart(startDate, endDate) {
    try {
      const startTs = firebase.firestore.Timestamp.fromDate(startDate);
      const endTs = firebase.firestore.Timestamp.fromDate(endDate);

      // Consultar reportes en el período
      const reportsSnap = await db.collection('reports')
        .where('creado_en', '>=', startTs)
        .where('creado_en', '<=', endTs)
        .limit(1000)
        .get();

      // Agrupar por hora
      const hourlyData = {};
      reportsSnap.docs.forEach(doc => {
        const data = doc.data();
        const timestamp = _getMillisFromPossibleTimestamp(data.creado_en || data.createdAt);
        if (timestamp) {
          const hour = new Date(timestamp).getHours();
          hourlyData[hour] = (hourlyData[hour] || 0) + 1;
        }
      });

      // Crear datos para el gráfico
      const labels = [];
      const data = [];
      for (let i = 0; i < 24; i++) {
        labels.push(`${i}:00`);
        data.push(hourlyData[i] || 0);
      }

      // Destruir gráfico anterior si existe
      if (activityChart) {
        activityChart.destroy();
      }

      // Crear nuevo gráfico
      const ctx = document.createElement('canvas');
      ctx.width = 400;
      ctx.height = 200;

      // Reemplazar placeholder con canvas
      const placeholder = document.querySelector('.chart-placeholder');
      if (placeholder) {
        placeholder.innerHTML = '';
        placeholder.appendChild(ctx);
      }

      activityChart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: labels,
          datasets: [{
            label: 'Reportes por hora',
            data: data,
            borderColor: '#6366f1',
            backgroundColor: 'rgba(99, 102, 241, 0.1)',
            tension: 0.4,
            fill: true
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                precision: 0
              }
            }
          },
          elements: {
            point: {
              radius: 3,
              hoverRadius: 5
            }
          }
        }
      });

    } catch (error) {
      console.error('Error loading activity chart:', error);
    }
  }

  async function loadStatusChart() {
    try {
      // Consultar estados de estaciones
      const stationsSnap = await db.collection('stations').limit(100).get();

      const statusCounts = {
        'operando': 0,
        'cerrado': 0,
        'retraso': 0,
        'moderado': 0,
        'lleno': 0
      };

      stationsSnap.docs.forEach(doc => {
        const data = doc.data();
        const status = data.estado || 'operando';

        // Mapear estados del modelo a categorías del gráfico
        if (status === 'cerrado' || status === 'fuera_de_servicio') {
          statusCounts.cerrado++;
        } else if (status === 'retraso' || status === 'demora') {
          statusCounts.retraso++;
        } else if (status === 'moderado' || status === 'aglomerado') {
          statusCounts.moderado++;
        } else if (status === 'lleno' || status === 'muy_lleno') {
          statusCounts.lleno++;
        } else {
          statusCounts.operando++;
        }
      });

      // Destruir gráfico anterior si existe
      if (statusChart) {
        statusChart.destroy();
      }

      // Crear nuevo gráfico
      const ctx = document.createElement('canvas');
      ctx.width = 400;
      ctx.height = 200;

      // Reemplazar placeholder con canvas
      const placeholders = document.querySelectorAll('.chart-placeholder');
      if (placeholders[1]) { // Segundo placeholder para el gráfico de estados
        placeholders[1].innerHTML = '';
        placeholders[1].appendChild(ctx);
      }

      statusChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: ['Operando', 'Cerrado', 'Retraso', 'Moderado', 'Lleno'],
          datasets: [{
            data: [
              statusCounts.operando,
              statusCounts.cerrado,
              statusCounts.retraso,
              statusCounts.moderado,
              statusCounts.lleno
            ],
            backgroundColor: [
              '#10b981', // verde - operando
              '#ef4444', // rojo - cerrado
              '#f59e0b', // amarillo - retraso
              '#f97316', // naranja - moderado
              '#dc2626'  // rojo oscuro - lleno
            ],
            borderWidth: 2,
            borderColor: '#ffffff'
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom',
              labels: {
                padding: 20,
                usePointStyle: true
              }
            }
          }
        }
      });

    } catch (error) {
      console.error('Error loading status chart:', error);
    }
  }

  async function loadRecentActivity() {
    try {
      const activityList = document.getElementById('recentActivity');
      if (!activityList) return;

      // Mostrar loading
      activityList.innerHTML = `
        <div class="activity-loading">
          <i class="fas fa-spinner fa-spin"></i>
          Cargando actividad...
        </div>
      `;

      // Consultar reportes recientes
      const recentReportsSnap = await db.collection('reports')
        .orderBy('creado_en', 'desc')
        .limit(10)
        .get();

      if (recentReportsSnap.empty) {
        activityList.innerHTML = `
          <div class="activity-empty">
            <i class="fas fa-info-circle"></i>
            No hay actividad reciente
          </div>
        `;
        return;
      }

      // Crear lista de actividad
      const activities = [];
      recentReportsSnap.docs.forEach(doc => {
        const data = doc.data();
        const timestamp = _getMillisFromPossibleTimestamp(data.creado_en || data.createdAt);

        let activityType = 'reporte';
        let activityIcon = 'fas fa-clipboard-list';
        let activityColor = 'info';

        // Determinar tipo de actividad basado en el estado
        if (data.estado_principal === 'cerrado') {
          activityIcon = 'fas fa-times-circle';
          activityColor = 'danger';
        } else if (data.estado_principal === 'retraso') {
          activityIcon = 'fas fa-clock';
          activityColor = 'warning';
        } else if (data.estado_principal === 'lleno') {
          activityIcon = 'fas fa-users';
          activityColor = 'danger';
        }

        const timeAgo = timestamp ? getTimeAgo(timestamp) : 'Hace un momento';

        activities.push(`
          <div class="activity-item">
            <div class="activity-icon ${activityColor}">
              <i class="${activityIcon}"></i>
            </div>
            <div class="activity-content">
              <div class="activity-text">
                Nuevo reporte en ${data.objetivo || data.estacion || 'estación desconocida'}
              </div>
              <div class="activity-time">${timeAgo}</div>
            </div>
          </div>
        `);
      });

      activityList.innerHTML = activities.join('');

    } catch (error) {
      console.error('Error loading recent activity:', error);
      const activityList = document.getElementById('recentActivity');
      if (activityList) {
        activityList.innerHTML = `
          <div class="activity-error">
            <i class="fas fa-exclamation-triangle"></i>
            Error cargando actividad
          </div>
        `;
      }
    }
  }

  function getTimeAgo(timestamp) {
    const now = Date.now();
    const diff = now - timestamp;

    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (minutes < 1) return 'Hace un momento';
    if (minutes < 60) return `Hace ${minutes} minutos`;
    if (hours < 24) return `Hace ${hours} horas`;
    return `Hace ${days} días`;
  }

  // Inicializar event listeners para los gráficos
  function initOverviewCharts() {
    // Event listener para el selector de período
    const periodSelect = document.querySelector('.chart-period');
    if (periodSelect) {
      periodSelect.addEventListener('change', (e) => {
        loadOverviewCharts(e.target.value);
      });
    }

    // Cargar datos iniciales
    loadOverviewCharts();
    loadRecentActivity();
  }

  window.loadOverviewCharts = loadOverviewCharts;
  window.loadRecentActivity = loadRecentActivity;
  window.initOverviewCharts = initOverviewCharts;
  window.loadStats = loadStats;
})();


