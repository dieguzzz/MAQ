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

    // Inicializar gráficos del overview
    window.initOverviewCharts?.();

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

  // Setup theme toggle (duplicado con ui.js, removido para evitar conflictos)
  // const themeToggle = document.getElementById('themeToggle');
  // if (themeToggle) {
  //   themeToggle.addEventListener('click', toggleTheme);
  // }

  // Setup sidebar navigation (movido a ui.js para evitar duplicados)
  // document.querySelectorAll('.menu-item').forEach(item => {
  //   item.addEventListener('click', () => {
  //     const tabName = item.getAttribute('data-tab');
  //     showTab(tabName);
  //   });
  // });

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

// Función global para refrescar todos los datos
window.refreshAll = async function() {
  try {
    console.log('🔄 Refrescando datos del dashboard...');

    // Cargar estadísticas principales (siempre)
    if (window.loadStats) {
      await window.loadStats();
    }

    // Cargar datos específicos según la pestaña activa
    const activeTab = document.querySelector('.tab-content.active');

    if (activeTab) {
      switch (activeTab.id) {
        case 'overview':
          // Las estadísticas ya se cargaron arriba
          break;

        case 'stations':
          if (window.loadStations) {
            await window.loadStations(false); // false = sin mostrar loading
          }
          break;

        case 'trains':
          if (window.loadTrains) {
            await window.loadTrains();
          }
          break;

        case 'reports':
          if (window.loadRecentReports) {
            await window.loadRecentReports();
          }
          break;

        case 'users':
          if (window.loadTopUsers) {
            await window.loadTopUsers();
          }
          break;

        case 'analytics':
          if (window.loadTimeAnalysis) {
            await window.loadTimeAnalysis();
          }
          if (window.loadCommunityStats) {
            await window.loadCommunityStats();
          }
          break;

        case 'testing':
          // No hay datos específicos para cargar en testing
          break;

        case 'debugLogs':
          if (window.loadDebugLogs) {
            await window.loadDebugLogs();
          }
          break;
      }
    }

    console.log('✅ Datos refrescados exitosamente');
    showToast('Datos actualizados', 'success', 2000);

  } catch (error) {
    console.error('❌ Error al refrescar datos:', error);
    showToast('Error al actualizar datos', 'error', 3000);
  }
};

// Inicializar carga de datos al cargar la página
document.addEventListener('DOMContentLoaded', async () => {
  // Pequeño delay para asegurar que Firebase esté listo
  setTimeout(async () => {
    await window.refreshAll();
  }, 2000);
});
}


