(function () {
  const { db } = window.Dashboard;

  async function loadTrains() {
    try {
      const snapshot = await db.collection('trains').get();

      const table = `
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Línea</th>
              <th>Dirección</th>
              <th>Velocidad</th>
              <th>Estado</th>
              <th>Confianza</th>
              <th>Última Actualización</th>
            </tr>
          </thead>
          <tbody>
            ${snapshot.docs.map(doc => {
              const data = doc.data();
              const confidence = data.confidence || 'low';
              const isEstimated = data.is_estimated || false;
              const trainId = doc.id.toLowerCase();
              const linea = (data.linea || 'N/A').toLowerCase();
              const direccion = (data.direccion || 'N/A').toLowerCase();
              const estado = (data.estado || 'normal').toLowerCase();
              return `
                <tr data-train-id="${trainId}"
                    data-train-line="${linea}"
                    data-train-direction="${direccion}"
                    data-train-state="${estado}">
                  <td><strong>${doc.id}</strong></td>
                  <td>${data.linea || 'N/A'}</td>
                  <td>${data.direccion || 'N/A'}</td>
                  <td>${data.velocidad || 0} km/h</td>
                  <td>${data.estado || 'normal'}</td>
                  <td>
                    <span class="badge ${confidence === 'high' ? 'badge-high' : confidence === 'medium' ? 'badge-medium' : isEstimated ? 'badge-estimated' : 'badge-low'}">
                      ${isEstimated ? '📊 Estimado' : confidence === 'high' ? '🟢 Alta' : confidence === 'medium' ? '🟡 Media' : '🔴 Baja'}
                    </span>
                  </td>
                  <td>${data.ultima_actualizacion ? new Date(data.ultima_actualizacion.toMillis()).toLocaleString('es-PA') : 'N/A'}</td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      `;

      const loadingElement = document.querySelector('#trains .loading');
      if (loadingElement) loadingElement.outerHTML = table;
      else {
        const section = document.getElementById('trains');
        if (section) {
          const existingTable = section.querySelector('table');
          if (existingTable) existingTable.outerHTML = table;
          else section.insertAdjacentHTML('beforeend', table);
        }
      }

      document.getElementById('trainsCount').textContent = `${snapshot.size} trenes`;
    } catch (error) {
      console.error('Error loading trains:', error);
      const loadingElement = document.querySelector('#trains .loading');
      const errorMsg = error.message.includes('permissions')
        ? '⚠️ Error de permisos. Verifica las reglas de Firestore o autenticación.'
        : 'Error al cargar trenes: ' + error.message;
      if (loadingElement) loadingElement.textContent = errorMsg;
      else document.getElementById('trains')?.insertAdjacentHTML('beforeend', `<div class="loading">${errorMsg}</div>`);
    }
  }

  window.loadTrains = loadTrains;
})();


