(function () {
  const { db, auth } = window.Dashboard;

  async function loadCommunityStats() {
    try {
      console.log('Modo testing: Leyendo community_stats sin verificación de autenticación');
      const statsDoc = await db.collection('community_stats').doc('founder_week').get();

      if (statsDoc.exists) {
        const data = statsDoc.data();
        const progress = ((data.total_reports || 0) / 1000 * 100).toFixed(1);

        const html = `
          <div style="margin-bottom: 2rem;">
            <h3>Progreso Semana del Fundador</h3>
            <div style="background: #f0f0f0; border-radius: 8px; height: 30px; margin-top: 1rem; position: relative; overflow: hidden;">
              <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); height: 100%; width: ${progress}%; transition: width 0.3s;"></div>
              <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-weight: bold; color: #333;">
                ${progress}%
              </div>
            </div>
            <p style="margin-top: 0.5rem; color: #666;">
              ${data.total_reports || 0} / 1,000 reportes objetivo
            </p>
          </div>

          <div class="stats-grid" style="margin-top: 2rem;">
            <div class="stat-card">
              <h3>Total Reportes (7 días)</h3>
              <div class="value">${data.total_reports || 0}</div>
            </div>
            <div class="stat-card">
              <h3>Estaciones Activas</h3>
              <div class="value">${data.active_stations || 0}</div>
            </div>
            <div class="stat-card">
              <h3>Participantes</h3>
              <div class="value">${data.participants || 0}</div>
            </div>
            <div class="stat-card">
              <h3>Última Actualización</h3>
              <div class="value" style="font-size: 1rem;">
                ${data.last_updated ? new Date(data.last_updated.toMillis()).toLocaleString('es-PA') : 'N/A'}
              </div>
            </div>
          </div>
        `;

        const loadingElement = document.querySelector('#community .loading');
        if (loadingElement) loadingElement.outerHTML = html;
        else document.getElementById('community')?.insertAdjacentHTML('beforeend', html);
      } else {
        const loadingElement = document.querySelector('#community .loading');
        if (loadingElement) loadingElement.textContent = 'No hay estadísticas comunitarias aún';
      }
    } catch (error) {
      console.error('Error loading community stats:', error);
      const loadingElement = document.querySelector('#community .loading');

      let errorMsg = '';
      if (error.message.includes('permissions') || error.code === 'permission-denied') {
        errorMsg = '⚠️ Error de permisos para community_stats.\n\n';
        const currentAuth = auth.currentUser;
        if (!currentAuth) {
          errorMsg += 'No estás autenticado.\n';
          errorMsg += 'Solución:\n';
          errorMsg += '1. Haz clic en "Login" en el header\n';
          errorMsg += '2. O habilita "Anonymous" en Firebase Authentication';
        } else {
          errorMsg += 'Estás autenticado pero las reglas de Firestore no permiten la lectura.\n';
          errorMsg += 'Solución:\n';
          errorMsg += '1. Verifica que las reglas incluyan: allow read: if request.auth != null\n';
          errorMsg += '2. Despliega las reglas: firebase deploy --only firestore:rules';
        }
      } else if (error.message.includes('No autenticado') || error.message.includes('No se pudo autenticar')) {
        errorMsg = '⚠️ ' + error.message + '\n\n';
        errorMsg += 'Pasos para resolver:\n';
        errorMsg += '1. Firebase Console → Authentication → Sign-in method\n';
        errorMsg += '2. Habilita "Anonymous"\n';
        errorMsg += '3. O haz clic en "Login" en el header del dashboard';
      } else {
        errorMsg = 'Error al cargar estadísticas: ' + error.message;
      }

      if (loadingElement) loadingElement.innerHTML = errorMsg.replace(/\n/g, '<br>');
      else document.getElementById('community')?.insertAdjacentHTML('beforeend', `<div class="loading">${errorMsg.replace(/\n/g, '<br>')}</div>`);
    }
  }

  window.loadCommunityStats = loadCommunityStats;
})();


