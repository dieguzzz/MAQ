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
        <i class="fas fa-spinner fa-spin"></i>
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
        const loadingElement = document.querySelector('#stations .data-loading');
        if (loadingElement) {
          loadingElement.outerHTML = getLoadingStateHtml();
        }
      }

      // Cargar estaciones y estadísticas de reportes en paralelo
      const [stationsSnapshot, reportsSnapshot] = await Promise.all([
        db.collection('stations').orderBy('nombre').get(),
        db.collection('reports').get()
      ]);

      // Procesar estadísticas de reportes por estación
      const reportsByStation = {};
      reportsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const stationId = data.objetivo || data.estacion;
        if (stationId) {
          if (!reportsByStation[stationId]) {
            reportsByStation[stationId] = {
              total: 0,
              recent: [],
              byType: {},
              byStatus: {}
            };
          }

          reportsByStation[stationId].total++;

          // Últimos 3 reportes
          if (reportsByStation[stationId].recent.length < 3) {
            reportsByStation[stationId].recent.push({
              id: doc.id,
              data: data,
              timestamp: _getMillisFromPossibleTimestamp(data.creado_en || data.createdAt)
            });
          }

          // Por tipo
          const tipo = data.tipo || data.categoria || 'general';
          reportsByStation[stationId].byType[tipo] = (reportsByStation[stationId].byType[tipo] || 0) + 1;

          // Por estado
          const estado = data.estado_principal || data.estado || 'normal';
          reportsByStation[stationId].byStatus[estado] = (reportsByStation[stationId].byStatus[estado] || 0) + 1;
        }
      });

      // Verificar si hay datos
      if (stationsSnapshot.empty) {
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

      // Crear vista de tarjetas detalladas
      const stationsHtml = stationsSnapshot.docs.map(doc => {
        const data = doc.data();
        const stationId = doc.id;
        const stats = reportsByStation[stationId] || { total: 0, recent: [], byType: {}, byStatus: {} };

        const confidence = data.confidence || 'low';
        const isEstimated = data.is_estimated || false;
        const lastUpdate = data.ultima_actualizacion ?
          new Date(data.ultima_actualizacion.toMillis()).toLocaleString('es-PA') : 'N/A';

        // Crear resumen de tipos de reportes
        const reportTypes = Object.entries(stats.byType)
          .map(([type, count]) => `${type}: ${count}`)
          .join(', ') || 'Sin reportes';

        // Últimos reportes
        const recentReportsHtml = stats.recent
          .sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0))
          .slice(0, 3)
          .map(report => {
            const timeAgo = report.timestamp ? getTimeAgo(report.timestamp) : 'Hace un momento';
            const estado = report.data.estado_principal || 'normal';
            return `
              <div class="recent-report">
                <div class="report-status status-${estado.toLowerCase()}">${estado}</div>
                <div class="report-info">
                  <div class="report-type">${report.data.categoria || report.data.tipo || 'General'}</div>
                  <div class="report-time">${timeAgo}</div>
                </div>
              </div>
            `;
          }).join('') || '<div class="no-reports">Sin reportes recientes</div>';

        return `
          <div class="station-card" data-station-name="${(data.nombre || stationId).toLowerCase()}"
               data-station-line="${(data.linea || 'L1').toLowerCase()}"
               data-station-state="${(data.estado_actual || 'normal').toLowerCase()}">
            <div class="station-header">
              <div class="station-title">
                <h3>${data.nombre || stationId}</h3>
                <span class="station-line">Línea ${data.linea || '1'}</span>
              </div>
              <div class="station-confidence">
                <span class="badge ${confidence === 'high' ? 'badge-high' : confidence === 'medium' ? 'badge-medium' : isEstimated ? 'badge-estimated' : 'badge-low'}">
                  ${isEstimated ? '📊 Estimado' : confidence === 'high' ? '🟢 Alta' : confidence === 'medium' ? '🟡 Media' : '🔴 Baja'}
                </span>
              </div>
            </div>

            <div class="station-stats">
              <div class="stat-item">
                <div class="stat-icon">📊</div>
                <div class="stat-info">
                  <div class="stat-value">${data.estado_actual || 'Normal'}</div>
                  <div class="stat-label">Estado Actual</div>
                </div>
              </div>
              <div class="stat-item">
                <div class="stat-icon">👥</div>
                <div class="stat-info">
                  <div class="stat-value">${data.aglomeracion || 1}/5</div>
                  <div class="stat-label">Aglomeración</div>
                </div>
              </div>
              <div class="stat-item">
                <div class="stat-icon">📋</div>
                <div class="stat-info">
                  <div class="stat-value">${stats.total}</div>
                  <div class="stat-label">Reportes Totales</div>
                </div>
              </div>
            </div>

            <div class="station-reports">
              <div class="reports-summary">
                <h4>📈 Actividad Reciente</h4>
                <div class="reports-types">${reportTypes}</div>
              </div>
              <div class="recent-reports-list">
                ${recentReportsHtml}
              </div>
            </div>

            <div class="station-footer">
              <div class="station-location">
                ${typeof data.direccion === 'string' ? data.direccion :
                  typeof data.ubicacion === 'string' ? data.ubicacion :
                  'Ubicación no especificada'}
              </div>
              <div class="station-updated">
                🕒 ${lastUpdate}
              </div>
            </div>
          </div>
        `;
      }).join('');

      const html = `<div id="stationsContainer" class="stations-grid">${stationsHtml}</div>`;

      const loadingElement = document.querySelector('#stations .loading-state');
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

      document.getElementById('stationsCount').textContent = `${stationsSnapshot.size} estaciones`;

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
          const existingContainer = section.querySelector('#stationsContainer');
          if (existingContainer) existingContainer.outerHTML = errorHtml;
          else section.insertAdjacentHTML('beforeend', errorHtml);
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

  // Función para inicializar listeners en tiempo real (DESHABILITADA)
  // Ahora solo se actualiza con el botón "Actualizar"
  function initStationsRealtimeListeners() {
    console.log('ℹ️ Listeners en tiempo real deshabilitados. Usa el botón Actualizar.');
    // No se inicializan listeners de onSnapshot
    return;
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

  // Inicializar filtros y búsqueda
  function initStationsFilters() {
    const searchInput = document.getElementById('filterStations');
    const statusFilter = document.getElementById('statusFilter');
    const confidenceFilter = document.getElementById('confidenceFilter');

    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        filterStations(e.target.value);
      });
    }

    if (statusFilter) {
      statusFilter.addEventListener('change', () => {
        filterStations(searchInput?.value || '');
      });
    }

    if (confidenceFilter) {
      confidenceFilter.addEventListener('change', () => {
        filterStations(searchInput?.value || '');
      });
    }
  }

  function filterStations(query) {
    const statusFilter = document.getElementById('statusFilter')?.value || '';
    const confidenceFilter = document.getElementById('confidenceFilter')?.value || '';
    const normalizedQuery = query.toLowerCase().trim();

    const cards = document.querySelectorAll('.station-card');
    cards.forEach(card => {
      const stationName = card.getAttribute('data-station-name') || '';
      const stationLine = card.getAttribute('data-station-line') || '';
      const stationState = card.getAttribute('data-station-state') || '';

      // Obtener datos de confianza del DOM
      const confidenceBadge = card.querySelector('.badge');
      let stationConfidence = '';
      if (confidenceBadge) {
        const badgeText = confidenceBadge.textContent;
        if (badgeText.includes('Alta')) stationConfidence = 'high';
        else if (badgeText.includes('Media')) stationConfidence = 'medium';
        else if (badgeText.includes('Estimado')) stationConfidence = 'estimated';
        else stationConfidence = 'low';
      }

      // Aplicar filtros
      const matchesQuery = !normalizedQuery ||
                          stationName.includes(normalizedQuery) ||
                          stationLine.includes(normalizedQuery) ||
                          stationState.includes(normalizedQuery);

      const matchesStatus = !statusFilter || stationState === statusFilter;
      const matchesConfidence = !confidenceFilter || stationConfidence === confidenceFilter;

      const shouldShow = matchesQuery && matchesStatus && matchesConfidence;
      card.style.display = shouldShow ? '' : 'none';
    });

    // Actualizar contador con filtros aplicados
    const visibleCards = document.querySelectorAll('.station-card:not([style*="display: none"])');
    const totalCards = document.querySelectorAll('.station-card');

    let countText = `${totalCards.length} estaciones`;
    if (query || statusFilter || confidenceFilter) {
      countText = `${visibleCards.length}/${totalCards.length} estaciones`;
      if (statusFilter) countText += ` (estado: ${statusFilter})`;
      if (confidenceFilter) countText += ` (confianza: ${confidenceFilter})`;
    }

    document.getElementById('stationsCount').textContent = countText;
  }

  function setStationsView(viewType) {
    const container = document.getElementById('stationsContainer');

    if (!container) return;

    // Actualizar botones activos
    document.querySelectorAll('.view-btn').forEach(btn => {
      btn.classList.remove('active');
    });
    document.querySelector(`[onclick="setStationsView('${viewType}')"]`)?.classList.add('active');

    if (viewType === 'lines') {
      // Cambiar a vista de líneas (recargar con el método anterior)
      loadStationsLines();
    } else {
      // Vista de tarjetas (por defecto)
      loadStations();
    }
  }

  async function loadStationsLines() {
    // Recargar usando el método anterior de líneas
    const snapshot = await db.collection('stations').orderBy('nombre').get();

    if (snapshot.empty) {
      const html = getEmptyStateHtml();
      const loadingElement = document.querySelector('#stations .loading-state');
      if (loadingElement) {
        loadingElement.outerHTML = html;
      }
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

    const section = document.getElementById('stations');
    if (section) {
      const existingContainer = section.querySelector('#stationsContainer');
      if (existingContainer) existingContainer.outerHTML = html;
      else section.insertAdjacentHTML('beforeend', html);
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

  // Inicializar cuando se carga el DOM
  document.addEventListener('DOMContentLoaded', () => {
    initStationsFilters();
  });

  window.loadStations = loadStations;
  window.loadStationsLines = loadStationsLines;
  window.toggleLine = toggleLine;
  window.setStationsView = setStationsView;
  window.initStationsRealtimeListeners = initStationsRealtimeListeners;
  window.cleanupStationsListeners = cleanupStationsListeners;
  window.filterStations = filterStations;
})();


