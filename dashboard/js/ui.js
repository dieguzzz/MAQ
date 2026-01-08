// Sistema de temas
function initTheme() {
  const theme = localStorage.getItem('dashboard-theme') || 'light';
  document.documentElement.setAttribute('data-theme', theme);
  updateThemeButton(theme);
}

function toggleTheme() {
  const currentTheme = document.documentElement.getAttribute('data-theme');
  const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

  document.documentElement.setAttribute('data-theme', newTheme);
  localStorage.setItem('dashboard-theme', newTheme);
  updateThemeButton(newTheme);

  showToast('Tema cambiado exitosamente', 'success');
}

function updateThemeButton(theme) {
  const themeBtn = document.getElementById('themeToggle');
  if (!themeBtn) return;

  const icon = themeBtn.querySelector('i');
  if (!icon) return;

  if (theme === 'dark') {
    icon.className = 'fas fa-sun';
  } else {
    icon.className = 'fas fa-moon';
  }
}

// Sidebar functionality
function initSidebar() {
  const sidebar = document.querySelector('.sidebar');
  const mainContent = document.querySelector('.main-content');
  const toggleBtn = document.getElementById('sidebarToggle');

  if (!sidebar || !mainContent || !toggleBtn) return;

  toggleBtn.addEventListener('click', () => {
    sidebar.classList.toggle('collapsed');
    mainContent.classList.toggle('sidebar-collapsed');
  });
}

// Navegación por tabs
function showTab(tabName) {
  // Ocultar todas las tabs
  document.querySelectorAll('.tab-content').forEach(tab => {
    tab.classList.remove('active');
  });

  // Mostrar tab seleccionada
  const targetTab = document.getElementById(tabName);
  if (targetTab) {
    targetTab.classList.add('active');
  }

  // Actualizar sidebar
  document.querySelectorAll('.menu-item').forEach(item => {
    item.classList.remove('active');
  });

  const activeMenuItem = document.querySelector(`[data-tab="${tabName}"]`);
  if (activeMenuItem) {
    activeMenuItem.classList.add('active');
  }

  // Actualizar título de página
  updatePageTitle(tabName);
}

// Navegación por sub-tabs de testing
function showTestingSubTab(subTabName) {
  // Ocultar contenido principal del tab testing
  const testingTab = document.getElementById('testing');
  if (testingTab) {
    testingTab.style.display = 'none';
  }

  // Mostrar sub-tab específico
  const subTab = document.getElementById(subTabName);
  if (subTab) {
    subTab.classList.add('active');
    subTab.style.display = 'block';

    // Agregar botón de volver
    addBackButton(subTab);
  }
}

function addBackButton(container) {
  // Remover botón anterior si existe
  const existingBackBtn = container.querySelector('.back-to-testing-btn');
  if (existingBackBtn) {
    existingBackBtn.remove();
  }

  // Crear botón de volver
  const backButton = document.createElement('button');
  backButton.className = 'back-to-testing-btn';
  backButton.innerHTML = '<i class="fas fa-arrow-left"></i> Volver al menú de Testing';
  backButton.style.cssText = `
    margin: 1rem 0;
    padding: 0.75rem 1.5rem;
    background: #007bff;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.9rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  `;

  backButton.onclick = () => {
    // Ocultar sub-tab
    container.classList.remove('active');
    container.style.display = 'none';

    // Mostrar tab principal de testing
    const testingTab = document.getElementById('testing');
    if (testingTab) {
      testingTab.style.display = 'block';
    }
  };

  // Insertar al inicio del contenedor
  const firstElement = container.firstElementChild;
  if (firstElement) {
    container.insertBefore(backButton, firstElement);
  } else {
    container.appendChild(backButton);
  }
}

function updatePageTitle(tabName) {
  const titles = {
    'overview': { title: 'Dashboard Overview', subtitle: 'Monitoreo en tiempo real de MetroPTY' },
    'stations': { title: 'Estaciones', subtitle: 'Monitoreo de estaciones del metro' },
    'trains': { title: 'Trenes Virtuales', subtitle: 'Estado de trenes en tiempo real' },
    'reports': { title: 'Reportes', subtitle: 'Gestión de reportes de usuarios' },
    'users': { title: 'Usuarios', subtitle: 'Gestión de usuarios y rankings' },
    'analytics': { title: 'Análisis', subtitle: 'Estadísticas y métricas detalladas' },
    'testing': { title: 'Testing', subtitle: 'Herramientas de desarrollo y testing' }
  };

  const pageTitle = document.getElementById('pageTitle');
  const pageSubtitle = document.getElementById('pageSubtitle');

  if (titles[tabName]) {
    if (pageTitle) pageTitle.textContent = titles[tabName].title;
    if (pageSubtitle) pageSubtitle.textContent = titles[tabName].subtitle;
  }
}

