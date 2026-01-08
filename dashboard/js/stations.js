(function () {
  const { db } = window.Dashboard;

  // Variables globales para listeners
  let stationsUnsubscribe = null;
  let reportsUnsubscribe = null;

  // Estados UI
  function getEmptyStateHtml() {
    return `
      <div class="empty-state">
        <div class="empty-state-icon">📍</div>
        <h3>No hay estaciones disponibles</h3>
        <p>Las estaciones aparecerán aquí cuando se registren reportes o se configure el sistema.</p>
        <div class="empty-state-actions">
          <button class="refresh-btn" onclick="refreshAll()">🔄 Actualizar</button>
          <button class="test-btn test-btn-primary" onclick="showTab('reports')">📊 Ver Reportes</button>
        </div>
      </div>
    `;
  }

  function getLoadingStateHtml() {
    return `
      <div class="loading-state">
        <div class="loading-spinner"></div>
        <p>Cargando estaciones...</p>
      </div>
    `;
  }

  function showRealtimeIndicator(message = 'Actualizado') {
    const indicator = document.getElementById('realtimeIndicator');
    if (indicator) {
      indicator.textContent = message;
      indicator.classList.add('show');
      setTimeout(() => {
        indicator.classList.remove('show');
      }, 3000);
    }
  }

  async function loadStations(showLoading = true) {
    try {
      if (showLoading) {
        const loadingElement = document.querySelector('#stations .loading');
        if (loadingElement) {
          loadingElement.outerHTML = getLoadingStateHtml();
        }
      }

      const snapshot = await db.collection('stations')
        .orderBy('nombre')
        .get();

      // Verificar si hay datos
      if (snapshot.empty) {
        const html = getEmptyStateHtml();
        const loadingElement = document.querySelector('#stations .loading-state');
        if (loadingElement) {
          loadingElement.outerHTML = html;
        } else {
          const section = document.getElementById('stations');
          if (section) {
            section.insertAdjacentHTML('beforeend', html);
          }
        }
        document.getElementById('stationsCount').textContent = '0 estaciones';
        return;
      }

      // Agrupar por línea
      const stationsByLine = {};
      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const linea = data.linea || 'L1';
        if (!stationsByLine[linea]) stationsByLine[linea] = [];
        stationsByLine[linea].push({ id: doc.id, data });
      });

      const groupsHtml = Object.keys(stationsByLine).sort().map(linea => {
        const stations = stationsByLine[linea];
        const stationsHtml = stations.map(({ id, data }) => {
          const confidence = data.confidence || 'low';
          const isEstimated = data.is_estimated || false;
          return `
            <tr data-station-name="${(data.nombre || id).toLowerCase()}"
                data-station-line="${linea.toLowerCase()}"
                data-station-state="${(data.estado_actual || 'normal').toLowerCase()}">
              <td><strong>${data.nombre || id}</strong></td>
              <td>${linea}</td>
              <td>${data.estado_actual || 'normal'}</td>
              <td>${data.aglomeracion || 1}/5</td>
              <td>
                <span class="badge ${confidence === 'high' ? 'badge-high' : confidence === 'medium' ? 'badge-medium' : isEstimated ? 'badge-estimated' : 'badge-low'}">
                  ${isEstimated ? '📊 Estimado' : confidence === 'high' ? '🟢 Alta' : confidence === 'medium' ? '🟡 Media' : '🔴 Baja'}
                </span>
              </td>
              <td>${data.ultima_actualizacion ? new Date(data.ultima_actualizacion.toMillis()).toLocaleString('es-PA') : 'N/A'}</td>
            </tr>
          `;
        }).join('');

        return `
          <div class="line-group" data-line="${linea.toLowerCase()}">
            <div class="line-header" onclick="toggleLine('${linea}')">
              <div class="line-title">
                <span class="line-toggle">▶</span>
                <span>Línea ${linea}</span>
                <span class="line-count">${stations.length}</span>
              </div>
            </div>
            <div class="line-stations">
              <table>
                <thead>
                  <tr>
                    <th>📍 Nombre</th>
                    <th>🚇 Línea</th>
                    <th>📊 Estado</th>
                    <th>👥 Aglomeración</th>
                    <th>🎯 Confianza</th>
                    <th>🕒 Última Actualización</th>
                  </tr>
                </thead>
                <tbody>
                  ${stationsHtml}
                </tbody>
              </table>
            </div>
          </div>
        `;
      }).join('');

      const html = `<div id="stationsContainer">${groupsHtml}</div>`;

      const loadingElement = document.querySelector('#stations .loading');
      if (loadingElement) {
        loadingElement.outerHTML = html;
      } else {
        const section = document.getElementById('stations');
        if (section) {
          const existingContainer = section.querySelector('#stationsContainer');
          if (existingContainer) existingContainer.outerHTML = html;
          else section.insertAdjacentHTML('beforeend', html);
        }
      }

      document.getElementById('stationsCount').textContent = `${snapshot.size} estaciones`;

      // Mostrar indicador de actualización si no es carga inicial
      if (!showLoading) {
        showRealtimeIndicator('Estaciones actualizadas');
      }

    } catch (error) {
      console.error('Error loading stations:', error);
      const errorHtml = `
        <div class="error-state">
          <div class="error-icon">⚠️</div>
          <h3>Error al cargar estaciones</h3>
          <p>${error.message.includes('permissions')
            ? 'Error de permisos. Verifica las reglas de Firestore o autenticación.'
            : error.message}</p>
          <button class="refresh-btn" onclick="loadStations()">🔄 Reintentar</button>
        </div>
      `;

      const loadingElement = document.querySelector('#stations .loading-state');
      if (loadingElement) {
        loadingElement.outerHTML = errorHtml;
      } else {
        const section = document.getElementById('stations');
        if (section) {
          section.insertAdjacentHTML('beforeend', errorHtml);
        }
      }
    }
  }

  function toggleLine(linea) {
    const group = document.querySelector(`.line-group[data-line="${linea.toLowerCase()}"]`);
    if (!group) return;
    const header = group.querySelector('.line-header');
    group.classList.toggle('expanded');
    header?.classList.toggle('expanded');
  }

  // Nueva función para inicializar listeners en tiempo real
  function initStationsRealtimeListeners() {
    // Limpiar listeners existentes
    cleanupStationsListeners();

    // Listener para cambios en estaciones
    stationsUnsubscribe = db.collection('stations')
      .orderBy('nombre')
      .onSnapshot((snapshot) => {
        console.log('📍 Estaciones actualizadas en tiempo real');
        loadStations(false); // false para no mostrar loading en updates
      }, (error) => {
        console.error('Error en listener de estaciones:', error);
      });

    // Listener para reportes (sin filtros para evitar índices compuestos)
    // El nuevo sistema usa 'scope' en vez de 'tipo', así que mejor escuchar todos los reportes
    try {
      reportsUnsubscribe = db.collection('reports')
        .orderBy('createdAt', 'desc')
        .limit(20)
        .onSnapshot((snapshot) => {
          console.log('📊 Reportes actualizados');
          if (!snapshot.empty && snapshot.docChanges().length > 0) {
            loadStations(false);
            window.loadStats?.();
            showRealtimeIndicator('Nuevo reporte recibido');
          }
        }, (error) => {
          console.warn('Error en listener de reportes:', error);
        });
    } catch (e) {
      console.warn('No se pudieron inicializar listeners de reportes:', e);
    }
  }

  // Función para limpiar listeners
  function cleanupStationsListeners() {
    if (stationsUnsubscribe) {
      stationsUnsubscribe();
      stationsUnsubscribe = null;
    }
    if (reportsUnsubscribe) {
      reportsUnsubscribe();
      reportsUnsubscribe = null;
    }
  }

  window.loadStations = loadStations;
  window.toggleLine = toggleLine;
  window.initStationsRealtimeListeners = initStationsRealtimeListeners;
  window.cleanupStationsListeners = cleanupStationsListeners;
})();


