(function () {
  function filterTable(tableType) {
    const filterInput = document.getElementById(`filter${tableType.charAt(0).toUpperCase() + tableType.slice(1)}`);
    if (!filterInput) return;
    const filterValue = filterInput.value.toLowerCase();
    let visibleCount = 0;
    let totalCount = 0;

    if (tableType === 'stations') {
      const allRows = document.querySelectorAll('#stationsContainer tr[data-station-name]');
      totalCount = allRows.length;

      allRows.forEach(row => {
        const name = row.getAttribute('data-station-name') || '';
        const line = row.getAttribute('data-station-line') || '';
        const state = row.getAttribute('data-station-state') || '';
        const text = row.textContent.toLowerCase();

        const matches =
          name.includes(filterValue) ||
          line.includes(filterValue) ||
          state.includes(filterValue) ||
          text.includes(filterValue);

        row.style.display = matches ? '' : 'none';
        if (matches) visibleCount++;
      });

      // Mostrar/ocultar grupos según si tienen filas visibles
      document.querySelectorAll('.line-group').forEach(group => {
        const visibleRows = group.querySelectorAll('tr[data-station-name]:not([style*="display: none"])');
        const header = group.querySelector('.line-header');
        if (visibleRows.length === 0 && filterValue) {
          group.style.display = 'none';
        } else {
          group.style.display = '';
          const countBadge = header?.querySelector('.line-count');
          if (countBadge) {
            const totalInGroup = group.querySelectorAll('tr[data-station-name]').length;
            countBadge.textContent = filterValue ? `${visibleRows.length}/${totalInGroup}` : `${totalInGroup}`;
          }
        }
      });

      document.getElementById('stationsCount').textContent = filterValue
        ? `${visibleCount} de ${totalCount} estaciones`
        : `${totalCount} estaciones`;
      return;
    }

    const tableBody = document.querySelector(`#${tableType} table tbody`);
    if (!tableBody) return;
    const rows = tableBody.querySelectorAll('tr');
    totalCount = rows.length;

    rows.forEach(row => {
      const text = row.textContent.toLowerCase();
      const matches = text.includes(filterValue);
      row.style.display = matches ? '' : 'none';
      if (matches) visibleCount++;
    });

    const countElement = document.getElementById(`${tableType}Count`);
    if (countElement) {
      countElement.textContent = filterValue ? `${visibleCount} de ${totalCount}` : `${totalCount}`;
    }
  }

  window.filterTable = filterTable;
})();