// Toast notifications
function showToast(message, type = 'info', duration = 5000) {
  const toastContainer = document.getElementById('toastContainer');
  if (!toastContainer) return;

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;

  const iconClass = {
    'success': 'fas fa-check-circle',
    'error': 'fas fa-exclamation-circle',
    'warning': 'fas fa-exclamation-triangle',
    'info': 'fas fa-info-circle'
  };

  toast.innerHTML = `
    <div class="toast-icon">
      <i class="${iconClass[type] || iconClass.info}"></i>
    </div>
    <div class="toast-content">
      <div class="toast-title">${type.charAt(0).toUpperCase() + type.slice(1)}</div>
      <div class="toast-message">${message}</div>
    </div>
    <button class="toast-close" onclick="this.parentElement.remove()">
      <i class="fas fa-times"></i>
    </button>
  `;

  toastContainer.appendChild(toast);

  // Auto-remover después de duración
  setTimeout(() => {
    if (toast.parentElement) {
      toast.remove();
    }
  }, duration);
}

// Responsive sidebar for mobile
function initResponsiveSidebar() {
  const sidebar = document.querySelector('.sidebar');
  const mainContent = document.querySelector('.main-content');
  const toggleBtn = document.getElementById('sidebarToggle');

  if (!sidebar || !mainContent || !toggleBtn) return;

  // Close sidebar when clicking outside on mobile
  mainContent.addEventListener('click', () => {
    if (window.innerWidth <= 1024 && sidebar.classList.contains('mobile-open')) {
      sidebar.classList.remove('mobile-open');
    }
  });

  // Handle window resize
  window.addEventListener('resize', () => {
    if (window.innerWidth > 1024) {
      sidebar.classList.remove('mobile-open');
    }
  });
}

// Initialize tooltips for collapsed sidebar
function initTooltips() {
  const menuItems = document.querySelectorAll('.menu-item');

  menuItems.forEach(item => {
    const tabName = item.getAttribute('data-tab');
    const tooltipText = getTabDisplayName(tabName);
    item.setAttribute('data-tooltip', tooltipText);
  });
}

function getTabDisplayName(tabName) {
  const names = {
    'overview': 'Overview',
    'stations': 'Estaciones',
    'trains': 'Trenes',
    'reports': 'Reportes',
    'users': 'Usuarios',
    'analytics': 'Análisis',
    'testing': 'Testing'
  };
  return names[tabName] || tabName;
}

// Enhanced search functionality
function initSearch() {
  const searchBoxes = document.querySelectorAll('.search-box input');

  searchBoxes.forEach(searchBox => {
    searchBox.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase();
      const tabName = getCurrentTab();

      // Call existing filter functions based on current tab
      switch(tabName) {
        case 'stations':
          filterTable('stations');
          break;
        case 'trains':
          filterTable('trains');
          break;
        case 'reports':
          filterReportsAdvanced();
          break;
        case 'users':
          filterTable('users');
          break;
      }
    });
  });
}

function getCurrentTab() {
  const activeTab = document.querySelector('.tab-content.active');
  return activeTab ? activeTab.id : 'overview';
}

// Initialize all UI components
document.addEventListener('DOMContentLoaded', function() {
  initTheme();
  initSidebar();
  initResponsiveSidebar();
  initTooltips();
  initSearch();

  // Event listeners
  const themeToggle = document.getElementById('themeToggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', toggleTheme);
  }

  // Navegación por sidebar
  document.querySelectorAll('.menu-item').forEach(item => {
    item.addEventListener('click', () => {
      const tabName = item.getAttribute('data-tab');
      showTab(tabName);
    });
  });

  // Mostrar overview por defecto
  showTab('overview');

  // Add loading animations
  initLoadingAnimations();
});

// Loading animations
function initLoadingAnimations() {
  const loadingElements = document.querySelectorAll('.data-loading, .analytics-loading');

  loadingElements.forEach(element => {
    const spinner = element.querySelector('i');
    if (spinner) {
      spinner.style.animation = 'spin 1s linear infinite';
    }
  });
}

// Utility functions for animations
function animateElement(element, animation, duration = 300) {
  if (!element) return;

  element.style.animation = `${animation} ${duration}ms ease-out`;

  setTimeout(() => {
    element.style.animation = '';
  }, duration);
}

// Enhanced filter functionality
function updateFilterCount(tabName, count) {
  const countElement = document.getElementById(`${tabName}Count`);
  if (countElement) {
    countElement.textContent = count;
  }
}

// Export functions for global use
window.showToast = showToast;
window.showTab = showTab;
window.showTestingSubTab = showTestingSubTab;
window.toggleTheme = toggleTheme;