/**
 * Load Testing Module - Pruebas de carga masiva para MetroPTY
 * Soporta generacion de miles de reportes en paralelo usando Firestore batches
 */
(function () {
  const { db, auth, firebase } = window.Dashboard;

  // Estado del modulo
  let loadTestState = {
    isRunning: false,
    isPaused: false,
    totalReports: 0,
    completedReports: 0,
    failedReports: 0,
    startTime: null,
    generatedIds: [],
    metrics: {
      reportsPerSecond: 0,
      avgLatency: 0,
      latencies: []
    }
  };

  // Configuracion por defecto
  const DEFAULT_CONFIG = {
    batchSize: 400, // Firestore permite hasta 500 ops por batch
    parallelBatches: 3, // Batches en paralelo
    delayBetweenBatches: 50, // ms
    reportTypes: ['station', 'trainTime'], // Tipos de reportes
    stationDistribution: 0.7, // 70% station, 30% trainTime
  };

  // Estaciones cargadas
  let loadedStations = [];

  // Cargar estaciones al inicializar
  async function loadStationsForLoadTest() {
    try {
      const snapshot = await db.collection('stations').orderBy('nombre').get();
      loadedStations = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      console.log(`[LoadTest] Cargadas ${loadedStations.length} estaciones`);
      updateStationCount();
    } catch (error) {
      console.error('[LoadTest] Error cargando estaciones:', error);
    }
  }

  function updateStationCount() {
    const countEl = document.getElementById('loadTestStationCount');
    if (countEl) {
      countEl.textContent = `${loadedStations.length} estaciones disponibles`;
    }
  }

  // Generar datos aleatorios para reportes de estacion
  function generateStationReportData(userId, station) {
    const estados = ['yes', 'partial', 'no'];
    const crowdLevels = [1, 2, 3, 4, 5];
    const lines = ['L1', 'L2'];
    const directions = ['A', 'B'];

    const minutesAgo = Math.floor(Math.random() * 30);
    const reportTime = new Date(Date.now() - (minutesAgo * 60 * 1000));

    return {
      userId: userId,
      stationId: station.id,
      scope: 'station',
      operational: estados[Math.floor(Math.random() * estados.length)],
      crowdLevel: crowdLevels[Math.floor(Math.random() * crowdLevels.length)],
      trainLine: station.linea === 'L1' ? 'L1' : 'L2',
      direction: directions[Math.floor(Math.random() * directions.length)],
      createdAt: firebase.firestore.Timestamp.fromDate(reportTime),
      status: 'active',
      confirmationCount: Math.floor(Math.random() * 3),
      confirmedBy: [],
      source: 'load_test',
      testBatch: true
    };
  }

  // Generar datos aleatorios para reportes de tiempo de tren
  function generateTrainTimeReportData(userId, station) {
    const directions = station.linea === 'L1'
      ? ['Villa Zaita', 'Albrook']
      : ['Nuevo Tocumen', 'San Miguelito'];

    const nextTrainMinutes = Math.random() > 0.1 ? Math.floor(Math.random() * 12) + 1 : null;
    const followingTrainMinutes = Math.random() > 0.5 ? Math.floor(Math.random() * 12) + 1 : null;

    let nextTrainRange;
    if (nextTrainMinutes === null) {
      nextTrainRange = 'unknown';
    } else if (nextTrainMinutes <= 1) {
      nextTrainRange = '0-1';
    } else if (nextTrainMinutes <= 5) {
      nextTrainRange = String(nextTrainMinutes);
    } else {
      nextTrainRange = '5+';
    }

    return {
      userId: userId,
      stationId: station.id,
      line: station.linea === 'L1' ? 'linea1' : 'linea2',
      direction: directions[Math.floor(Math.random() * directions.length)],
      nextTrainMinutes: nextTrainMinutes,
      nextTrainRange: nextTrainRange,
      followingTrainMinutes: followingTrainMinutes,
      nextTrainUnknown: nextTrainMinutes === null,
      reportedAt: firebase.firestore.FieldValue.serverTimestamp(),
      source: 'load_test',
      confidenceWeight: 'medium',
      points: 5 + (followingTrainMinutes ? 3 : 0),
      testBatch: true
    };
  }

  // Crear un batch de reportes
  async function createReportBatch(reports, collectionName) {
    const batch = db.batch();
    const startTime = performance.now();

    reports.forEach(report => {
      const docRef = db.collection(collectionName).doc();
      batch.set(docRef, report);
      loadTestState.generatedIds.push({ id: docRef.id, collection: collectionName });
    });

    await batch.commit();

    const latency = performance.now() - startTime;
    loadTestState.metrics.latencies.push(latency);

    return reports.length;
  }

  // Generar reportes en paralelo con batches
  async function generateReportsBatched(config) {
    const {
      totalReports,
      batchSize = DEFAULT_CONFIG.batchSize,
      parallelBatches = DEFAULT_CONFIG.parallelBatches,
      includeStationReports = true,
      includeTrainTimeReports = true,
      stationDistribution = DEFAULT_CONFIG.stationDistribution
    } = config;

    if (!auth.currentUser) {
      await window.authenticateDashboard?.();
    }
    const userId = auth.currentUser?.uid;
    if (!userId) throw new Error('Usuario no autenticado');

    if (loadedStations.length === 0) {
      await loadStationsForLoadTest();
    }

    // Reset estado
    loadTestState = {
      isRunning: true,
      isPaused: false,
      totalReports: totalReports,
      completedReports: 0,
      failedReports: 0,
      startTime: performance.now(),
      generatedIds: [],
      metrics: { reportsPerSecond: 0, avgLatency: 0, latencies: [] }
    };

    updateProgress();

    // Generar todos los reportes
    const allReports = [];
    for (let i = 0; i < totalReports; i++) {
      const station = loadedStations[Math.floor(Math.random() * loadedStations.length)];
      const isStationReport = !includeTrainTimeReports ||
        (includeStationReports && Math.random() < stationDistribution);

      if (isStationReport && includeStationReports) {
        allReports.push({
          type: 'station',
          collection: 'simplified_reports',
          data: generateStationReportData(userId, station)
        });
      } else if (includeTrainTimeReports) {
        allReports.push({
          type: 'trainTime',
          collection: 'train_time_reports',
          data: generateTrainTimeReportData(userId, station)
        });
      }
    }

    // Dividir en batches
    const batches = [];
    for (let i = 0; i < allReports.length; i += batchSize) {
      batches.push(allReports.slice(i, i + batchSize));
    }

    console.log(`[LoadTest] Generando ${totalReports} reportes en ${batches.length} batches`);

    // Procesar batches en paralelo
    for (let i = 0; i < batches.length; i += parallelBatches) {
      if (!loadTestState.isRunning) break;

      while (loadTestState.isPaused) {
        await new Promise(r => setTimeout(r, 100));
      }

      const parallelGroup = batches.slice(i, i + parallelBatches);

      const promises = parallelGroup.map(async (batch) => {
        // Agrupar por coleccion
        const stationReports = batch.filter(r => r.collection === 'simplified_reports').map(r => r.data);
        const trainReports = batch.filter(r => r.collection === 'train_time_reports').map(r => r.data);

        let completed = 0;
        try {
          if (stationReports.length > 0) {
            completed += await createReportBatch(stationReports, 'simplified_reports');
          }
          if (trainReports.length > 0) {
            completed += await createReportBatch(trainReports, 'train_time_reports');
          }
          return completed;
        } catch (error) {
          console.error('[LoadTest] Error en batch:', error);
          loadTestState.failedReports += batch.length;
          return 0;
        }
      });

      const results = await Promise.all(promises);
      loadTestState.completedReports += results.reduce((a, b) => a + b, 0);
      updateProgress();

      // Pequeno delay entre grupos de batches
      if (i + parallelBatches < batches.length) {
        await new Promise(r => setTimeout(r, DEFAULT_CONFIG.delayBetweenBatches));
      }
    }

    // Calcular metricas finales
    const totalTime = (performance.now() - loadTestState.startTime) / 1000;
    loadTestState.metrics.reportsPerSecond = loadTestState.completedReports / totalTime;
    loadTestState.metrics.avgLatency = loadTestState.metrics.latencies.length > 0
      ? loadTestState.metrics.latencies.reduce((a, b) => a + b, 0) / loadTestState.metrics.latencies.length
      : 0;

    loadTestState.isRunning = false;
    updateProgress();
    renderResults();

    return loadTestState;
  }

  // Actualizar UI de progreso
  function updateProgress() {
    const progressBar = document.getElementById('loadTestProgress');
    const progressText = document.getElementById('loadTestProgressText');
    const metricsDiv = document.getElementById('loadTestMetrics');

    if (progressBar && loadTestState.totalReports > 0) {
      const percent = (loadTestState.completedReports / loadTestState.totalReports) * 100;
      progressBar.style.width = `${percent}%`;
      progressBar.setAttribute('aria-valuenow', percent);
    }

    if (progressText) {
      progressText.textContent = `${loadTestState.completedReports} / ${loadTestState.totalReports} reportes`;
    }

    if (metricsDiv && loadTestState.startTime) {
      const elapsed = (performance.now() - loadTestState.startTime) / 1000;
      const rps = loadTestState.completedReports / Math.max(elapsed, 0.1);

      metricsDiv.innerHTML = `
        <div class="metric-item">
          <span class="metric-label">Tiempo:</span>
          <span class="metric-value">${elapsed.toFixed(1)}s</span>
        </div>
        <div class="metric-item">
          <span class="metric-label">Velocidad:</span>
          <span class="metric-value">${rps.toFixed(1)} rep/s</span>
        </div>
        <div class="metric-item">
          <span class="metric-label">Fallidos:</span>
          <span class="metric-value ${loadTestState.failedReports > 0 ? 'error' : ''}">${loadTestState.failedReports}</span>
        </div>
      `;
    }
  }

  // Renderizar resultados finales
  function renderResults() {
    const resultsDiv = document.getElementById('loadTestResults');
    if (!resultsDiv) return;

    const totalTime = loadTestState.startTime
      ? (performance.now() - loadTestState.startTime) / 1000
      : 0;

    // Contar por tipo
    const stationCount = loadTestState.generatedIds.filter(r => r.collection === 'simplified_reports').length;
    const trainCount = loadTestState.generatedIds.filter(r => r.collection === 'train_time_reports').length;

    resultsDiv.innerHTML = `
      <div class="load-test-results-card">
        <h4>Resultados de Prueba de Carga</h4>

        <div class="results-grid">
          <div class="result-stat primary">
            <div class="stat-value">${loadTestState.completedReports.toLocaleString()}</div>
            <div class="stat-label">Reportes Generados</div>
          </div>

          <div class="result-stat success">
            <div class="stat-value">${loadTestState.metrics.reportsPerSecond.toFixed(1)}</div>
            <div class="stat-label">Reportes/Segundo</div>
          </div>

          <div class="result-stat info">
            <div class="stat-value">${totalTime.toFixed(2)}s</div>
            <div class="stat-label">Tiempo Total</div>
          </div>

          <div class="result-stat warning">
            <div class="stat-value">${loadTestState.metrics.avgLatency.toFixed(0)}ms</div>
            <div class="stat-label">Latencia Promedio (batch)</div>
          </div>
        </div>

        <div class="results-breakdown">
          <h5>Desglose por Tipo</h5>
          <div class="breakdown-row">
            <span>Reportes de Estacion:</span>
            <strong>${stationCount.toLocaleString()}</strong>
          </div>
          <div class="breakdown-row">
            <span>Reportes de Tiempo de Tren:</span>
            <strong>${trainCount.toLocaleString()}</strong>
          </div>
          <div class="breakdown-row error-row ${loadTestState.failedReports === 0 ? 'hidden' : ''}">
            <span>Reportes Fallidos:</span>
            <strong>${loadTestState.failedReports}</strong>
          </div>
        </div>

        <div class="results-actions">
          <button class="test-btn test-btn-warning" onclick="clearLoadTestReports()">
            <i class="fas fa-trash"></i> Limpiar Reportes de Prueba
          </button>
        </div>
      </div>
    `;

    resultsDiv.style.display = 'block';
  }

  // Iniciar prueba de carga
  async function startLoadTest() {
    const totalReports = parseInt(document.getElementById('loadTestTotal').value) || 100;
    const batchSize = parseInt(document.getElementById('loadTestBatchSize').value) || 400;
    const parallelBatches = parseInt(document.getElementById('loadTestParallel').value) || 3;
    const includeStation = document.getElementById('loadTestIncludeStation').checked;
    const includeTrain = document.getElementById('loadTestIncludeTrain').checked;

    if (!includeStation && !includeTrain) {
      showLoadTestStatus('Selecciona al menos un tipo de reporte', 'error');
      return;
    }

    if (totalReports > 10000) {
      const confirmed = window.confirm(
        `Vas a generar ${totalReports.toLocaleString()} reportes.\n\n` +
        'Esto puede tardar varios minutos y consumir recursos significativos.\n\n' +
        'Continuar?'
      );
      if (!confirmed) return;
    }

    // Deshabilitar botones
    toggleLoadTestButtons(true);
    showLoadTestStatus('Iniciando prueba de carga...', 'info');

    try {
      await generateReportsBatched({
        totalReports,
        batchSize,
        parallelBatches,
        includeStationReports: includeStation,
        includeTrainTimeReports: includeTrain
      });

      showLoadTestStatus(
        `Completado: ${loadTestState.completedReports.toLocaleString()} reportes en ${((performance.now() - loadTestState.startTime) / 1000).toFixed(1)}s`,
        'success'
      );

      // Actualizar otras vistas del dashboard
      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      console.error('[LoadTest] Error:', error);
      showLoadTestStatus(`Error: ${error.message}`, 'error');
    } finally {
      toggleLoadTestButtons(false);
    }
  }

  // Pausar/Reanudar prueba
  function togglePauseLoadTest() {
    loadTestState.isPaused = !loadTestState.isPaused;
    const btn = document.getElementById('loadTestPauseBtn');
    if (btn) {
      btn.innerHTML = loadTestState.isPaused
        ? '<i class="fas fa-play"></i> Reanudar'
        : '<i class="fas fa-pause"></i> Pausar';
    }
    showLoadTestStatus(loadTestState.isPaused ? 'Pausado' : 'Reanudando...', 'info');
  }

  // Detener prueba
  function stopLoadTest() {
    loadTestState.isRunning = false;
    showLoadTestStatus('Detenido por el usuario', 'warning');
    toggleLoadTestButtons(false);
  }

  // Limpiar reportes de prueba
  async function clearLoadTestReports() {
    if (loadTestState.generatedIds.length === 0) {
      showLoadTestStatus('No hay reportes de prueba para limpiar', 'warning');
      return;
    }

    const confirmed = window.confirm(
      `Eliminar ${loadTestState.generatedIds.length.toLocaleString()} reportes de prueba?\n\n` +
      'Esta accion no se puede deshacer.'
    );
    if (!confirmed) return;

    showLoadTestStatus('Eliminando reportes...', 'info');
    toggleLoadTestButtons(true);

    try {
      // Agrupar por coleccion
      const byCollection = {};
      loadTestState.generatedIds.forEach(item => {
        if (!byCollection[item.collection]) {
          byCollection[item.collection] = [];
        }
        byCollection[item.collection].push(item.id);
      });

      let deleted = 0;
      const batchSize = 400;

      for (const [collection, ids] of Object.entries(byCollection)) {
        for (let i = 0; i < ids.length; i += batchSize) {
          const batch = db.batch();
          const batchIds = ids.slice(i, i + batchSize);

          batchIds.forEach(id => {
            batch.delete(db.collection(collection).doc(id));
          });

          await batch.commit();
          deleted += batchIds.length;

          showLoadTestStatus(`Eliminando... ${deleted}/${loadTestState.generatedIds.length}`, 'info');
        }
      }

      loadTestState.generatedIds = [];
      document.getElementById('loadTestResults').style.display = 'none';

      showLoadTestStatus(`Eliminados ${deleted.toLocaleString()} reportes`, 'success');

      // Actualizar otras vistas
      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      console.error('[LoadTest] Error eliminando:', error);
      showLoadTestStatus(`Error: ${error.message}`, 'error');
    } finally {
      toggleLoadTestButtons(false);
    }
  }

  // Limpiar TODOS los reportes de prueba de la BD (por marca testBatch)
  async function clearAllTestReports() {
    const confirmed = window.confirm(
      'ADVERTENCIA: Esto eliminara TODOS los reportes marcados como testBatch de la base de datos.\n\n' +
      'Esto incluye reportes de sesiones anteriores.\n\n' +
      'Continuar?'
    );
    if (!confirmed) return;

    showLoadTestStatus('Buscando reportes de prueba...', 'info');
    toggleLoadTestButtons(true);

    try {
      let totalDeleted = 0;
      const collections = ['simplified_reports', 'train_time_reports'];
      const batchSize = 400;

      for (const collection of collections) {
        // Buscar reportes con testBatch=true
        let snapshot = await db.collection(collection)
          .where('testBatch', '==', true)
          .limit(batchSize)
          .get();

        while (!snapshot.empty) {
          const batch = db.batch();
          snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
          });
          await batch.commit();
          totalDeleted += snapshot.docs.length;

          showLoadTestStatus(`Eliminando de ${collection}... ${totalDeleted} eliminados`, 'info');

          // Obtener siguiente lote
          snapshot = await db.collection(collection)
            .where('testBatch', '==', true)
            .limit(batchSize)
            .get();
        }
      }

      loadTestState.generatedIds = [];
      document.getElementById('loadTestResults').style.display = 'none';

      showLoadTestStatus(`Eliminados ${totalDeleted.toLocaleString()} reportes de prueba de la BD`, 'success');

      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      console.error('[LoadTest] Error:', error);
      showLoadTestStatus(`Error: ${error.message}`, 'error');
    } finally {
      toggleLoadTestButtons(false);
    }
  }

  // Helpers de UI
  function showLoadTestStatus(message, type) {
    const statusDiv = document.getElementById('loadTestStatus');
    if (!statusDiv) return;

    const colors = {
      info: '#666',
      success: '#28a745',
      warning: '#ffc107',
      error: '#dc3545'
    };

    statusDiv.textContent = message;
    statusDiv.style.color = colors[type] || colors.info;
  }

  function toggleLoadTestButtons(disabled) {
    const buttons = ['loadTestStartBtn', 'loadTestPauseBtn', 'loadTestStopBtn'];
    buttons.forEach(id => {
      const btn = document.getElementById(id);
      if (btn) {
        if (id === 'loadTestStartBtn') {
          btn.disabled = disabled;
        } else {
          btn.disabled = !disabled && !loadTestState.isRunning;
        }
      }
    });
  }

  // Presets de configuracion
  function applyLoadTestPreset(preset) {
    const presets = {
      small: { total: 100, batch: 50, parallel: 2 },
      medium: { total: 500, batch: 200, parallel: 3 },
      large: { total: 2000, batch: 400, parallel: 4 },
      stress: { total: 5000, batch: 400, parallel: 5 }
    };

    const config = presets[preset];
    if (!config) return;

    document.getElementById('loadTestTotal').value = config.total;
    document.getElementById('loadTestBatchSize').value = config.batch;
    document.getElementById('loadTestParallel').value = config.parallel;

    showLoadTestStatus(`Preset "${preset}" aplicado: ${config.total} reportes`, 'info');
  }

  // Exponer funciones globales
  window.loadStationsForLoadTest = loadStationsForLoadTest;
  window.startLoadTest = startLoadTest;
  window.togglePauseLoadTest = togglePauseLoadTest;
  window.stopLoadTest = stopLoadTest;
  window.clearLoadTestReports = clearLoadTestReports;
  window.clearAllTestReports = clearAllTestReports;
  window.applyLoadTestPreset = applyLoadTestPreset;
})();
