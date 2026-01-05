(function () {
  const { db } = window.Dashboard;

  async function loadTimeAnalysis() {
    try {
      const snapshot = await db.collection('reports').get();

      let reportsWithTime = 0;
      let validatedReports = 0;
      let validReports = 0;
      let invalidReports = 0;
      let totalTimeReported = 0;
      const reportsByStation = {};

      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const tiempoEstimadoReportado = data.tiempo_estimado_reportado;
        const tiempoEstimadoValidado = data.tiempo_estimado_validado;
        const objetivoId = data.objetivo_id || data.stationId || 'unknown';

        if (tiempoEstimadoReportado !== null && tiempoEstimadoReportado !== undefined) {
          reportsWithTime++;
          totalTimeReported += tiempoEstimadoReportado;

          if (!reportsByStation[objetivoId]) {
            reportsByStation[objetivoId] = { total: 0, valid: 0, invalid: 0, validated: 0 };
          }
          reportsByStation[objetivoId].total++;

          if (tiempoEstimadoValidado !== null && tiempoEstimadoValidado !== undefined) {
            validatedReports++;
            reportsByStation[objetivoId].validated++;

            if (tiempoEstimadoValidado === true) {
              validReports++;
              reportsByStation[objetivoId].valid++;
            } else {
              invalidReports++;
              reportsByStation[objetivoId].invalid++;
            }
          }
        }
      });

      const avgTimeReported = reportsWithTime > 0 ? (totalTimeReported / reportsWithTime).toFixed(1) : 0;
      const validationRate = reportsWithTime > 0 ? ((validatedReports / reportsWithTime) * 100).toFixed(1) : 0;
      const accuracyRate = validatedReports > 0 ? ((validReports / validatedReports) * 100).toFixed(1) : 0;

      const topStations = Object.entries(reportsByStation)
        .sort((a, b) => b[1].total - a[1].total)
        .slice(0, 10);

      const html = `
        <div class="stats-grid" style="margin-bottom: 2rem;">
          <div class="stat-card">
            <h3>Reportes con Tiempo</h3>
            <div class="value">${reportsWithTime}</div>
            <div class="change">De ${snapshot.size} total</div>
          </div>
          <div class="stat-card">
            <h3>Tiempo Promedio</h3>
            <div class="value">${avgTimeReported}</div>
            <div class="change">Minutos reportados</div>
          </div>
          <div class="stat-card">
            <h3>Tasa de Validación</h3>
            <div class="value">${validationRate}%</div>
            <div class="change">${validatedReports} de ${reportsWithTime}</div>
          </div>
          <div class="stat-card">
            <h3>Precisión</h3>
            <div class="value">${accuracyRate}%</div>
            <div class="change">${validReports} válidos de ${validatedReports}</div>
          </div>
        </div>

        <div class="section">
          <h3>Desglose de Validación</h3>
          <p><strong>Válidos:</strong> ${validReports} | <strong>Inválidos:</strong> ${invalidReports} | <strong>Sin validar:</strong> ${reportsWithTime - validatedReports}</p>
        </div>

        ${topStations.length > 0 ? `
        <div class="section">
          <h3>Top Estaciones por Reportes de Tiempo</h3>
          <table>
            <thead>
              <tr>
                <th>Estación</th>
                <th>Total Reportes</th>
                <th>Validados</th>
                <th>Válidos</th>
                <th>Inválidos</th>
                <th>Tasa de Precisión</th>
              </tr>
            </thead>
            <tbody>
              ${topStations.map(([stationId, stats]) => {
                const precisionRate = stats.validated > 0 ? ((stats.valid / stats.validated) * 100).toFixed(1) : 'N/A';
                return `
                  <tr>
                    <td><strong>${stationId}</strong></td>
                    <td>${stats.total}</td>
                    <td>${stats.validated}</td>
                    <td style="color: #28a745;">${stats.valid}</td>
                    <td style="color: #dc3545;">${stats.invalid}</td>
                    <td>${precisionRate}%</td>
                  </tr>
                `;
              }).join('')}
            </tbody>
          </table>
        </div>
        ` : ''}
      `;

      const loadingElement = document.querySelector('#timeAnalysis .loading');
      if (loadingElement) loadingElement.outerHTML = html;
      else {
        const section = document.getElementById('timeAnalysis');
        if (section) {
          section.innerHTML = '<h2>⏱️ Análisis de Validación de Tiempo Estimado</h2>' + html;
        }
      }
    } catch (error) {
      console.error('Error loading time analysis:', error);
      const loadingElement = document.querySelector('#timeAnalysis .loading');
      const errorMsg = error.message.includes('permissions')
        ? '⚠️ Error de permisos. Verifica las reglas de Firestore.'
        : 'Error al cargar análisis: ' + error.message;
      if (loadingElement) loadingElement.textContent = errorMsg;
      else document.getElementById('timeAnalysis')?.insertAdjacentHTML('beforeend', `<div class="loading">${errorMsg}</div>`);
    }
  }

  window.loadTimeAnalysis = loadTimeAnalysis;
})();


