(function () {
  const { db, firebase } = window.Dashboard;
  const state = window.Dashboard.state;

  // Función principal para cargar análisis
  async function loadAnalytics(force = false) {
    const container = document.getElementById('analytics');
    if (!container) return;

    // Mostrar loading
    const loadingEl = container.querySelector('.analytics-loading');
    if (loadingEl) loadingEl.style.display = 'flex';

    try {
      // Cargar estadísticas principales
      await loadAnalyticsStats();

      // Cargar gráficos y métricas
      await loadAnalyticsCharts();

      // Ocultar loading y mostrar contenido
      if (loadingEl) loadingEl.style.display = 'none';

      // Mostrar contenedor de analytics
      const analyticsContainer = container.querySelector('.analytics-container');
      if (analyticsContainer) analyticsContainer.style.display = 'block';

    } catch (error) {
      console.error('Error loading analytics:', error);
      if (loadingEl) loadingEl.style.display = 'none';

      // Mostrar error
      showAnalyticsError('Error al cargar análisis: ' + error.message);
    }
  }

  // Cargar estadísticas principales
  async function loadAnalyticsStats() {
    try {
      // Estadísticas de usuarios
      const usersSnapshot = await db.collection('users').get();
      const totalUsers = usersSnapshot.size;

      // Estadísticas de reportes
      const reportsSnapshot = await db.collection('reports').get();
      const totalReports = reportsSnapshot.size;

      // Reportes por estado
      const reportsByStatus = {};
      reportsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const status = data.estado_principal || data.estado_actual || 'desconocido';
        reportsByStatus[status] = (reportsByStatus[status] || 0) + 1;
      });

      // Estadísticas de estaciones
      const stationsSnapshot = await db.collection('stations').get();
      const totalStations = stationsSnapshot.size;

      // Reportes por día (últimos 7 días)
      const last7Days = await getReportsLast7Days();

      // Actualizar UI
      updateAnalyticsStats({
        totalUsers,
        totalReports,
        totalStations,
        reportsByStatus,
        last7Days
      });

    } catch (error) {
      console.error('Error loading analytics stats:', error);
      throw error;
    }
  }

  // Obtener reportes de los últimos 7 días
  async function getReportsLast7Days() {
    const reports = [];
    const today = new Date();

    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);

      const nextDay = new Date(date);
      nextDay.setDate(nextDay.getDate() + 1);

      try {
        // Intentar diferentes campos de fecha
        const dayReports = [];
        const fieldsToTry = ['createdAt', 'creado_en'];

        for (const field of fieldsToTry) {
          try {
            const snapshot = await db.collection('reports')
              .where(field, '>=', firebase.firestore.Timestamp.fromDate(date))
              .where(field, '<', firebase.firestore.Timestamp.fromDate(nextDay))
              .limit(1000)
              .get();

            snapshot.docs.forEach(doc => dayReports.push(doc.data()));
          } catch (e) {
            // Continuar con el siguiente campo
          }
        }

        reports.push({
          date: date.toISOString().split('T')[0],
          count: dayReports.length
        });

      } catch (error) {
        console.warn(`Error getting reports for ${date.toISOString().split('T')[0]}:`, error);
        reports.push({
          date: date.toISOString().split('T')[0],
          count: 0
        });
      }
    }

    return reports;
  }

  // Cargar gráficos y visualizaciones
  async function loadAnalyticsCharts() {
    // Crear contenedor de gráficos
    const container = document.getElementById('analytics');
    if (!container) return;

    // Verificar si ya existe el contenedor de gráficos
    let chartsContainer = container.querySelector('.analytics-charts');
    if (!chartsContainer) {
      chartsContainer = document.createElement('div');
      chartsContainer.className = 'analytics-charts';

      // Insertar después del loading
      const loadingEl = container.querySelector('.analytics-loading');
      if (loadingEl) {
        loadingEl.insertAdjacentElement('afterend', chartsContainer);
      } else {
        container.appendChild(chartsContainer);
      }
    }

    // Limpiar contenido anterior
    chartsContainer.innerHTML = '';

    // Crear gráficos
    await createReportsChart(chartsContainer);
    await createStationsChart(chartsContainer);
    await createUsersChart(chartsContainer);
  }

  // Crear gráfico de reportes
  async function createReportsChart(container) {
    const chartDiv = document.createElement('div');
    chartDiv.className = 'analytics-chart';
    chartDiv.innerHTML = `
      <div class="chart-header">
        <h3>Reportes por Día (Últimos 7 días)</h3>
      </div>
      <div class="chart-container">
        <canvas id="reportsChart" width="400" height="200"></canvas>
      </div>
    `;
    container.appendChild(chartDiv);

    // Obtener datos
    const last7Days = await getReportsLast7Days();

    // Crear gráfico con Chart.js
    const ctx = document.getElementById('reportsChart');
    if (ctx && window.Chart) {
      new Chart(ctx, {
        type: 'line',
        data: {
          labels: last7Days.map(d => {
            const date = new Date(d.date);
            return date.toLocaleDateString('es-ES', { weekday: 'short', month: 'short', day: 'numeric' });
          }),
          datasets: [{
            label: 'Reportes',
            data: last7Days.map(d => d.count),
            borderColor: '#3b82f6',
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
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
                stepSize: 1
              }
            }
          }
        }
      });
    }
  }

  // Crear gráfico de estaciones
  async function createStationsChart(container) {
    const chartDiv = document.createElement('div');
    chartDiv.className = 'analytics-chart';
    chartDiv.innerHTML = `
      <div class="chart-header">
        <h3>Estado de Estaciones</h3>
      </div>
      <div class="chart-container">
        <canvas id="stationsChart" width="400" height="200"></canvas>
      </div>
    `;
    container.appendChild(chartDiv);

    // Obtener datos de estaciones
    const stationsSnapshot = await db.collection('stations').get();
    const stationsByStatus = {};

    stationsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const status = data.estado_actual || 'normal';
      stationsByStatus[status] = (stationsByStatus[status] || 0) + 1;
    });

    // Crear gráfico
    const ctx = document.getElementById('stationsChart');
    if (ctx && window.Chart) {
      new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: Object.keys(stationsByStatus),
          datasets: [{
            data: Object.values(stationsByStatus),
            backgroundColor: [
              '#10b981', // normal - green
              '#f59e0b', // moderado - yellow
              '#ef4444', // lleno - red
              '#6b7280'  // otros - gray
            ],
            borderWidth: 2
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom'
            }
          }
        }
      });
    }
  }

  // Crear gráfico de usuarios
  async function createUsersChart(container) {
    const chartDiv = document.createElement('div');
    chartDiv.className = 'analytics-chart';
    chartDiv.innerHTML = `
      <div class="chart-header">
        <h3>Usuarios por Nivel</h3>
      </div>
      <div class="chart-container">
        <canvas id="usersChart" width="400" height="200"></canvas>
      </div>
    `;
    container.appendChild(chartDiv);

    // Obtener datos de usuarios
    const usersSnapshot = await db.collection('users').get();
    const usersByLevel = {};

    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const level = data.nivel || 1;
      usersByLevel[level] = (usersByLevel[level] || 0) + 1;
    });

    // Crear gráfico
    const ctx = document.getElementById('usersChart');
    if (ctx && window.Chart) {
      new Chart(ctx, {
        type: 'bar',
        data: {
          labels: Object.keys(usersByLevel).sort((a, b) => parseInt(a) - parseInt(b)),
          datasets: [{
            label: 'Usuarios',
            data: Object.values(usersByLevel),
            backgroundColor: '#8b5cf6',
            borderColor: '#7c3aed',
            borderWidth: 1
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
                stepSize: 1
              }
            }
          }
        }
      });
    }
  }

  // Actualizar estadísticas en la UI
  function updateAnalyticsStats(stats) {
    // Crear contenedor de estadísticas si no existe
    const container = document.getElementById('analytics');
    let statsContainer = container.querySelector('.analytics-stats');

    if (!statsContainer) {
      statsContainer = document.createElement('div');
      statsContainer.className = 'analytics-stats';
      statsContainer.innerHTML = `
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon">👥</div>
            <div class="stat-info">
              <div class="stat-value" id="analytics-total-users">${stats.totalUsers}</div>
              <div class="stat-label">Usuarios Totales</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon">📊</div>
            <div class="stat-info">
              <div class="stat-value" id="analytics-total-reports">${stats.totalReports}</div>
              <div class="stat-label">Reportes Totales</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon">🚇</div>
            <div class="stat-info">
              <div class="stat-value" id="analytics-total-stations">${stats.totalStations}</div>
              <div class="stat-label">Estaciones</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon">📈</div>
            <div class="stat-info">
              <div class="stat-value" id="analytics-reports-today">${stats.last7Days[6]?.count || 0}</div>
              <div class="stat-label">Reportes Hoy</div>
            </div>
          </div>
        </div>
        <div class="status-breakdown">
          <h3>Estado de Reportes</h3>
          <div class="status-list" id="analytics-status-list">
            ${Object.entries(stats.reportsByStatus).map(([status, count]) => `
              <div class="status-item">
                <span class="status-label">${status}</span>
                <span class="status-count">${count}</span>
              </div>
            `).join('')}
          </div>
        </div>
      `;

      // Insertar después del header
      const header = container.querySelector('.page-header');
      if (header) {
        header.insertAdjacentElement('afterend', statsContainer);
      }
    } else {
      // Actualizar valores existentes
      const totalUsersEl = document.getElementById('analytics-total-users');
      const totalReportsEl = document.getElementById('analytics-total-reports');
      const totalStationsEl = document.getElementById('analytics-total-stations');
      const reportsTodayEl = document.getElementById('analytics-reports-today');

      if (totalUsersEl) totalUsersEl.textContent = stats.totalUsers;
      if (totalReportsEl) totalReportsEl.textContent = stats.totalReports;
      if (totalStationsEl) totalStationsEl.textContent = stats.totalStations;
      if (reportsTodayEl) reportsTodayEl.textContent = stats.last7Days[6]?.count || 0;
    }
  }

  // Mostrar error en analytics
  function showAnalyticsError(message) {
    const container = document.getElementById('analytics');
    if (!container) return;

    let errorEl = container.querySelector('.analytics-error');
    if (!errorEl) {
      errorEl = document.createElement('div');
      errorEl.className = 'analytics-error';
      container.appendChild(errorEl);
    }

    errorEl.innerHTML = `
      <div class="error-message">
        <i class="fas fa-exclamation-triangle"></i>
        <p>${message}</p>
        <button onclick="window.loadAnalytics(true)" class="retry-btn">Reintentar</button>
      </div>
    `;
  }

  // Exponer función global
  window.loadAnalytics = loadAnalytics;

})();