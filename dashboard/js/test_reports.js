(function () {
  const { db, auth, firebase } = window.Dashboard;

  const TEST_REPORT_PROBLEMS = [
    { id: 'aireAcondicionado', label: '❄️ Aire Acondicionado' },
    { id: 'puertas', label: '🚪 Puertas' },
    { id: 'limpieza', label: '🧹 Limpieza' },
    { id: 'mantenimiento', label: '🔧 Mantenimiento' },
    { id: 'sonido', label: '🔊 Sonido' },
    { id: 'luces', label: '💡 Luces' },
  ];

  function initTestReportProblemsUI() {
    const container = document.getElementById('testReportProblemas');
    if (!container) return;
    container.innerHTML = TEST_REPORT_PROBLEMS.map(p => `
      <label style="display:flex; align-items:center; gap:0.4rem; background:#fff; border:1px solid #ddd; border-radius: 999px; padding:0.35rem 0.6rem;">
        <input type="checkbox" value="${p.id}">
        <span style="font-size:0.85rem;">${p.label}</span>
      </label>
    `).join('');
  }

  function getSelectedTestProblems() {
    const container = document.getElementById('testReportProblemas');
    if (!container) return [];
    return Array.from(container.querySelectorAll('input[type="checkbox"]:checked')).map(i => i.value);
  }

  function getEstadoPrincipalOptions(tipo) {
    if (tipo === 'tren') {
      return [
        { value: 'asientosDisponibles', label: '🟢 Asientos disponibles' },
        { value: 'dePieComodo', label: '🟡 De pie cómodo' },
        { value: 'sardina', label: '🔴 Sardina' },
        { value: 'express', label: '⚡ Express' },
        { value: 'lento', label: '🐌 Lento' },
        { value: 'detenido', label: '🛑 Detenido' },
      ];
    }
    return [
      { value: 'normal', label: '🟢 Normal' },
      { value: 'moderado', label: '🟡 Moderado' },
      { value: 'lleno', label: '🔴 Lleno' },
      { value: 'retraso', label: '⚠️ Retraso' },
      { value: 'cerrado', label: '🚫 Cerrado' },
    ];
  }

  function onTestReportTipoChanged() {
    const tipo = document.getElementById('testReportTipo')?.value || 'estacion';
    const estadoEl = document.getElementById('testReportEstadoPrincipal');
    if (!estadoEl) return;
    const options = getEstadoPrincipalOptions(tipo);
    estadoEl.innerHTML = options.map(o => `<option value="${o.value}">${o.label}</option>`).join('');
  }

  function setTestReportFormDefaults({ tipo } = {}) {
    const tipoEl = document.getElementById('testReportTipo');
    if (tipoEl && tipo) tipoEl.value = tipo;

    const catEl = document.getElementById('testReportCategoria');
    const confEl = document.getElementById('testReportConfidence');
    const verEl = document.getElementById('testReportVerificationStatus');
    const priEl = document.getElementById('testReportPrioridad');
    const confCountEl = document.getElementById('testReportConfirmations');
    const statusEl = document.getElementById('testReportStatus');
    const tiempoEl = document.getElementById('testReportTiempoEstimado');
    const tiempoValEl = document.getElementById('testReportTiempoValidado');
    const descEl = document.getElementById('testReportDescripcion');

    if (tipo === 'tren') {
      if (catEl) catEl.value = 'servicio_normal';
      if (confEl) confEl.value = '0.6';
      if (tiempoEl) tiempoEl.value = '5';
    } else if (tipo === 'estacion') {
      if (catEl) catEl.value = 'aglomeracion';
      if (confEl) confEl.value = '0.5';
      if (tiempoEl) tiempoEl.value = '';
    }

    if (verEl) verEl.value = 'pending';
    if (priEl) priEl.checked = false;
    if (confCountEl) confCountEl.value = '0';
    if (statusEl) statusEl.value = 'active';
    if (tiempoValEl) tiempoValEl.value = '';
    if (descEl && !descEl.value) descEl.value = 'Reporte de prueba generado desde el dashboard';

    onTestReportTipoChanged();
  }

  async function loadStationsForTestForm() {
    const select = document.getElementById('testReportObjetivo');
    if (!select) return;
    try {
      const snapshot = await db.collection('stations')
        .orderBy('nombre')
        .limit(200)
        .get();
      if (snapshot.empty) {
        select.innerHTML = '<option value="">No hay estaciones</option>';
        return;
      }
      select.innerHTML = snapshot.docs.map(doc => {
        const data = doc.data();
        const nombre = data.nombre || doc.id;
        const linea = data.linea ? ` (${data.linea})` : '';
        return `<option value="${doc.id}">${nombre}${linea}</option>`;
      }).join('');
    } catch (e) {
      console.error('Error cargando estaciones para formulario:', e);
      select.innerHTML = '<option value="">Error cargando estaciones</option>';
    }
  }

  async function createTestReportFromForm() {
    const statusDiv = document.getElementById('testToolsStatus');
    const btn = document.getElementById('createCustomReportBtn');

    try {
      if (btn) btn.disabled = true;
      if (statusDiv) statusDiv.textContent = '➕ Creando reporte configurable...';

      if (!auth.currentUser) {
        await window.authenticateDashboard?.();
      }
      const user = auth.currentUser;
      if (!user) {
        throw new Error('No se pudo autenticar. Habilita Anonymous en Firebase Authentication.');
      }

      const tipo = document.getElementById('testReportTipo')?.value || 'estacion';
      const objetivoId = document.getElementById('testReportObjetivo')?.value || '';
      if (!objetivoId) throw new Error('Selecciona una estación/objetivo.');

      const categoria = document.getElementById('testReportCategoria')?.value || 'aglomeracion';
      const estadoPrincipal = document.getElementById('testReportEstadoPrincipal')?.value || (tipo === 'tren' ? 'asientosDisponibles' : 'normal');
      const prioridad = document.getElementById('testReportPrioridad')?.checked === true;
      const verificationStatus = document.getElementById('testReportVerificationStatus')?.value || 'pending';
      const confidenceRaw = parseFloat(document.getElementById('testReportConfidence')?.value || '0.5');
      const confidence = Number.isFinite(confidenceRaw) ? Math.max(0, Math.min(1, confidenceRaw)) : 0.5;
      const confirmations = parseInt(document.getElementById('testReportConfirmations')?.value || '0', 10) || 0;
      const status = document.getElementById('testReportStatus')?.value || 'active';
      const descripcion = (document.getElementById('testReportDescripcion')?.value || '').trim();
      const problemas = getSelectedTestProblems();

      const tiempoEstimadoRaw = document.getElementById('testReportTiempoEstimado')?.value;
      const tiempoEstimado = tiempoEstimadoRaw ? parseInt(tiempoEstimadoRaw, 10) : null;

      const tiempoValidadoRaw = document.getElementById('testReportTiempoValidado')?.value;
      const tiempoValidado = tiempoValidadoRaw === '' ? null : (tiempoValidadoRaw === 'true');

      const stationDoc = await db.collection('stations').doc(objetivoId).get();
      const stationData = stationDoc.exists ? stationDoc.data() : null;
      const ubicacion = stationData?.ubicacion || new firebase.firestore.GeoPoint(8.9824, -79.5199);

      const report = {
        // Campos esperados por rules actuales (modelo simplificado)
        userId: user.uid,
        scope: tipo === 'tren' ? 'train' : 'station',
        stationId: objetivoId,
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
        status: status,
        confirmations: confirmations,
        confidence: confidence,
        verification_status: verificationStatus,
        confirmation_count: confirmations,

        // Campos del modelo nuevo (para análisis)
        usuario_id: user.uid,
        tipo: tipo,
        objetivo_id: objetivoId,
        categoria: categoria,
        estado_principal: estadoPrincipal,
        problemas_especificos: problemas,
        prioridad: prioridad,
        descripcion: descripcion || null,
        ubicacion: ubicacion,
        verificaciones: 0,
        estado: status === 'resolved' ? 'resuelto' : (status === 'deleted' ? 'falso' : 'activo'),
        creado_en: firebase.firestore.FieldValue.serverTimestamp(),
        tiempo_estimado_reportado: tiempoEstimado,
        tiempo_estimado_validado: tiempoValidado,
      };

      await db.collection('reports').add(report);

      if (statusDiv) {
        statusDiv.innerHTML = `✅ <strong>Reporte creado</strong> (${tipo} / ${objetivoId})`;
        statusDiv.style.color = '#28a745';
      }

      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
      }, 800);
    } catch (error) {
      console.error('Error creating configurable test report:', error);
      if (statusDiv) {
        statusDiv.innerHTML = `❌ Error: ${error.message || error}`;
        statusDiv.style.color = '#dc3545';
      }
    } finally {
      if (btn) btn.disabled = false;
    }
  }

  async function createTestStationReport() {
    const statusDiv = document.getElementById('testToolsStatus');
    const btn = document.getElementById('createStationBtn');
    try {
      if (btn) btn.disabled = true;
      if (statusDiv) statusDiv.textContent = '➕ Creando reporte de prueba (con configuración)...';
      setTestReportFormDefaults({ tipo: 'estacion' });
      await createTestReportFromForm();
    } catch (error) {
      console.error('Error creating test report:', error);
      if (statusDiv) {
        statusDiv.innerHTML = `❌ Error: ${error.message}`;
        statusDiv.style.color = '#dc3545';
      }
    } finally {
      if (btn) btn.disabled = false;
    }
  }

  async function createTestTrainReport() {
    const statusDiv = document.getElementById('testToolsStatus');
    const btn = document.getElementById('createTrainBtn');
    try {
      if (btn) btn.disabled = true;
      if (statusDiv) statusDiv.textContent = '➕ Creando reporte de tren (con configuración)...';
      setTestReportFormDefaults({ tipo: 'tren' });
      await createTestReportFromForm();
    } catch (error) {
      console.error('Error creating test report:', error);
      if (statusDiv) {
        statusDiv.innerHTML = `❌ Error: ${error.message}`;
        statusDiv.style.color = '#dc3545';
      }
    } finally {
      if (btn) btn.disabled = false;
    }
  }

  // Exponer para HTML
  window.initTestReportProblemsUI = initTestReportProblemsUI;
  window.getSelectedTestProblems = getSelectedTestProblems;
  window.setTestReportFormDefaults = setTestReportFormDefaults;
  window.onTestReportTipoChanged = onTestReportTipoChanged;
  window.loadStationsForTestForm = loadStationsForTestForm;
  window.createTestReportFromForm = createTestReportFromForm;
  window.createTestStationReport = createTestStationReport;
  window.createTestTrainReport = createTestTrainReport;
})();


