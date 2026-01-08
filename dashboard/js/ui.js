(function () {
  const state = window.Dashboard.state;

  function updateAuthUI() {
    const authInfo = document.getElementById('authInfo');
    if (!authInfo) return;

    const currentUser = state.currentUser;
    if (currentUser) {
      const label = currentUser.isAnonymous
        ? `🧪 MODO TESTING - Auth anónimo (${currentUser.uid.substring(0, 8)}...)`
        : `Autenticado: ${currentUser.email || (currentUser.uid.substring(0, 8) + '...')}`;

      authInfo.innerHTML = `
        <span style="color: #4caf50;">${label}</span>
        <span style="margin-left: 10px; color: #ddd; font-size: 12px;">(Sin login admin requerido)</span>
      `;
      return;
    }

    authInfo.innerHTML = `
      <span style="color: #ff9800;">⚠ No autenticado</span>
      <button onclick="authenticateDashboard()" style="margin-left: 10px; padding: 5px 10px; background: #2196F3; color: white; border: none; border-radius: 4px; cursor: pointer;">Autenticar</button>
    `;
  }

  function showTab(tabName) {
    document.querySelectorAll('.tab').forEach((tab) => tab.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach((content) => content.classList.remove('active'));

    // eslint-disable-next-line no-undef
    event.target.classList.add('active');
    document.getElementById(tabName).classList.add('active');

    if (tabName === 'stations') {
      // Inicializar listeners cuando se abre la pestaña de estaciones
      window.initStationsRealtimeListeners?.();
    } else if (tabName === 'debugLogs') {
      window.loadDebugLogs?.();
    } else if (tabName === 'timeAnalysis') {
      window.loadTimeAnalysis?.();
    } else if (tabName === 'trainTimeReportsTesting') {
      // Cargar estaciones para el testing de tiempos de tren
      window.loadTrainTimeStations?.();
    } else if (tabName === 'stationReportsTesting') {
      // Cargar estaciones para el testing de reportes de estación
      window.loadStationTestingStations?.();
    } else if (tabName === 'multiReportsTesting') {
      // Cargar estaciones para testing múltiple
      window.loadMultiStations?.();
    } else {
      // Limpiar listeners cuando se sale de stations
      if (window.cleanupStationsListeners) {
        window.cleanupStationsListeners();
      }

      if (state.logsUnsubscribe) {
        state.logsUnsubscribe();
        state.logsUnsubscribe = null;
      }
    }
  }

  function refreshAll() {
    window.loadStats?.();
    window.loadStations?.();
    window.loadTrains?.();
    window.loadRecentReports?.();
    window.loadTopUsers?.();
    window.loadCommunityStats?.();

    const timeTab = document.getElementById('timeAnalysis');
    if (timeTab && timeTab.classList.contains('active')) {
      window.loadTimeAnalysis?.();
    }

    const debugTab = document.getElementById('debugLogs');
    if (debugTab && debugTab.classList.contains('active')) {
      window.loadDebugLogs?.();
    }
  }

  function closeReportModal() {
    document.getElementById('reportModal')?.classList.remove('active');
  }

  window.updateAuthUI = updateAuthUI;
  window.showTab = showTab;
  window.refreshAll = refreshAll;
  window.closeReportModal = closeReportModal;
})();


