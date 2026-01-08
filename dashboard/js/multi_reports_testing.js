(function () {
  const { db, auth, firebase } = window.Dashboard;

  // Variables para el generador múltiple
  let availableStations = [];
  let generatedReports = [];

  // Cargar estaciones disponibles para múltiples reportes
  async function loadAvailableStations() {
    try {
      const snapshot = await db.collection('stations')
        .orderBy('nombre')
        .get();

      availableStations = snapshot.docs.map(doc => ({
        id: doc.id,
        data: doc.data(),
        selected: false
      }));

      renderStationsMultiSelect();
    } catch (error) {
      console.error('Error cargando estaciones:', error);
      document.getElementById('stationsMultiSelect').innerHTML =
        '<div class="testing-error">Error cargando estaciones</div>';
    }
  }

  // Renderizar selector múltiple de estaciones
  function renderStationsMultiSelect() {
    const container = document.getElementById('stationsMultiSelect');
    const html = availableStations.map(station => `
      <label>
        <input type="checkbox"
               value="${station.id}"
               onchange="toggleStation('${station.id}')"
               ${station.selected ? 'checked' : ''}>
        ${station.data.nombre || station.id} (${station.data.linea || 'L?'})
      </label>
    `).join('');

    container.innerHTML = html;
  }

  // Toggle selección de estación individual
  function toggleStation(stationId) {
    const station = availableStations.find(s => s.id === stationId);
    if (station) {
      station.selected = !station.selected;
      updateSelectAllCheckbox();
    }
  }

  // Toggle seleccionar todas las estaciones
  function toggleAllStations() {
    const selectAll = document.getElementById('selectAllStations').checked;
    availableStations.forEach(station => station.selected = selectAll);
    renderStationsMultiSelect();
  }

  // Actualizar checkbox "seleccionar todas"
  function updateSelectAllCheckbox() {
    const selectAll = document.getElementById('selectAllStations');
    const allSelected = availableStations.every(s => s.selected);
    const someSelected = availableStations.some(s => s.selected);

    selectAll.checked = allSelected;
    selectAll.indeterminate = someSelected && !allSelected;
  }

  // Toggle variedad de estados
  function toggleStateVariety() {
    const useVaried = document.getElementById('useVariedStates').checked;
    const stateOptions = document.getElementById('stateOptions');
    const fixedState = document.getElementById('fixedState');

    stateOptions.style.display = useVaried ? 'grid' : 'none';
    fixedState.style.display = useVaried ? 'none' : 'block';
  }

  // Obtener estados seleccionados
  function getSelectedStates() {
    if (!document.getElementById('useVariedStates').checked) {
      return [document.getElementById('fixedStateSelect').value];
    }

    return Array.from(document.querySelectorAll('input[name="states"]:checked'))
      .map(cb => cb.value);
  }

  // Generar distribución de tiempos
  function generateTimeDistribution(reportsCount, timeRange) {
    const distribution = document.querySelector('input[name="timeDistribution"]:checked').value;
    const times = [];

    switch (distribution) {
      case 'sequential':
        // Tiempos secuenciales: 1, 5, 10 minutos atrás
        const sequentialTimes = [1, 5, 10, 15, 20, 30, 45, 60];
        for (let i = 0; i < reportsCount; i++) {
          times.push(sequentialTimes[i % sequentialTimes.length]);
        }
        break;

      case 'random':
        // Tiempos aleatorios en el rango
        for (let i = 0; i < reportsCount; i++) {
          times.push(Math.floor(Math.random() * timeRange) + 1);
        }
        break;

      case 'clustered':
        // Agrupado: algunos reportes muy recientes, otros más antiguos
        const clusters = [
          [1, 2, 3],      // Grupo reciente
          [8, 10, 12],    // Grupo intermedio
          [25, 30, 35]   // Grupo antiguo
        ];

        for (let i = 0; i < reportsCount; i++) {
          const clusterIndex = i % clusters.length;
          const cluster = clusters[clusterIndex];
          times.push(cluster[i % cluster.length] || cluster[0]);
        }
        break;
    }

    return times.sort((a, b) => a - b); // Ordenar de más reciente a más antiguo
  }

  // Vista previa de reportes múltiples
  async function previewMultiReports() {
    const selectedStations = availableStations.filter(s => s.selected);
    if (selectedStations.length === 0) {
      showMultiStatus('❌ Selecciona al menos una estación', 'error');
      return;
    }

    const reportsPerStation = parseInt(document.getElementById('reportsPerStation').value) || 3;
    const timeRange = parseInt(document.getElementById('timeRange').value) || 15;
    const selectedStates = getSelectedStates();

    if (selectedStates.length === 0) {
      showMultiStatus('❌ Selecciona al menos un estado', 'error');
      return;
    }

    const statusDiv = document.getElementById('multiStatus');
    statusDiv.textContent = '👁️ Generando vista previa...';
    statusDiv.style.color = '#666';

    try {
      const previewData = [];
      const now = new Date();

      selectedStations.forEach(station => {
        const timeDistribution = generateTimeDistribution(reportsPerStation, timeRange);

        for (let i = 0; i < reportsPerStation; i++) {
          const minutesAgo = timeDistribution[i];
          const reportTime = new Date(now.getTime() - (minutesAgo * 60 * 1000));

          const stateIndex = i % selectedStates.length;
          const estado = selectedStates[stateIndex];

          previewData.push({
            stationId: station.id,
            stationName: station.data.nombre || station.id,
            timeAgo: minutesAgo,
            reportTime: reportTime,
            estado: estado,
            categoria: getCategoriaForEstado(estado),
            confidence: calculatePreviewConfidence(minutesAgo, i)
          });
        }
      });

      // Ordenar por tiempo (más reciente primero)
      previewData.sort((a, b) => a.timeAgo - b.timeAgo);

      renderPreviewTable(previewData);

      document.getElementById('multiPreview').style.display = 'block';
      showMultiStatus(`✅ Vista previa generada: ${previewData.length} reportes`, 'success');

    } catch (error) {
      showMultiStatus(`❌ Error en vista previa: ${error.message}`, 'error');
    }
  }

  // Obtener categoría basada en estado
  function getCategoriaForEstado(estado) {
    const mapping = {
      'normal': 'servicio_normal',
      'moderado': 'aglomeracion',
      'lleno': 'aglomeracion',
      'retraso': 'retraso',
      'cerrado': 'falla_tecnica'
    };
    return mapping[estado] || 'aglomeracion';
  }

  // Calcular confianza de vista previa
  function calculatePreviewConfidence(minutesAgo, confirmations) {
    let confidence = 0.5; // Base

    // Frescura
    if (minutesAgo <= 2) confidence += 0.1;
    else if (minutesAgo <= 5) confidence += 0.07;
    else if (minutesAgo <= 10) confidence += 0.03;

    // Confirmaciones simuladas
    const maxConf = parseInt(document.getElementById('maxConfirmations').value) || 2;
    const simConfirmations = Math.min(confirmations, maxConf);

    if (simConfirmations >= 3) confidence += 0.3;
    else if (simConfirmations >= 2) confidence += 0.2;
    else if (simConfirmations >= 1) confidence += 0.1;

    return Math.min(confidence, 1.0);
  }

  // Renderizar tabla de vista previa
  function renderPreviewTable(previewData) {
    const tableHtml = `
      <table class="preview-table">
        <thead>
          <tr>
            <th>🏢 Estación</th>
            <th>⏰ Tiempo</th>
            <th>📊 Estado</th>
            <th>🎯 Confianza</th>
            <th>👥 Confirmaciones</th>
          </tr>
        </thead>
        <tbody>
          ${previewData.map(item => `
            <tr>
              <td>${item.stationName}</td>
              <td class="time-cell">${item.timeAgo}min atrás</td>
              <td class="state-cell">
                <span class="badge badge-category-${item.categoria}">
                  ${item.estado}
                </span>
              </td>
              <td>${(item.confidence * 100).toFixed(0)}%</td>
              <td>${Math.min(item.confirmations || 0, parseInt(document.getElementById('maxConfirmations').value) || 2)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;

    document.getElementById('previewTable').innerHTML = tableHtml;
  }

  // Generar reportes múltiples
  async function generateMultiReports() {
    const selectedStations = availableStations.filter(s => s.selected);
    if (selectedStations.length === 0) {
      showMultiStatus('❌ Selecciona al menos una estación', 'error');
      return;
    }

    const confirm = window.confirm(
      `⚠️ ¿Generar ${selectedStations.length * parseInt(document.getElementById('reportsPerStation').value)} reportes de prueba?\n\n` +
      'Esto creará múltiples reportes que afectarán las estadísticas del dashboard.'
    );

    if (!confirm) return;

    const statusDiv = document.getElementById('multiStatus');
    statusDiv.textContent = '🚀 Generando reportes múltiples...';
    statusDiv.style.color = '#666';

    try {
      if (!auth.currentUser) {
        await window.authenticateDashboard?.();
      }
      const user = auth.currentUser;
      if (!user) {
        throw new Error('No se pudo autenticar');
      }

      const reportsPerStation = parseInt(document.getElementById('reportsPerStation').value) || 3;
      const timeRange = parseInt(document.getElementById('timeRange').value) || 15;
      const selectedStates = getSelectedStates();
      const simulateConfirmations = document.getElementById('simulateConfirmations').checked;
      const maxConfirmations = parseInt(document.getElementById('maxConfirmations').value) || 2;

      generatedReports = [];
      let totalReports = 0;

      for (const station of selectedStations) {
        const timeDistribution = generateTimeDistribution(reportsPerStation, timeRange);

        for (let i = 0; i < reportsPerStation; i++) {
          const minutesAgo = timeDistribution[i];
          const reportTime = new Date(Date.now() - (minutesAgo * 60 * 1000));

          const stateIndex = i % selectedStates.length;
          const estado = selectedStates[stateIndex];
          const categoria = getCategoriaForEstado(estado);

          // Crear reporte
          const report = {
            userId: user.uid,
            scope: 'station',
            stationId: station.id,
            categoria: categoria,
            estado_principal: estado,
            createdAt: firebase.firestore.Timestamp.fromDate(reportTime),
            creado_en: firebase.firestore.Timestamp.fromDate(reportTime),
            status: 'active',
            estado: 'activo',
            tipo: 'estacion',
            objetivo_id: station.id,
            descripcion: `Reporte múltiple generado automáticamente - ${estado}`,
            confidence: calculatePreviewConfidence(minutesAgo, simulateConfirmations ? Math.floor(Math.random() * maxConfirmations) : 0),
            confirmation_count: simulateConfirmations ? Math.floor(Math.random() * (maxConfirmations + 1)) : 0,
            verificaciones: 0,
            prioridad: false,
            ubicacion: station.data.ubicacion || new firebase.firestore.GeoPoint(8.9824, -79.5199)
          };

          const docRef = await db.collection('reports').add(report);
          generatedReports.push({
            id: docRef.id,
            stationId: station.id,
            stationName: station.data.nombre || station.id,
            timeAgo: minutesAgo,
            estado: estado,
            confidence: report.confidence,
            confirmations: report.confirmation_count
          });

          totalReports++;

          // Pequeño delay para evitar rate limits
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      // Mostrar resultados
      renderMultiResults(generatedReports);

      document.getElementById('multiResults').style.display = 'block';
      showMultiStatus(`✅ Generados ${totalReports} reportes exitosamente`, 'success');

      // Actualizar otras vistas
      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
        window.loadStations?.();
      }, 1000);

    } catch (error) {
      console.error('Error generando reportes múltiples:', error);
      showMultiStatus(`❌ Error: ${error.message}`, 'error');
    }
  }

  // Renderizar resultados de generación múltiple
  function renderMultiResults(reports) {
    // Resumen general
    const summaryHtml = `
      <div class="results-summary">
        <div class="result-card">
          <h5>📊 Total Reportes</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${reports.length}</div>
        </div>
        <div class="result-card">
          <h5>🏢 Estaciones</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${new Set(reports.map(r => r.stationId)).size}</div>
        </div>
        <div class="result-card">
          <h5>🎯 Confianza Promedio</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">
            ${(reports.reduce((sum, r) => sum + r.confidence, 0) / reports.length * 100).toFixed(0)}%
          </div>
        </div>
        <div class="result-card">
          <h5>👥 Confirmaciones Totales</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">
            ${reports.reduce((sum, r) => sum + r.confirmations, 0)}
          </div>
        </div>
      </div>
    `;

    // Agrupar por estación
    const byStation = {};
    reports.forEach(report => {
      if (!byStation[report.stationId]) {
        byStation[report.stationId] = {
          name: report.stationName,
          reports: []
        };
      }
      byStation[report.stationId].reports.push(report);
    });

    const stationsHtml = `
      <div class="station-results">
        ${Object.entries(byStation).map(([stationId, data]) => `
          <div class="station-result-card">
            <h5>${data.name}</h5>
            <div class="station-reports">
              ${data.reports.map(report => `
                <div class="station-report-item">
                  <span>${report.timeAgo}min atrás - ${report.estado}</span>
                  <span>${(report.confidence * 100).toFixed(0)}% / ${report.confirmations} conf</span>
                </div>
              `).join('')}
            </div>
          </div>
        `).join('')}
      </div>
    `;

    document.getElementById('resultsSummary').innerHTML = summaryHtml;
    document.getElementById('resultsStations').innerHTML = stationsHtml;
  }

  // Limpiar reportes de prueba múltiples
  async function clearMultiTestReports() {
    if (generatedReports.length === 0) {
      showMultiStatus('❌ No hay reportes generados para limpiar', 'error');
      return;
    }

    const confirm = window.confirm(
      `⚠️ ¿Eliminar ${generatedReports.length} reportes de prueba generados?\n\n` +
      'Esta acción no se puede deshacer.'
    );

    if (!confirm) return;

    const statusDiv = document.getElementById('multiStatus');
    statusDiv.textContent = '🗑️ Eliminando reportes de prueba...';
    statusDiv.style.color = '#666';

    try {
      const batchSize = 10;
      let deleted = 0;

      for (let i = 0; i < generatedReports.length; i += batchSize) {
        const batch = db.batch();
        const batchReports = generatedReports.slice(i, i + batchSize);

        batchReports.forEach(report => {
          batch.delete(db.collection('reports').doc(report.id));
        });

        await batch.commit();
        deleted += batchReports.length;

        statusDiv.textContent = `🗑️ Eliminando... ${deleted}/${generatedReports.length}`;
      }

      generatedReports = [];
      document.getElementById('multiResults').style.display = 'none';
      document.getElementById('multiPreview').style.display = 'none';

      showMultiStatus(`✅ Eliminados ${deleted} reportes de prueba`, 'success');

      // Actualizar otras vistas
      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
        window.loadStations?.();
      }, 1000);

    } catch (error) {
      showMultiStatus(`❌ Error eliminando reportes: ${error.message}`, 'error');
    }
  }

  // Función helper para mostrar status múltiple
  function showMultiStatus(message, type = 'info') {
    const statusDiv = document.getElementById('multiStatus');
    if (!statusDiv) return;

    statusDiv.textContent = message;
    statusDiv.style.color = type === 'error' ? '#dc3545' : type === 'success' ? '#28a745' : '#666';
  }

  // Exponer funciones globales para múltiples reportes
  window.loadAvailableStations = loadAvailableStations;
  window.toggleAllStations = toggleAllStations;
  window.toggleStation = toggleStation;
  window.toggleStateVariety = toggleStateVariety;
  window.previewMultiReports = previewMultiReports;
  window.generateMultiReports = generateMultiReports;
  window.clearMultiTestReports = clearMultiTestReports;
})();
