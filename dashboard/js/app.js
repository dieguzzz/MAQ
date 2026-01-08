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

  // Inicializar nuevas funcionalidades UI
  initializeDashboardUI();
})();

// Initialize new dashboard UI features
function initializeDashboardUI() {
  // Initialize theme
  initTheme();

  // Initialize sidebar
  initSidebar();

  // Initialize responsive features
  initResponsiveSidebar();

  // Initialize tooltips
  initTooltips();

  // Initialize enhanced search
  initSearch();

  // Setup theme toggle
  const themeToggle = document.getElementById('themeToggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', toggleTheme);
  }

  // Setup sidebar navigation
  document.querySelectorAll('.menu-item').forEach(item => {
    item.addEventListener('click', () => {
      const tabName = item.getAttribute('data-tab');
      showTab(tabName);
    });
  });

  // Setup testing cards navigation
  document.querySelectorAll('.testing-card').forEach(card => {
    card.addEventListener('click', () => {
      const tabName = card.getAttribute('onclick')?.match(/showTab\('([^']+)'\)/)?.[1];
      if (tabName) {
        showTab(tabName);
      }
    });
  });

  // Start with overview tab
  showTab('overview');

  // Show welcome message
  setTimeout(() => {
    showToast('Dashboard actualizado con nuevo diseño moderno', 'success', 3000);
  }, 1000);
}


