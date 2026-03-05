(function () {
  window.Dashboard = window.Dashboard || {};

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text ?? '';
    return div.innerHTML;
  }

  window.Dashboard.utils = { escapeHtml };
})();


