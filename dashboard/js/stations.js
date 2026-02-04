(function () {
  const { db } = window.Dashboard;

  // Variables globales para listeners
  let stationsUnsubscribe = null;
  let reportsUnsubscribe = null;
  
  // Cache local para datos
  let allStations = [];
  let reportsStatsByStation = {};

  // Estados UI
  function getEmptyStateHtml() {
    return `
      <div class="empty-state">
        <div class="empty-state-icon">📍</div>
        <h3>No hay estaciones disponibles</h3>
        <p>Las estaciones aparecerán aquí cuando se registren reportes o se configure el sistema.</p>
        <div class="empty-state-actions">
          <button class="refresh-btn" onclick="refreshAll()">🔄 Actualizar</button>
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

  // --- LOGICA DE DATOS ---

  async function loadStations(showLoading = true) {
    if (showLoading) {
      const section = document.getElementById('stations');
      if (section) {
        const loadingElement = section.querySelector('.data-loading') || section.querySelector('.loading-state');
        if (loadingElement) loadingElement.style.display = 'block';
      }
    }
    
    // Si no hay listeners, inicializarlos preferentemente
    if (!stationsUnsubscribe) {
      initStationsRealtimeListeners();
    }
  }

  function processReportsStats(reportsSnapshot) {
    const stats = {};
    reportsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const stationId = data.objetivo || data.estacion || data.objetivo_id;
      if (!stationId) return;

      if (!stats[stationId]) {
        stats[stationId] = {
          total: 0,
          recent: [],
          byType: {},
          byStatus: {}
        };
      }

      const s = stats[stationId];
      s.total++;

      // Guardar últimos 3 reportes
      if (s.recent.length < 3) {
        s.recent.push({
          id: doc.id,
          data: data,
          timestamp: _getMillisFromPossibleTimestamp(data.creado_en || data.createdAt)
        });
      }

      const tipo = data.tipo || data.categoria || 'general';
      s.byType[tipo] = (s.byType[tipo] || 0) + 1;

      const estado = data.estado_principal || data.estado || 'normal';
      s.byStatus[estado] = (s.byStatus[estado] || 0) + 1;
    });
    return stats;
  }

  function initStationsRealtimeListeners() {
    if (stationsUnsubscribe) stationsUnsubscribe();
    if (reportsUnsubscribe) reportsUnsubscribe();

    console.log('📡 Inicializando listeners en tiempo real para Estaciones...');

    // Listener para Reportes (para estadísticas rápidas)
    reportsUnsubscribe = db.collection('reports')
      .orderBy('creado_en', 'desc')
      .limit(500) // Limitar a los más recientes para rendimiento
      .onSnapshot(snapshot => {
        reportsStatsByStation = processReportsStats(snapshot);
        renderCurrentView();
      }, error => console.error('Error en reports listener:', error));

    // Listener para Estaciones
    stationsUnsubscribe = db.collection('stations')
      .orderBy('nombre')
      .onSnapshot(snapshot => {
        allStations = snapshot.docs.map(doc => ({ id: doc.id, data: doc.data() }));
        renderCurrentView();
        
        const loadingElement = document.querySelector('#stations .data-loading') || document.querySelector('#stations .loading-state');
        if (loadingElement) loadingElement.style.display = 'none';
        
        showRealtimeIndicator('Estaciones actualizadas');
      }, error => {
        console.error('Error en stations listener:', error);
        showToast('Error de permisos en Firestore', 'error');
      });
  }

  // --- RENDERIZADO ---

  function renderCurrentView() {
    const activeBtn = document.querySelector('.view-btn.active');
    const viewType = activeBtn?.getAttribute('onclick')?.match(/'([^']+)'/)?.[1] || 'cards';
    
    if (viewType === 'lines') {
      renderStationsLines();
    } else {
      renderStationsCards();
    }
  }

  function renderStationsCards() {
    const section = document.getElementById('stations');
    if (!section) return;

    if (allStations.length === 0) {
      updateStationsContent(getEmptyStateHtml());
      return;
    }

    const stationsHtml = allStations.map(({ id, data }) => createStationCardHtml(id, data)).join('');
    const html = `<div id="stationsContainer" class="stations-grid">${stationsHtml}</div>`;
    updateStationsContent(html);
    updateCountLabel();
  }

  function renderStationsLines() {
    if (allStations.length === 0) {
      updateStationsContent(getEmptyStateHtml());
      return;
    }

    // Agrupar por línea
    const stationsByLine = {};
    allStations.forEach(({ id, data }) => {
      const line = data.linea || 'L1';
      if (!stationsByLine[line]) stationsByLine[line] = [];
      stationsByLine[line].push({ id, data });
    });

    const groupsHtml = Object.keys(stationsByLine).sort().map(linea => {
      const stations = stationsByLine[linea];
      const stationsHtml = stations.map(({ id, data }) => createStationMinimalCardHtml(id, data)).join('');

      return `
        <div class="line-group expanded" data-line="${linea.toLowerCase()}">
          <div class="line-header expanded" onclick="toggleLine('${linea}')">
            <div class="line-title">
              <span class="line-toggle">▶</span>
              <span class="line-badge" style="background: ${getLineColor(linea)}">Línea ${linea}</span>
              <span class="line-count">${stations.length} estaciones</span>
            </div>
          </div>
          <div class="line-stations">
            <div class="stations-grid mini">
              ${stationsHtml}
            </div>
          </div>
        </div>
      `;
    }).join('');

    const html = `<div id="stationsContainer" class="lines-view">${groupsHtml}</div>`;
    updateStationsContent(html);
    updateCountLabel();
  }

  function createStationCardHtml(id, data) {
    const stats = reportsStatsByStation[id] || { total: 0, recent: [], byType: {}, byStatus: {} };
    const confidence = data.confidence || 'low';
    const isEstimated = data.is_estimated || false;
    const lastUpdate = data.ultima_actualizacion ? 
      new Date(data.ultima_actualizacion.toMillis ? data.ultima_actualizacion.toMillis() : data.ultima_actualizacion).toLocaleString('es-PA') : 'N/A';

    return `
      <div class="station-card clickable" onclick="showStationDetails('${id}')" 
           data-station-name="${(data.nombre || id).toLowerCase()}"
           data-station-line="${(data.linea || 'L1').toLowerCase()}"
           data-station-state="${(data.estado_actual || 'normal').toLowerCase()}">
        <div class="station-header">
          <div class="station-title">
            <h3>${data.nombre || id}</h3>
            <span class="line-tag" style="background: ${getLineColor(data.linea)}">Línea ${data.linea || '1'}</span>
          </div>
          <div class="station-confidence">
            <span class="badge ${confidence === 'high' ? 'badge-high' : confidence === 'medium' ? 'badge-medium' : isEstimated ? 'badge-estimated' : 'badge-low'}">
              ${isEstimated ? '📊 Estimado' : confidence === 'high' ? '🟢 Alta' : confidence === 'medium' ? '🟡 Media' : '🔴 Baja'}
            </span>
          </div>
        </div>

        <div class="station-stats">
          <div class="stat-item">
            <div class="stat-value ${getStateColorClass(data.estado_actual)}">${data.estado_actual || 'Normal'}</div>
            <div class="stat-label">Estado</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">${data.aglomeracion || 1}/5</div>
            <div class="stat-label">Pasajeros</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">${stats.total}</div>
            <div class="stat-label">Reportes</div>
          </div>
        </div>

        <div class="station-footer">
          <div class="station-updated">🕒 ${lastUpdate}</div>
          <div class="view-detail">Ver más <i class="fas fa-chevron-right"></i></div>
        </div>
      </div>
    `;
  }

  function createStationMinimalCardHtml(id, data) {
    return `
      <div class="station-card mini clickable" onclick="showStationDetails('${id}')"
           data-station-name="${(data.nombre || id).toLowerCase()}"
           data-station-state="${(data.estado_actual || 'normal').toLowerCase()}">
        <div class="station-info-mini">
          <div class="status-dot-large ${getStateColorClass(data.estado_actual)}"></div>
          <div class="name-container">
            <div class="station-name-mini">${data.nombre || id}</div>
            <div class="station-status-mini">${data.estado_actual || 'Normal'}</div>
          </div>
        </div>
        <div class="station-stats-mini">
           <span><i class="fas fa-users"></i> ${data.aglomeracion || 1}/5</span>
        </div>
      </div>
    `;
  }

  // --- MODAL DETALLES ---

  async function showStationDetails(stationId) {
    const modal = document.getElementById('reportModal');
    const modalBody = document.getElementById('reportModalBody');
    const modalTitle = document.querySelector('#reportModal h3');

    if (modalTitle) modalTitle.innerHTML = '<i class="fas fa-map-marker-alt"></i> Detalles de Estación';
    
    modal.classList.add('active');
    modalBody.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i> Cargando detalles...</div>';

    try {
      const station = allStations.find(s => s.id === stationId);
      if (!station) {
        // Cargar de base de datos si no está en cache
        const doc = await db.collection('stations').doc(stationId).get();
        if (!doc.exists) throw new Error('Estación no encontrada');
        station = { id: doc.id, data: doc.data() };
      }

      const { data } = station;
      const stats = reportsStatsByStation[stationId] || { total: 0, recent: [] };
      
      const lastUpdate = data.ultima_actualizacion ? 
        new Date(data.ultima_actualizacion.toMillis ? data.ultima_actualizacion.toMillis() : data.ultima_actualizacion).toLocaleString('es-PA') : 'N/A';

      const html = `
        <div class="station-detail-view">
          <div class="detail-header" style="border-left: 8px solid ${getLineColor(data.linea)}">
            <h2>${data.nombre || stationId}</h2>
            <div class="detail-line-info">Línea ${data.linea || '1'}</div>
          </div>

          <div class="detail-grid">
            <div class="detail-card main-status">
              <div class="detail-label">Estado Operacional</div>
              <div class="detail-value ${getStateColorClass(data.estado_actual)}">${data.estado_actual || 'Normal'}</div>
              <div class="detail-sublabel">Aglomeración: ${data.aglomeracion || 1}/5</div>
            </div>

            <div class="detail-card">
              <div class="detail-label">Confianza del Sistema</div>
              <div class="detail-value">${data.confidence === 'high' ? 'Alta 🟢' : data.confidence === 'medium' ? 'Media 🟡' : 'Baja 🔴'}</div>
              <div class="detail-sublabel">${data.is_estimated ? 'Métricas estimadas por IA' : 'Basado en reportes reales'}</div>
            </div>
          </div>

          <div class="detail-section">
            <h3>📈 Histórico de Reportes</h3>
            <div class="detail-stats-row">
              <div class="stat-mini"><strong>${stats.total}</strong> <br>Totales</div>
              <div class="stat-mini"><strong>${Object.keys(stats.byType || {}).length}</strong> <br>Categorías</div>
            </div>
          </div>

          <div class="detail-section">
            <h3>📍 Ubicación y Actualización</h3>
            <p><strong>Dirección:</strong> ${data.direccion || data.ubicacion_nombre || 'No especificada'}</p>
            <p><strong>Coordenadas:</strong> ${data.ubicacion ? `${data.ubicacion.latitude}, ${data.ubicacion.longitude}` : 'No disponibles'}</p>
            <p><strong>Última actualización:</strong> ${lastUpdate}</p>
          </div>

          <div class="detail-actions">
            <button class="test-btn test-btn-primary" onclick="showTab('reports'); filterReportsListByStation('${stationId}'); closeReportModal()">
              <i class="fas fa-list"></i> Ver todos los reportes
            </button>
          </div>
        </div>
      `;
      modalBody.innerHTML = html;
    } catch (error) {
       modalBody.innerHTML = `<div class="error-msg">${error.message}</div>`;
    }
  }

  // --- UTILS ---

  function updateStationsContent(html) {
    const section = document.getElementById('stations');
    if (!section) return;
    
    let container = section.querySelector('#stationsContainer');
    if (container) {
      container.outerHTML = html;
    } else {
      section.insertAdjacentHTML('beforeend', html);
    }
  }

  function updateCountLabel() {
    const label = document.getElementById('stationsCount');
    if (label) label.textContent = `${allStations.length} estaciones`;
  }

  function getLineColor(line) {
    if (line === '1' || line === 'L1') return '#007bff';
    if (line === '2' || line === 'L2') return '#28a745';
    return '#6c757d';
  }

  function getStateColorClass(state) {
    const s = (state || '').toLowerCase();
    if (s === 'normal') return 'text-success';
    if (s === 'moderado' || s === 'retraso') return 'text-warning';
    if (s === 'lleno' || s === 'cerrado') return 'text-danger';
    return '';
  }

  function _getMillisFromPossibleTimestamp(t) {
    if (!t) return Date.now();
    if (t.toMillis) return t.toMillis();
    if (t instanceof Date) return t.getTime();
    if (typeof t === 'number') return t;
    return new Date(t).getTime();
  }

  // Sobrescribir funciones globales para interactividad
  window.loadStations = loadStations;
  window.loadStationsLines = renderStationsLines; // Ahora solo cambia render
  window.toggleLine = function(linea) {
    const group = document.querySelector(`.line-group[data-line="${linea.toLowerCase()}"]`);
    if (group) {
        group.classList.toggle('expanded');
        group.querySelector('.line-header')?.classList.toggle('expanded');
    }
  };
  window.setStationsView = function(view) {
    document.querySelectorAll('.view-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`[onclick*="${view}"]`)?.classList.add('active');
    renderCurrentView();
  };
  window.showStationDetails = showStationDetails;

  // Filtrado
  window.filterStations = function(query) {
    const q = (query || '').toLowerCase();
    const cards = document.querySelectorAll('.station-card');
    cards.forEach(card => {
       const text = card.textContent.toLowerCase();
       card.style.display = text.includes(q) ? '' : 'none';
    });
  };

  // Inicialización auto
  document.addEventListener('DOMContentLoaded', () => {
    // Si estamos en la pestaña de estaciones al cargar
    if (document.getElementById('stations').classList.contains('active')) {
        initStationsRealtimeListeners();
    }
  });

})();


