(function () {
  const { db } = window.Dashboard;
  const state = window.Dashboard.state;
  const { escapeHtml } = window.Dashboard.utils;

  function renderLogs() {
    const container = document.getElementById('logsContainer');
    if (!container) return;

    const categoryFilter = document.getElementById('logCategoryFilter')?.value || '';
    const levelFilter = document.getElementById('logLevelFilter')?.value || '';

    let filteredLogs = state.allLogs;
    if (categoryFilter) filteredLogs = filteredLogs.filter(log => log.category === categoryFilter);
    if (levelFilter) filteredLogs = filteredLogs.filter(log => log.level === levelFilter);

    const countElement = document.getElementById('logsCount');
    if (countElement) countElement.textContent = `${filteredLogs.length} de ${state.allLogs.length} logs`;

    if (filteredLogs.length === 0) {
      container.innerHTML = '<div style="color: #808080; padding: 1rem; text-align: center;">No hay logs para mostrar</div>';
      return;
    }

    const logsHtml = filteredLogs.map(log => {
      const timestamp = log.timestamp
        ? new Date(log.timestamp.toDate ? log.timestamp.toDate() : log.timestamp).toLocaleTimeString('es-PA')
        : 'N/A';
      const levelColor = log.level === 'error' ? '#cd3131'
        : log.level === 'warning' ? '#d7ba7d'
        : log.level === 'success' ? '#6a9955'
        : '#569cd6';

      return `
        <div class="log-entry" style="margin-bottom: 0.5rem; padding: 0.5rem; border-left: 3px solid ${levelColor}; background: rgba(255,255,255,0.02);">
          <span style="color: #808080; margin-right: 0.5rem;">${timestamp}</span>
          <span style="color: ${levelColor}; font-weight: bold; margin-right: 0.5rem;">[${log.category}]</span>
          <span style="color: ${levelColor};">${escapeHtml(log.message)}</span>
        </div>
      `;
    }).join('');

    container.innerHTML = logsHtml;

    const debugTab = document.getElementById('debugLogs');
    if (debugTab && debugTab.classList.contains('active')) {
      container.scrollTop = 0;
    }
  }

  function loadDebugLogs() {
    try {
      if (state.logsUnsubscribe) {
        state.logsUnsubscribe();
      }

      db.collection('debug_logs')
        .orderBy('timestamp', 'desc')
        .limit(500)
        .get()
        .then((snapshot) => {
          state.allLogs = snapshot.docs.map(doc => ({
            id: doc.id,
            timestamp: doc.data().timestamp,
            category: doc.data().category || 'Unknown',
            message: doc.data().message || '',
            level: doc.data().level || 'info',
          }));
          renderLogs();

          state.logsUnsubscribe = db.collection('debug_logs')
            .orderBy('timestamp', 'desc')
            .limit(500)
            .onSnapshot((snap) => {
              snap.docChanges().forEach((change) => {
                if (change.type !== 'added') return;
                const logData = change.doc.data();
                const newLog = {
                  id: change.doc.id,
                  timestamp: logData.timestamp,
                  category: logData.category || 'Unknown',
                  message: logData.message || '',
                  level: logData.level || 'info',
                };

                if (!state.allLogs.find(l => l.id === newLog.id)) {
                  state.allLogs.unshift(newLog);
                  if (state.allLogs.length > 500) state.allLogs = state.allLogs.slice(0, 500);
                  renderLogs();
                }
              });
            }, (error) => {
              console.error('Error en listener de logs:', error);
            });
        })
        .catch((error) => {
          console.error('Error cargando logs:', error);
          const container = document.getElementById('logsContainer');
          if (container) {
            container.innerHTML = `
              <div style="color: #cd3131; padding: 1rem;">
                ❌ Error cargando logs: ${error.message}<br>
                ${error.message.includes('permissions') ? 'Verifica las reglas de Firestore para debug_logs' : ''}
              </div>
            `;
          }
        });
    } catch (error) {
      console.error('Error inicializando logs:', error);
    }
  }

  function filterLogs() {
    renderLogs();
  }

  function clearLogsDisplay() {
    state.allLogs = [];
    renderLogs();
  }

  window.loadDebugLogs = loadDebugLogs;
  window.filterLogs = filterLogs;
  window.clearLogsDisplay = clearLogsDisplay;
})();


