(function () {
  const { db, auth, firebase } = window.Dashboard;

  // Variables para el testing
  let availableStations = [];
  let generatedStationReports = [];

  // Problemas específicos detallados (nuevo sistema)
  let specificIssues = [];
  
  // Tipos de problemas disponibles
  const availableIssueTypes = [
    { id: 'ac', name: 'Aire Acondicionado', icon: '❄️' },
    { id: 'escalator', name: 'Escalera Eléctrica', icon: '🎢' },
    { id: 'elevator', name: 'Elevador', icon: '🛗' },
    { id: 'atm', name: 'Cajero/ATM', icon: '🏧' },
    { id: 'recharge', name: 'Máquina de Recarga', icon: '💳' },
    { id: 'bathroom', name: 'Baño', icon: '🚻' },
    { id: 'lights', name: 'Iluminación', icon: '💡' }
  ];
  
  // Estados posibles
  const issueStatuses = [
    { id: 'not_working', name: '🔴 No Funciona' },
    { id: 'working_poorly', name: '🟡 Funciona Mal' },
    { id: 'out_of_service', name: '⚫ Fuera de Servicio' }
  ];

  // Cargar estaciones disponibles
  async function loadStationTestingStations() {
    console.log('🔄 Cargando estaciones para testing de reportes de estación...');
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
      renderStationTestingStations();
    } catch (error) {
      console.error('❌ Error cargando estaciones:', error);
      showStationTestingStatus('❌ Error cargando estaciones', 'error');
    }
  }

  // Renderizar selector de estaciones
  function renderStationTestingStations() {
    const select = document.getElementById('stationTestingStationSelect');
    if (!select) {
      console.error('❌ No se encontró el selector stationTestingStationSelect');
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

  // Agregar problema específico
  function addSpecificIssue() {
    const typeSelect = document.getElementById('issueTypeSelect');
    const locationInput = document.getElementById('issueLocationInput');
    const statusSelect = document.getElementById('issueStatusSelect');
    
    if (!typeSelect || !locationInput || !statusSelect) {
      console.error('❌ Elementos del formulario no encontrados');
      return;
    }
    
    const type = typeSelect.value;
    const location = locationInput.value.trim();
    const status = statusSelect.value;
    
    if (!type || !location || !status) {
      showStationTestingStatus('❌ Completa todos los campos del problema', 'error');
      return;
    }
    
    // Agregar problema a la lista
    specificIssues.push({ type, location, status });
    
    // Limpiar formulario
    locationInput.value = '';
    typeSelect.selectedIndex = 0;
    statusSelect.selectedIndex = 0;
    
    // Renderizar lista
    renderSpecificIssuesList();
    showStationTestingStatus(`✅ Problema agregado (${specificIssues.length} total)`, 'success');
  }
  
  // Eliminar problema específico
  function removeSpecificIssue(index) {
    specificIssues.splice(index, 1);
    renderSpecificIssuesList();
    showStationTestingStatus(`✅ Problema eliminado (${specificIssues.length} restantes)`, 'success');
  }
  
  // Renderizar lista de problemas específicos
  function renderSpecificIssuesList() {
    const container = document.getElementById('specificIssuesList');
    if (!container) return;
    
    if (specificIssues.length === 0) {
      container.innerHTML = '<p style="color: #999;">No hay problemas específicos agregados</p>';
      return;
    }
    
    const html = specificIssues.map((issue, index) => {
      const typeInfo = availableIssueTypes.find(t => t.id === issue.type);
      const statusInfo = issueStatuses.find(s => s.id === issue.status);
      
      return `
        <div class="issue-item" style="background: #f5f5f5; padding: 12px; border-radius: 8px; margin-bottom: 8px; display: flex; align-items: center; justify-content: space-between;">
          <div style="flex: 1;">
            <div style="font-weight: 600; margin-bottom: 4px;">
              ${typeInfo?.icon || '⚠️'} ${typeInfo?.name || issue.type}
            </div>
            <div style="font-size: 13px; color: #666; margin-bottom: 4px;">
              📍 ${issue.location}
            </div>
            <div style="font-size: 12px;">
              <span style="background: rgba(220, 53, 69, 0.1); color: #dc3545; padding: 2px 8px; border-radius: 4px;">
                ${statusInfo?.name || issue.status}
              </span>
            </div>
          </div>
          <button onclick="window.Dashboard.StationReportsTesting.removeSpecificIssue(${index})" 
                  style="background: #dc3545; color: white; border: none; padding: 8px 12px; border-radius: 6px; cursor: pointer;">
            🗑️ Eliminar
          </button>
        </div>
      `;
    }).join('');
    
    container.innerHTML = html;
  }
  
  // Limpiar todos los problemas
  function clearSpecificIssues() {
    specificIssues = [];
    renderSpecificIssuesList();
    showStationTestingStatus('✅ Problemas específicos limpiados', 'success');
  }

  // Vista previa de reportes de estación
  async function previewStationReports() {
    const stationId = document.getElementById('stationTestingStationSelect').value;
    const operational = document.getElementById('stationOperationalSelect').value;
    const crowdLevel = parseInt(document.getElementById('stationCrowdSelect').value);
    const reportCount = parseInt(document.getElementById('stationReportCount').value) || 5;
    const interval = parseInt(document.getElementById('stationInterval').value) || 30;
    const addVariation = document.getElementById('addStationVariation').checked;
    const issues = getSelectedIssues();

    if (!stationId || !operational) {
      showStationTestingStatus('❌ Selecciona estación y estado operacional', 'error');
      return;
    }

    if (!crowdLevel || crowdLevel < 1 || crowdLevel > 5) {
      showStationTestingStatus('❌ Selecciona nivel de aglomeración', 'error');
      return;
    }

    const statusDiv = document.getElementById('stationTestingStatus');
    statusDiv.textContent = '👁️ Generando vista previa...';
    statusDiv.style.color = '#666';

    try {
      const station = availableStations.find(s => s.id === stationId);
      const previewReports = [];
      const baseTime = new Date();

      for (let i = 0; i < reportCount; i++) {
        const reportTime = new Date(baseTime.getTime() + (i * interval * 1000));

        // Calcular variación si está activada
        let actualCrowd = crowdLevel;
        let actualOperational = operational;

        if (addVariation && reportCount > 1) {
          // Variar aglomeración ±1
          actualCrowd = Math.max(1, Math.min(5, crowdLevel + (Math.random() > 0.5 ? 1 : -1)));
          
          // Ocasionalmente cambiar estado operacional
          if (Math.random() > 0.7) {
            const states = ['yes', 'partial', 'no'];
            actualOperational = states[Math.floor(Math.random() * states.length)];
          }
        }

        previewReports.push({
          stationId: stationId,
          stationName: station.name,
          line: station.line,
          operational: actualOperational,
          crowdLevel: actualCrowd,
          issues: issues.length > 0 ? issues : [],
          reportedAt: reportTime,
          points: 15 + (issues.length * 5)
        });
      }

      renderStationPreview(previewReports);

      document.getElementById('stationTestingPreview').style.display = 'block';
      showStationTestingStatus(`✅ Vista previa generada: ${previewReports.length} reportes`, 'success');

    } catch (error) {
      showStationTestingStatus(`❌ Error en vista previa: ${error.message}`, 'error');
    }
  }

  // Renderizar vista previa
  function renderStationPreview(reports) {
    const operationalText = {
      'yes': '🟢 Operando Normal',
      'partial': '🟡 Parcialmente Operando',
      'no': '🔴 No Operando'
    };

    const html = `
      <div class="preview-reports-table">
        <table class="preview-table">
          <thead>
            <tr>
              <th>⏰ Reportado</th>
              <th>🏢 Estación</th>
              <th>🚦 Estado</th>
              <th>👥 Aglomeración</th>
              <th>⚠️ Problemas</th>
              <th>🏆 Puntos</th>
            </tr>
          </thead>
          <tbody>
            ${reports.map(report => `
              <tr>
                <td>${report.reportedAt.toLocaleTimeString('es-PA')}</td>
                <td>${report.stationName}</td>
                <td>${operationalText[report.operational]}</td>
                <td>${'⭐'.repeat(report.crowdLevel)}</td>
                <td>${report.issues.length > 0 ? report.issues.join(', ') : '-'}</td>
                <td>${report.points}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;

    document.getElementById('stationTestingPreviewContent').innerHTML = html;
  }

  // Generar reportes de estación
  async function generateStationReports() {
    const stationId = document.getElementById('stationTestingStationSelect').value;
    const operational = document.getElementById('stationOperationalSelect').value;
    const crowdLevel = parseInt(document.getElementById('stationCrowdSelect').value);
    const reportCount = parseInt(document.getElementById('stationReportCount').value) || 5;
    const interval = parseInt(document.getElementById('stationInterval').value) || 30;
    const addVariation = document.getElementById('addStationVariation').checked;

    if (!stationId || !operational || !crowdLevel) {
      showStationTestingStatus('❌ Configuración incompleta', 'error');
      return;
    }

    const totalReportsToCreate = reportCount * (1 + specificIssues.length); // General + específicos por cada iteración
    const confirm = window.confirm(
      `⚠️ ¿Generar ${reportCount} conjuntos de reportes?\n\n` +
      `Cada conjunto incluye:\n` +
      `- 1 reporte general de estación\n` +
      `- ${specificIssues.length} problema(s) específico(s)\n\n` +
      `Total: ${totalReportsToCreate} reportes que aparecerán en la app.`
    );

    if (!confirm) return;

    const statusDiv = document.getElementById('stationTestingStatus');
    statusDiv.textContent = '🚀 Generando reportes de estación...';
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
      generatedStationReports = [];
      let totalReports = 0;

      for (let i = 0; i < reportCount; i++) {
        const reportTime = new Date(Date.now() + (i * interval * 1000));

        // Calcular variación si está activada
        let actualCrowd = crowdLevel;
        let actualOperational = operational;

        if (addVariation && reportCount > 1) {
          // Variar aglomeración ±1
          actualCrowd = Math.max(1, Math.min(5, crowdLevel + (Math.random() > 0.5 ? 1 : -1)));
          
          // Ocasionalmente cambiar estado operacional
          if (Math.random() > 0.7) {
            const states = ['yes', 'partial', 'no'];
            actualOperational = states[Math.floor(Math.random() * states.length)];
          }
        }

        // 1. Crear reporte general de estación
        const generalReportData = {
          scope: 'station',
          stationId: stationId,
          userId: user.uid,
          stationOperational: actualOperational,
          stationCrowd: actualCrowd,
          isSpecificIssue: false, // Es el reporte general
          createdAt: firebase.firestore.Timestamp.fromDate(reportTime),
          basePoints: 15,
          bonusPoints: 0, // En el nuevo sistema, los puntos bonus vienen de problemas específicos
          totalPoints: 15 + (specificIssues.length * 10),
          status: 'active',
          confirmations: 0,
          confidence: 0.8,
          confidenceReasons: ['testing']
        };

        const generalDocRef = await db.collection('reports').add(generalReportData);
        await generalDocRef.update({'id': generalDocRef.id});
        
        const reportIds = [generalDocRef.id];

        generatedStationReports.push({
          id: generalDocRef.id,
          stationId: stationId,
          stationName: station.name,
          operational: actualOperational,
          crowdLevel: actualCrowd,
          specificIssues: specificIssues,
          reportedAt: reportTime,
          points: generalReportData.totalPoints
        });

        totalReports++;

        // 2. Crear reportes de problemas específicos
        for (const issue of specificIssues) {
          const issueReportData = {
            scope: 'station',
            stationId: stationId,
            userId: user.uid,
            issueType: issue.type,
            issueLocation: issue.location,
            issueStatus: issue.status,
            parentReportId: generalDocRef.id, // Enlazar al reporte general
            isSpecificIssue: true,
            createdAt: firebase.firestore.Timestamp.fromDate(reportTime),
            basePoints: 10,
            bonusPoints: 0,
            totalPoints: 10,
            status: 'active',
            confirmations: 0,
            confidence: 0.8,
            confidenceReasons: ['testing']
          };

          const issueDocRef = await db.collection('reports').add(issueReportData);
          await issueDocRef.update({'id': issueDocRef.id});
          reportIds.push(issueDocRef.id);
          
          totalReports++;
        }

        console.log(`✅ Conjunto ${i + 1}/${reportCount}: 1 general + ${specificIssues.length} específicos (IDs: ${reportIds.join(', ')})`);

        // Pequeño delay para evitar rate limits
        await new Promise(resolve => setTimeout(resolve, 300));
      }

      // Mostrar resultados
      renderStationResults(generatedStationReports);

      document.getElementById('stationTestingResults').style.display = 'block';
      showStationTestingStatus(`✅ Generados ${totalReports} reportes de estación`, 'success');

      // Actualizar vistas relacionadas
      setTimeout(() => {
        window.loadRecentReports?.();
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      console.error('Error generando reportes de estación:', error);
      showStationTestingStatus(`❌ Error: ${error.message}`, 'error');
    }
  }

  // Renderizar resultados
  function renderStationResults(reports) {
    const totalPoints = reports.reduce((sum, r) => sum + r.points, 0);
    const avgCrowd = reports.reduce((sum, r) => sum + r.crowdLevel, 0) / reports.length;
    const withSpecificIssues = reports.filter(r => r.specificIssues && r.specificIssues.length > 0).length;

    const operationalText = {
      'yes': '🟢 Normal',
      'partial': '🟡 Parcial',
      'no': '🔴 No Operando'
    };

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
          <h5>👥 Aglomeración Promedio</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${avgCrowd.toFixed(1)} / 5</div>
        </div>
        <div class="result-card">
          <h5>⚠️ Con Problemas</h5>
          <div style="font-size: 1.5rem; font-weight: bold; color: #667eea;">${withIssues}/${reports.length}</div>
        </div>
      </div>

      <div class="generated-reports-list">
        <h5>Reportes Generados:</h5>
        <div class="reports-list">
          ${reports.map(report => `
            <div class="report-item">
              <span>${report.reportedAt.toLocaleTimeString('es-PA')}</span>
              <span>${report.stationName}</span>
              <span>${operationalText[report.operational]}</span>
              <span>👥 ${'⭐'.repeat(report.crowdLevel)}</span>
              <span>${report.issues.length > 0 ? '⚠️ ' + report.issues.length + ' problemas' : '✅ Sin problemas'}</span>
              <span>🏆 ${report.points}pts</span>
            </div>
          `).join('')}
        </div>
      </div>
    `;

    document.getElementById('stationTestingResultsContent').innerHTML = html;
  }

  // Limpiar reportes de prueba
  async function clearStationReports() {
    if (generatedStationReports.length === 0) {
      showStationTestingStatus('❌ No hay reportes generados para limpiar', 'error');
      return;
    }

    const confirm = window.confirm(
      `⚠️ ¿Eliminar ${generatedStationReports.length} reportes de estación?\n\n` +
      'Esta acción no se puede deshacer.'
    );

    if (!confirm) return;

    const statusDiv = document.getElementById('stationTestingStatus');
    statusDiv.textContent = '🗑️ Eliminando reportes...';
    statusDiv.style.color = '#666';

    try {
      const batchSize = 10;
      let deleted = 0;

      for (let i = 0; i < generatedStationReports.length; i += batchSize) {
        const batch = db.batch();
        const batchReports = generatedStationReports.slice(i, i + batchSize);

        batchReports.forEach(report => {
          batch.delete(db.collection('reports').doc(report.id));
        });

        await batch.commit();
        deleted += batchReports.length;
      }

      generatedStationReports = [];

      // Ocultar resultados
      document.getElementById('stationTestingResults').style.display = 'none';
      document.getElementById('stationTestingPreview').style.display = 'none';

      showStationTestingStatus(`✅ Eliminados ${deleted} reportes de estación`, 'success');

      // Actualizar stats
      setTimeout(() => {
        window.loadStats?.();
      }, 1000);

    } catch (error) {
      showStationTestingStatus(`❌ Error eliminando reportes: ${error.message}`, 'error');
    }
  }

  // Función helper para mostrar status
  function showStationTestingStatus(message, type = 'info') {
    const statusDiv = document.getElementById('stationTestingStatus');
    if (!statusDiv) return;

    statusDiv.textContent = message;
    statusDiv.style.color = type === 'error' ? '#dc3545' : type === 'success' ? '#28a745' : '#666';
  }

  // Exponer funciones globales
  window.loadStationTestingStations = loadStationTestingStations;
  window.previewStationReports = previewStationReports;
  window.generateStationReports = generateStationReports;
  window.clearStationReports = clearStationReports;
  
  // Exponer funciones de problemas específicos
  if (!window.Dashboard) window.Dashboard = {};
  if (!window.Dashboard.StationReportsTesting) window.Dashboard.StationReportsTesting = {};
  
  window.Dashboard.StationReportsTesting = {
    addSpecificIssue,
    removeSpecificIssue,
    clearSpecificIssues,
    renderSpecificIssuesList
  };
  
  window.addSpecificIssue = addSpecificIssue;
  window.clearSpecificIssues = clearSpecificIssues;
})();

