(function () {
  // Arranque
  window.Dashboard.authModule.initAuthListener();

  // UI test tools (si existen)
  window.initTestReportProblemsUI?.();
  window.loadStationsForTestForm?.();
  window.setTestReportFormDefaults?.({ tipo: 'estacion' });

  // Autenticación automática (sin bloquear)
  window.authenticateDashboard?.().catch(() => {});

  // Inicializar generadores
  window.loadAvailableStations?.();
  window.loadTrainTimeStations?.();
})();


