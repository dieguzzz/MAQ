(function () {
  const { db, auth, firebase } = window.Dashboard;

  // Variables para el testing
  let availableStations = [];
  let generatedTrainReports = [];

  // Direcciones por línea (usar códigos A/B como en la app)
  const lineDirections = {
    linea1: [
      { id: 'A', name: 'Hacia Villa Zaita', label: 'Villa Zaita' },
      { id: 'B', name: 'Hacia Albrook', label: 'Albrook' }
    ],
    linea2: [
      { id: 'A', name: 'Hacia Nuevo Tocumen', label: 'Nuevo Tocumen' },
      { id: 'B', name: 'Hacia San Miguelito', label: 'San Miguelito' }
    ]
  };

  // Cargar estaciones disponibles
  async function loadTrainTimeStations() {
    console.log('🔄 Cargando estaciones para testing de tiempos de tren...');
    try {
      const snapshot = await db.collection('stations')
        .orderBy('nombre')
        .get();

      availableStations = snapshot.docs.map(doc => ({
        id: doc.id,
        data: doc.data(),
        name: doc.data().nombre || doc.id,
        line: doc.data().linea
      }));

      console.log(`✅ Cargadas ${availableStations.length} estaciones`);
      renderTrainTimeStations();
    } catch (error) {
      console.error('❌ Error cargando estaciones:', error);
      showTrainTimeStatus('❌ Error cargando estaciones', 'error');
    }
  }

  // Renderizar selector de estaciones
  function renderTrainTimeStations() {
    const select = document.getElementById('trainTimeStationSelect');
    if (!select) {
      console.error('❌ No se encontró el selector trainTimeStationSelect');
      return;
    }
    
    const html = [
      '<option value="">Selecciona estación...</option>',
      ...availableStations.map(station =>
        `<option value="${station.id}" data-line="${station.line}">${station.name} (${station.line})</option>`
      )
    ].join('');

    select.innerHTML = html;
    console.log(`✅ Renderizadas ${availableStations.length} estaciones en el selector`);
  }

  // Cuando cambia la estación, actualizar direcciones disponibles
  function onTrainTimeStationChanged() {
    const stationSelect = document.getElementById('trainTimeStationSelect');
    const directionSelect = document.getElementById('trainTimeDirectionSelect');
    
    if (!stationSelect || !directionSelect) {
      console.error('❌ No se encontraron los selectores');
      return;
    }
    
    const selectedOption = stationSelect.options[stationSelect.selectedIndex];
    const line = selectedOption?.getAttribute('data-line');
    
    console.log(`🔄 Estación seleccionada, línea: ${line}`);

    if (!line || !lineDirections[line]) {
      directionSelect.innerHTML = '<option value="">Selecciona dirección...</option>';
      console.log('⚠️ No hay direcciones disponibles para esta línea');
      return;
    }

    const directions = lineDirections[line];
    const html = [
      '<option value="">Selecciona dirección...</option>',
      ...directions.map(dir => `<option value="${dir.id}">${dir.name}</option>`)
    ].join('');

    directionSelect.innerHTML = html;
    console.log(`✅ Cargadas ${directions.length} direcciones para ${line}`);
  }

  // Vista previa de reportes de tiempos
  async function previewTrainTimeReports() {
    const stationId = document.getElementById('trainTimeStationSelect').value;
    const direction = document.getElementById('trainTimeDirectionSelect').value;
    const nextTrainTime = document.getElementById('nextTrainTimeSelect').value;
    const followingTrainTime = document.getElementById('followingTrainTimeSelect').value;
    const reportCount = parseInt(document.getElementById('trainTimeReportCount').value) || 5;
    const interval = parseInt(document.getElementById('trainTimeInterval').value) || 30;
    const addVariation = document.getElementById('addTimeVariation').checked;

    if (!stationId || !direction) {
      showTrainTimeStatus('❌ Selecciona estación y dirección', 'error');
      return;
    }

    if (!nextTrainTime) {
      showTrainTimeStatus('❌ Selecciona tiempo del próximo tren', 'error');
      return;
    }

    const statusDiv = document.getElementById('trainTimeStatus');
    statusDiv.textContent = '👁️ Generando vista previa...';
    statusDiv.style.color = '#666';

    try {
      const station = availableStations.find(s => s.id === stationId);
      const previewReports = [];
      const baseTime = new Date();

      // Obtener nombre de dirección una vez (fuera del loop)
      const directionOption = lineDirections[station.line]?.find(d => d.id === direction);
      const directionName = directionOption ? directionOption.name : `Dirección ${direction}`;

      for (let i = 0; i < reportCount; i++) {
        const reportTime = new Date(baseTime.getTime() + (i * interval * 1000));

        // Calcular tiempo con variación
        let actualNextTime = parseInt(nextTrainTime);
        let actualFollowingTime = followingTrainTime ? parseInt(followingTrainTime) : null;

        if (addVariation) {
          actualNextTime += Math.floor(Math.random() * 5) - 2; // ±2 min
          actualNextTime = Math.max(1, Math.min(12, actualNextTime));

          if (actualFollowingTime) {
            actualFollowingTime += Math.floor(Math.random() * 5) - 2;
            actualFollowingTime = Math.max(1, Math.min(12, actualFollowingTime));
          }
        }

        previewReports.push({
        stationId: stationId,
        stationName: station.name,
        line: station.line,
        direction: direction,
        directionName: directionName,
        nextTrainMinutes: actualNextTime,
        followingTrainMinutes: actualFollowingTime,
        reportedAt: reportTime,
        etaBucket: convertMinutesToBucket(actualNextTime),
        points: 10 + (actualFollowingTime ? 5 : 0)
      });
      }

      renderTrainTimePreview(previewReports);

      document.getElementById('trainTimePreview').style.display = 'block';
      showTrainTimeStatus(`✅ Vista previa generada: ${previewReports.length} reportes`, 'success');

    } catch (error) {
      showTrainTimeStatus(`❌ Error en vista previa: ${error.message}`, 'error');
    }
  }

  // Renderizar vista previa
  function renderTrainTimePreview(reports) {
    const html = `
      <div class="preview-reports-table">
        <table class="preview-table">
          <thead>
            <tr>
              <th>⏰ Reportado</th>
              <th>🏢 Estación</th>
              <th>🎯 Dirección</th>
              <th>🚇 Rango ETA</th>
              <th>📱 Fuente</th>
              <th>🏆 Puntos</th>
            </tr>
          </thead>
          <tbody>
            ${reports.map(report => `
              <tr>
                <td>${report.reportedAt.toLocaleTimeString('es-PA')}</td>
                <td>${report.stationName}</td>
                <td>${report.directionName || report.direction}</td>
                <td>${report.etaBucket}</td>
                <td>📱 Pantalla oficial</td>
                <td>${report.points}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;

    document.getElementById('trainTimePreviewContent').innerHTML = html;
  }

  // Generar reportes de tiempos de tren
  async function generateTrainTimeReports() {
    const stationId = document.getElementById('trainTimeStationSelect').value;
    const direction = document.getElementById('trainTimeDirectionSelect').value;
    const nextTrainTime = document.getElementById('nextTrainTimeSelect').value;
    const followingTrainTime = document.getElementById('followingTrainTimeSelect').value;
    const reportCount = parseInt(document.getElementById('trainTimeReportCount').value) || 5;
    const interval = parseInt(document.getElementById('trainTimeInterval').value) || 30;
    const addVariation = document.getElementById('addTimeVariation').checked;

    if (!stationId) {
      showTrainTimeStatus('❌ Selecciona una estación', 'error');
      return;
    }
    if (!direction) {
      showTrainTimeStatus('❌ Selecciona una dirección', 'error');
      return;
    }
    if (!nextTrainTime) {
      showTrainTimeStatus('❌ Selecciona el tiempo del próximo tren', 'error');
      return;
    }

    const confirm = window.confirm(
      `⚠️ ¿Generar ${reportCount} reportes de tiempos de tren?\n\n` +
      'Esto creará reportes que aparecerán en la aplicación Flutter.'
    );

    if (!confirm) return;

    const statusDiv = document.getElementById('trainTimeStatus');
    statusDiv.textContent = '🚀 Generando reportes de tiempos...';
    statusDiv.style.color = '#666';

    try {
      if (!auth.currentUser) {
        await window.authenticateDashboard?.();
      }
      const user = auth.currentUser;
      if (!user) {
        throw new Error('No se pudo autenticar');
      }

      const station = availableStations.find(s => s.id === stationId);
      generatedTrainReports = [];
      let totalReports = 0;

      // Obtener directionLabel y directionName una vez (fuera del loop)
      const directionOption = lineDirections[station.line]?.find(d => d.id === direction);
      const directionLabel = directionOption ? directionOption.label : null;
      const directionName = directionOption ? directionOption.name : `Dirección ${direction}`;

      for (let i = 0; i < reportCount; i++) {
        const reportTime = new Date(Date.now() + (i * interval * 1000));

        // Calcular tiempo con variación
        let actualNextTime = parseInt(nextTrainTime);
        let actualFollowingTime = followingTrainTime ? parseInt(followingTrainTime) : null;

        if (addVariation) {
          actualNextTime += Math.floor(Math.random() * 5) - 2;
          actualNextTime = Math.max(1, Math.min(12, actualNextTime));

          if (actualFollowingTime) {
            actualFollowingTime += Math.floor(Math.random() * 5) - 2;
            actualFollowingTime = Math.max(1, Math.min(12, actualFollowingTime));
          }
        }

        // Crear reporte usando el formato correcto de SimplifiedReportModel
        const etaBucket = convertMinutesToBucket(actualNextTime);
        const etaExpectedAt = etaBucket !== 'unknown' ?
          new Date(reportTime.getTime() + (actualNextTime * 60 * 1000)) : null;

        const reportData = {
          // Campos requeridos por SimplifiedReportModel
          scope: 'train',
          stationId: stationId,
          userId: user.uid,

          // Campos específicos de tren
          etaBucket: etaBucket,
          etaExpectedAt: etaExpectedAt ? firebase.firestore.Timestamp.fromDate(etaExpectedAt) : null,
          direction: direction, // 'A' o 'B'
          directionLabel: directionLabel, // Nombre legible (Villa Zaita, Albrook, etc)
          trainLine: station.line, // 'linea1' o 'linea2'
          isPanelTime: true, // Alta confianza - viene de pantalla oficial

          // Campos comunes
          createdAt: firebase.firestore.Timestamp.fromDate(reportTime),
          basePoints: 10,
          bonusPoints: actualFollowingTime ? 5 : 0,
          totalPoints: 10 + (actualFollowingTime ? 5 : 0),
          status: 'active',
          confirmations: 0,
          confidence: 0.9, // Alta confianza para reportes de pantalla
          confidenceReasons: ['panel']
        };

        const docRef = await db.collection('reports').add(reportData);
        await docRef.update({'id': docRef.id});

        generatedTrainReports.push({
          id: docRef.id,
          stationId: stationId,
          stationName: station.name,
          direction: direction,
          directionName: directionName,
          nextTrainMinutes: actualNextTime,
          followingTrainMinutes: actualFollowingTime,
          reportedAt: reportTime,
          etaBucket: etaBucket,
          points: reportData.totalPoints
        });

        totalReports++;

        // Pequeño delay para evitar rate limits
        await new Promise(resolve => setTimeout(resolve, 200));
      }

      // Mostrar resultados
      renderTrainTimeResults(generatedTrainReports);

      document.getElementById('trainTimeResults').style.display = 'block';
      showTrainTimeStatus(`✅ Generados ${totalReports} reportes de tiempos`, 'success');

      // Actualizar vistas relacionadas
      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      console.error('Error generando reportes de tiempos:', error);
      showTrainTimeStatus(`❌ Error: ${error.message}`, 'error');
    }
  }

  // Convertir minutos a bucket (formato usado por la app)
  function convertMinutesToBucket(minutes) {
    if (minutes <= 2) return '1-2';
    if (minutes <= 5) return '3-5';
    if (minutes <= 8) return '6-8';
    if (minutes <= 12) return '9+';
    return 'unknown';
  }

  // Convertir minutos a rango (compatibilidad legacy)
  function convertMinutesToRange(minutes) {
    if (minutes <= 1) return '0-1';
    if (minutes === 2) return '2';
    if (minutes === 3) return '3';
    if (minutes === 4) return '4';
    if (minutes === 5) return '5';
    return '5+';
  }

  // Renderizar resultados
  function renderTrainTimeResults(reports) {
    const totalPoints = reports.reduce((sum, r) => sum + r.points, 0);
    const avgNextTrain = reports.reduce((sum, r) => sum + r.nextTrainMinutes, 0) / reports.length;
    const withFollowing = reports.filter(r => r.followingTrainMinutes).length;

    const html = `
      <div class="results-summary">
        <div class="result-card">
          <h5>📊 Total Reportes</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${reports.length}</div>
        </div>
        <div class="result-card">
          <h5>🏆 Puntos Totales</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${totalPoints}</div>
        </div>
        <div class="result-card">
          <h5>⏰ Tiempo Promedio</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${avgNextTrain.toFixed(1)} min</div>
        </div>
        <div class="result-card">
          <h5>🚇 Con Siguiente Tren</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${withFollowing}/${reports.length}</div>
        </div>
      </div>

        <div class="generated-reports-list">
          <h5>Reportes Generados:</h5>
          <div class="reports-list">
            ${reports.map(report => `
              <div class="report-item">
                <span>${report.reportedAt.toLocaleTimeString('es-PA')}</span>
                <span>${report.stationName} → ${report.directionName || report.direction}</span>
                <span>🚇 ${report.etaBucket} ${report.nextTrainMinutes ? `(${report.nextTrainMinutes}min)` : ''}</span>
                <span>🏆 ${report.points}pts</span>
              </div>
            `).join('')}
          </div>
        </div>
    `;

    document.getElementById('trainTimeResultsContent').innerHTML = html;
  }

  // Mostrar analytics de tiempos de tren
  async function showTrainTimeAnalytics() {
    const statusDiv = document.getElementById('trainTimeStatus');
    statusDiv.textContent = '📈 Cargando analytics...';
    statusDiv.style.color = '#666';

    try {
      // Obtener reportes recientes (últimas 24 horas)
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      const snapshot = await db.collection('reports')
        .where('scope', '==', 'train')
        .where('createdAt', '>', firebase.firestore.Timestamp.fromDate(yesterday))
        .orderBy('createdAt', 'desc')
        .get();

      if (snapshot.empty) {
        document.getElementById('trainTimeAnalyticsContent').innerHTML =
          '<div class="testing-error">No hay reportes recientes para analizar</div>';
        document.getElementById('trainTimeAnalytics').style.display = 'block';
        showTrainTimeStatus('ℹ️ No hay datos para analytics', 'info');
        return;
      }

      const reports = snapshot.docs.map(doc => doc.data());

      // Análisis por línea
      const byLine = {};
      const byStation = {};
      const timeRanges = {};

      reports.forEach(report => {
        // Por línea
        const line = report.trainLine || 'unknown';
        if (!byLine[line]) byLine[line] = { count: 0, totalPoints: 0, avgTime: 0, times: [] };
        byLine[line].count++;
        byLine[line].totalPoints += report.totalPoints || 0;

        // Por estación
        const stationId = report.stationId;
        if (!byStation[stationId]) byStation[stationId] = { count: 0, totalPoints: 0 };
        byStation[stationId].count++;
        byStation[stationId].totalPoints += report.totalPoints || 0;

        // Rangos de tiempo (etaBucket)
        const range = report.etaBucket || 'unknown';
        if (!timeRanges[range]) timeRanges[range] = 0;
        timeRanges[range]++;
      });

      // Calcular promedios
      Object.keys(byLine).forEach(line => {
        if (byLine[line].times.length > 0) {
          byLine[line].avgTime = byLine[line].times.reduce((a, b) => a + b, 0) / byLine[line].times.length;
        }
      });

      const analyticsHtml = `
        <div class="analytics-grid">
          <div class="analytics-section">
            <h5>🚇 Por Línea</h5>
            ${Object.entries(byLine).map(([line, data]) => `
              <div class="analytics-item">
                <strong>Línea ${line}:</strong> ${data.count} reportes,
                ${data.avgTime.toFixed(1)}min promedio,
                ${data.totalPoints} puntos
              </div>
            `).join('')}
          </div>

          <div class="analytics-section">
            <h5>🏢 Por Estación</h5>
            ${Object.entries(byStation).slice(0, 10).map(([stationId, data]) => `
              <div class="analytics-item">
                <strong>${stationId}:</strong> ${data.count} reportes, ${data.totalPoints} puntos
              </div>
            `).join('')}
          </div>

          <div class="analytics-section">
            <h5>⏰ Rangos de Tiempo</h5>
            ${Object.entries(timeRanges).map(([range, count]) => `
              <div class="analytics-item">
                <strong>${range}:</strong> ${count} reportes
              </div>
            `).join('')}
          </div>
        </div>

        <div class="analytics-summary">
          <h5>📊 Resumen General</h5>
        <div class="summary-stats">
          <div>Total reportes (24h): <strong>${reports.length}</strong></div>
          <div>Puntos totales: <strong>${reports.reduce((sum, r) => sum + (r.totalPoints || 0), 0)}</strong></div>
          <div>Reportes de pantalla: <strong>${reports.filter(r => r.isPanelTime).length}</strong></div>
        </div>
        </div>
      `;

      document.getElementById('trainTimeAnalyticsContent').innerHTML = analyticsHtml;
      document.getElementById('trainTimeAnalytics').style.display = 'block';
      showTrainTimeStatus(`✅ Analytics cargados: ${reports.length} reportes analizados`, 'success');

    } catch (error) {
      showTrainTimeStatus(`❌ Error en analytics: ${error.message}`, 'error');
    }
  }

  // Limpiar reportes de prueba
  async function clearTrainTimeReports() {
    if (generatedTrainReports.length === 0) {
      showTrainTimeStatus('❌ No hay reportes generados para limpiar', 'error');
      return;
    }

    const confirm = window.confirm(
      `⚠️ ¿Eliminar ${generatedTrainReports.length} reportes de tiempos de tren?\n\n` +
      'Esta acción no se puede deshacer.'
    );

    if (!confirm) return;

    const statusDiv = document.getElementById('trainTimeStatus');
    statusDiv.textContent = '🗑️ Eliminando reportes...';
    statusDiv.style.color = '#666';

    try {
      const batchSize = 10;
      let deleted = 0;

      for (let i = 0; i < generatedTrainReports.length; i += batchSize) {
        const batch = db.batch();
        const batchReports = generatedTrainReports.slice(i, i + batchSize);

        batchReports.forEach(report => {
          batch.delete(db.collection('reports').doc(report.id));
        });

        await batch.commit();
        deleted += batchReports.length;
      }

      generatedTrainReports = [];

      // Ocultar resultados
      document.getElementById('trainTimeResults').style.display = 'none';
      document.getElementById('trainTimePreview').style.display = 'none';
      document.getElementById('trainTimeAnalytics').style.display = 'none';

      showTrainTimeStatus(`✅ Eliminados ${deleted} reportes de tiempos`, 'success');

      // Actualizar stats
      setTimeout(() => {
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      showTrainTimeStatus(`❌ Error eliminando reportes: ${error.message}`, 'error');
    }
  }

  // Función helper para mostrar status
  function showTrainTimeStatus(message, type = 'info') {
    const statusDiv = document.getElementById('trainTimeStatus');
    if (!statusDiv) return;

    statusDiv.textContent = message;
    statusDiv.style.color = type === 'error' ? '#dc3545' : type === 'success' ? '#28a745' : '#666';
  }

  // Generar reportes de "Llegó el metro" (arrivalTime)
  async function generateTrainArrivalReports() {
    const stationId = document.getElementById('trainTimeStationSelect').value;
    const direction = document.getElementById('trainTimeDirectionSelect').value;
    const reportCount = parseInt(document.getElementById('arrivalReportCount')?.value) || 3;
    const interval = parseInt(document.getElementById('arrivalInterval')?.value) || 60;

    if (!stationId || !direction) {
      showTrainTimeStatus('❌ Selecciona estación y dirección', 'error');
      return;
    }

    const confirm = window.confirm(
      `⚠️ ¿Generar ${reportCount} reportes de "Llegó el metro"?\n\n` +
      'Esto creará reportes de llegadas confirmadas para probar el panel de la app.'
    );

    if (!confirm) return;

    const statusDiv = document.getElementById('trainTimeStatus');
    statusDiv.textContent = '🚇 Generando reportes de llegadas...';
    statusDiv.style.color = '#666';

    try {
      if (!auth.currentUser) {
        await window.authenticateDashboard?.();
      }
      const user = auth.currentUser;
      if (!user) {
        throw new Error('No se pudo autenticar');
      }

      const station = availableStations.find(s => s.id === stationId);
      let totalReports = 0;

      // Obtener directionLabel una vez (fuera del loop)
      const directionOption = lineDirections[station.line]?.find(d => d.id === direction);
      const directionLabel = directionOption ? directionOption.label : null;

      for (let i = 0; i < reportCount; i++) {
        const arrivalTime = new Date(Date.now() + (i * interval * 1000));

        const reportData = {
          scope: 'train',
          stationId: stationId,
          userId: user.uid,
          direction: direction,
          directionLabel: directionLabel,
          trainLine: station.line,
          arrivalTime: firebase.firestore.Timestamp.fromDate(arrivalTime),
          createdAt: firebase.firestore.Timestamp.fromDate(arrivalTime),
          basePoints: 15,
          bonusPoints: 0,
          totalPoints: 15,
          status: 'active',
          confirmations: 0,
          confidence: 0.9,
          confidenceReasons: ['direct_arrival']
        };

        const docRef = await db.collection('reports').add(reportData);
        await docRef.update({'id': docRef.id});

        totalReports++;

        // Pequeño delay para evitar rate limits
        await new Promise(resolve => setTimeout(resolve, 200));
      }

      showTrainTimeStatus(`✅ Generados ${totalReports} reportes de llegadas`, 'success');

      // Actualizar vistas relacionadas
      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      console.error('Error generando reportes de llegadas:', error);
      showTrainTimeStatus(`❌ Error: ${error.message}`, 'error');
    }
  }

  // Función de diagnóstico: verificar que los reportes generan eta_groups
  async function verifyEtaGroupsCreation() {
    try {
      showTrainTimeStatus('🔍 Verificando creación de eta_groups...', 'info');

      const stationSelect = document.getElementById('trainTimeStationSelect');
      const stationId = stationSelect.value;

      if (!stationId) {
        showTrainTimeStatus('❌ Selecciona una estación primero', 'error');
        return;
      }

      // Consultar reportes recientes de esta estación
      const reportsSnap = await db.collection('reports')
        .where('scope', '==', 'train')
        .where('stationId', '==', stationId)
        .orderBy('createdAt', 'desc')
        .limit(5)
        .get();

      // Consultar eta_groups recientes
      const etaGroupsSnap = await db.collection('eta_groups')
        .where('stationId', '==', stationId)
        .where('status', '==', 'active')
        .orderBy('bucketStart', 'desc')
        .limit(10)
        .get();

      let html = `
        <div class="verification-results">
          <h4>📊 Diagnóstico de Reportes → ETA Groups</h4>
          
          <div class="verification-section">
            <h5>📝 Reportes Recientes (scope='train')</h5>
            ${reportsSnap.empty ? '<p>No hay reportes recientes</p>' : ''}
            ${reportsSnap.docs.map(doc => {
              const data = doc.data();
              return `
                <div class="report-item" style="font-size: 0.85rem; padding: 8px; background: #f8f9fa; margin: 4px 0; border-radius: 4px;">
                  <strong>ID:</strong> ${doc.id.substring(0, 8)}...<br>
                  <strong>Estación:</strong> ${data.stationId}<br>
                  <strong>Dirección:</strong> ${data.direction} (${data.trainLine})<br>
                  <strong>ETA Bucket:</strong> ${data.etaBucket}<br>
                  <strong>Creado:</strong> ${data.createdAt?.toDate?.().toLocaleTimeString('es-PA') || 'N/A'}<br>
                  ${data.isPanelTime ? '📱 <strong>Fuente: Panel oficial</strong>' : ''}
                </div>
              `;
            }).join('')}
          </div>

          <div class="verification-section" style="margin-top: 1rem;">
            <h5>🎯 ETA Groups Activos</h5>
            ${etaGroupsSnap.empty ? '<p>⚠️ No hay eta_groups activos (las Cloud Functions no han procesado los reportes)</p>' : ''}
            ${etaGroupsSnap.docs.map(doc => {
              const data = doc.data();
              return `
                <div class="report-item" style="font-size: 0.85rem; padding: 8px; background: #e7f3ff; margin: 4px 0; border-radius: 4px;">
                  <strong>ID:</strong> ${doc.id.substring(0, 12)}...<br>
                  <strong>Dirección:</strong> ${data.directionCode} → ${data.directionLabel || 'N/A'}<br>
                  <strong>Próximo:</strong> ${data.nextEtaBucket} (${data.nextEtaMinutesP50 || '?'} min)<br>
                  <strong>Siguiente:</strong> ${data.followingEtaBucket || 'N/A'} (${data.followingEtaMinutesP50 || '?'} min)<br>
                  <strong>Reportes:</strong> ${data.reportCount} | <strong>Confianza:</strong> ${(data.confidence * 100).toFixed(0)}%<br>
                  <strong>Actualizado:</strong> ${data.updatedAt?.toDate?.().toLocaleTimeString('es-PA') || 'N/A'}<br>
                  <strong>Expira:</strong> ${data.expiresAt?.toDate?.().toLocaleTimeString('es-PA') || 'N/A'}
                </div>
              `;
            }).join('')}
          </div>

          <div class="verification-section" style="margin-top: 1rem; padding: 12px; background: #fff3cd; border-radius: 6px;">
            <strong>📝 Resumen:</strong><br>
            • Reportes generados: ${generatedTrainReports.length}<br>
            • Reportes en Firestore: ${reportsSnap.size}<br>
            • ETA Groups creados: ${etaGroupsSnap.size}<br>
            ${etaGroupsSnap.empty ? '<br><strong style="color: #856404;">⚠️ Si hay reportes pero no eta_groups, las Cloud Functions pueden tener un error. Revisa los logs de Firebase.</strong>' : ''}
            ${etaGroupsSnap.empty && reportsSnap.empty ? '<br><strong style="color: #856404;">ℹ️ No hay reportes ni grupos. Genera reportes primero.</strong>' : ''}
          </div>
        </div>
      `;

      const resultDiv = document.getElementById('trainTimeVerification') || (() => {
        const div = document.createElement('div');
        div.id = 'trainTimeVerification';
        div.className = 'train-time-results';
        div.style.display = 'block';
        div.style.marginTop = '1rem';
        document.getElementById('trainTimeResults').parentElement.appendChild(div);
        return div;
      })();

      resultDiv.innerHTML = html;
      resultDiv.style.display = 'block';

      showTrainTimeStatus('✅ Verificación completada', 'success');
    } catch (error) {
      console.error('Error verificando eta_groups:', error);
      showTrainTimeStatus(`❌ Error en verificación: ${error.message}`, 'error');
    }
  }

  // Exponer funciones globales
  window.loadTrainTimeStations = loadTrainTimeStations;
  window.onTrainTimeStationChanged = onTrainTimeStationChanged;
  window.previewTrainTimeReports = previewTrainTimeReports;
  window.generateTrainTimeReports = generateTrainTimeReports;
  window.generateTrainArrivalReports = generateTrainArrivalReports;
  window.showTrainTimeAnalytics = showTrainTimeAnalytics;
  window.clearTrainTimeReports = clearTrainTimeReports;
  window.verifyEtaGroupsCreation = verifyEtaGroupsCreation;
})();
