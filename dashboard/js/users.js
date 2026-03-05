(function () {
  const { db } = window.Dashboard;

  async function loadTopUsers() {
    try {
      const snapshot = await db.collection('users')
        .orderBy('gamification.puntos', 'desc')
        .limit(20)
        .get();

      const table = `
        <table>
          <thead>
            <tr>
              <th>Usuario</th>
              <th>Puntos</th>
              <th>Nivel</th>
              <th>Reportes</th>
              <th>Verificaciones</th>
              <th>Racha</th>
            </tr>
          </thead>
          <tbody>
            ${snapshot.docs.map(doc => {
              const data = doc.data();
              const gamification = data.gamification || {};
              const nombre = (data.nombre || '').toLowerCase();
              const email = (data.email || '').toLowerCase();
              return `
                <tr data-user-name="${nombre}" data-user-email="${email}">
                  <td><strong>${data.nombre || data.email || doc.id.substring(0, 8)}</strong></td>
                  <td>${gamification.puntos || 0}</td>
                  <td>${gamification.nivel || 1}</td>
                  <td>${data.reportes_count || 0}</td>
                  <td>${gamification.verificaciones_hechas || 0}</td>
                  <td>${gamification.streak || 0} días</td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      `;

      const loadingElement = document.querySelector('#users .loading');
      if (loadingElement) loadingElement.outerHTML = table;
      else {
        const section = document.getElementById('users');
        if (section) {
          const existingTable = section.querySelector('table');
          if (existingTable) existingTable.outerHTML = table;
          else section.insertAdjacentHTML('beforeend', table);
        }
      }

      document.getElementById('usersCount').textContent = `${snapshot.size} usuarios`;
    } catch (error) {
      console.error('Error loading users:', error);
      const loadingElement = document.querySelector('#users .loading');
      const errorMsg = error.message.includes('permissions')
        ? '⚠️ Error de permisos. Verifica las reglas de Firestore. Los usuarios requieren autenticación.'
        : 'Error al cargar usuarios: ' + error.message;
      if (loadingElement) loadingElement.textContent = errorMsg;
      else document.getElementById('users')?.insertAdjacentHTML('beforeend', `<div class="loading">${errorMsg}</div>`);
    }
  }

  window.loadTopUsers = loadTopUsers;
})();


