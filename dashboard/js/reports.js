(function () {
  const { db } = window.Dashboard;
  const { firebase } = window.Dashboard;

  function _getMillisFromPossibleTimestamp(value) {
    if (!value) return null;
    if (typeof value === 'number') return value;
    if (value.toMillis && typeof value.toMillis === 'function') return value.toMillis();
    if (value.toDate && typeof value.toDate === 'function') return value.toDate().getTime();
    if (value instanceof Date) return value.getTime();
    return null;
  }

  function filterReportsAdvanced() {
    const filterText = document.getElementById('filterReports').value.toLowerCase();
    const filterCategory = document.getElementById('filterCategory').value;
    const filterEstadoPrincipal = document.getElementById('filterEstadoPrincipal').value;
    const filterVerification = document.getElementById('filterVerification').value;
    const filterPriority = document.getElementById('filterPriority').checked;

    const rows = document.querySelectorAll('#reports table tbody tr[data-report-id]');
    let visibleCount = 0;
    const totalCount = rows.length;

    rows.forEach(row => {
      const objetivo = row.getAttribute('data-report-objetivo') || '';
      const categoria = row.getAttribute('data-report-categoria') || '';
      const estadoPrincipal = row.getAttribute('data-report-estado-principal') || '';
      const verification = row.getAttribute('data-report-verification') || '';
      const prioridad = row.getAttribute('data-report-prioridad') === 'true';
      const text = row.textContent.toLowerCase();

      let matches = true;

      if (filterText && !text.includes(filterText) && !objetivo.includes(filterText)) matches = false;
      if (filterCategory && categoria !== filterCategory) matches = false;
      if (filterEstadoPrincipal && estadoPrincipal !== filterEstadoPrincipal) matches = false;
      if (filterVerification && verification !== filterVerification) matches = false;
      if (filterPriority && !prioridad) matches = false;

      row.style.display = matches ? '' : 'none';
      if (matches) visibleCount++;
    });

    document.getElementById('reportsCount').textContent =
      filterText || filterCategory || filterEstadoPrincipal || filterVerification || filterPriority
        ? `${visibleCount} de ${totalCount} reportes`
        : `${totalCount} reportes`;
  }

  async function loadRecentReports() {
    try {
      // El app escribe con `createdAt`; el dashboard/test escribe con `creado_en`.
      // Para que “recientes” no dependa del formato, traemos ambos y mergeamos.
      const byId = new Map();

      async function tryOrder(fieldName) {
        try {
          const snap = await db.collection('reports')
            .orderBy(fieldName, 'desc')
            .limit(150)
            .get();
          snap.docs.forEach(d => byId.set(d.id, d));
        } catch (e) {
          console.warn(`No se pudo orderBy reports.${fieldName}:`, e);
        }
      }

      await Promise.all([
        tryOrder('createdAt'),
        tryOrder('creado_en'),
      ]);

      // Fallback: si ambas orderBy fallan, traer una ventana sin orden
      if (byId.size === 0) {
        const snap = await db.collection('reports').limit(200).get();
        snap.docs.forEach(d => byId.set(d.id, d));
      }

      const filteredDocs = Array.from(byId.values()).filter(doc => {
        const data = doc.data();
        const estado = data.estado || data.status || 'activo';
        return estado !== 'falso' && estado !== 'deleted';
      });

      filteredDocs.sort((a, b) => {
        const ams = _getMillisFromPossibleTimestamp(a.data().createdAt) ?? _getMillisFromPossibleTimestamp(a.data().creado_en) ?? 0;
        const bms = _getMillisFromPossibleTimestamp(b.data().createdAt) ?? _getMillisFromPossibleTimestamp(b.data().creado_en) ?? 0;
        return bms - ams;
      });

      const finalDocs = filteredDocs.slice(0, 50);

      const table = `
        <div class="table-responsive">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Tipo</th>
                <th>Categoría</th>
                <th>Objetivo</th>
                <th>Estado Principal</th>
                <th>Usuario</th>
                <th>Verificación</th>
                <th>Confirmaciones</th>
                <th>Confianza</th>
                <th>Prioridad</th>
                <th>Fecha</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              ${finalDocs.map(doc => {
                const data = doc.data();
                const tipo = (data.tipo || data.scope || 'estacion').toLowerCase();
                const objetivoId = data.objetivo_id || data.stationId || 'N/A';
                const usuarioId = data.usuario_id || data.userId || 'N/A';
                const estado = data.estado || data.status || 'activo';
                const categoria = data.categoria || 'aglomeracion';
                const estadoPrincipal = data.estado_principal || '-';
                const verificationStatus = data.verification_status || 'pending';
                const confirmationCount = data.confirmation_count || data.confirmations || 0;
                const prioridad = data.prioridad || false;

                let confidence = 0.5;
                if (typeof data.confidence === 'number') confidence = data.confidence;
                else if (data.confidence === 'high') confidence = 0.9;
                else if (data.confidence === 'medium') confidence = 0.6;
                else if (data.confidence === 'low') confidence = 0.3;

                let fecha = 'N/A';
                const ms = _getMillisFromPossibleTimestamp(data.creado_en) ?? _getMillisFromPossibleTimestamp(data.createdAt);
                if (ms) fecha = new Date(ms).toLocaleString('es-PA');

                const categoriaBadge = categoria === 'aglomeracion' ? 'badge-category-aglomeracion'
                  : categoria === 'retraso' ? 'badge-category-retraso'
                  : categoria === 'servicio_normal' ? 'badge-category-servicio_normal'
                  : categoria === 'falla_tecnica' ? 'badge-category-falla_tecnica'
                  : 'badge-medium';

                const categoriaLabel = categoria === 'aglomeracion' ? 'Aglom.'
                  : categoria === 'retraso' ? 'Retraso'
                  : categoria === 'servicio_normal' ? 'Normal'
                  : categoria === 'falla_tecnica' ? 'Falla'
                  : categoria;

                const verificationBadge = verificationStatus === 'verified' ? 'badge-high'
                  : verificationStatus === 'community_verified' ? 'badge-medium'
                  : 'badge-low';

                const verificationLabel = verificationStatus === 'verified' ? '✓ Verificado'
                  : verificationStatus === 'community_verified' ? '✓ Comunidad'
                  : '⏳ Pendiente';

                return `
                  <tr data-report-id="${doc.id}"
                      data-report-tipo="${tipo}"
                      data-report-objetivo="${objetivoId.toLowerCase()}"
                      data-report-categoria="${categoria}"
                      data-report-estado="${estado.toLowerCase()}"
                      data-report-estado-principal="${estadoPrincipal.toLowerCase()}"
                      data-report-prioridad="${prioridad}"
                      data-report-verification="${verificationStatus}"
                      style="cursor: pointer;"
                      onclick="showReportDetails('${doc.id}')">
                    <td>${doc.id.substring(0, 8)}...</td>
                    <td>${tipo === 'tren' ? '🚇 Tren' : '🏢 Estación'}</td>
                    <td><span class="badge ${categoriaBadge}">${categoriaLabel}</span></td>
                    <td>${objetivoId}</td>
                    <td>${estadoPrincipal}</td>
                    <td>${usuarioId.substring(0, 8)}...</td>
                    <td><span class="badge ${verificationBadge}">${verificationLabel}</span></td>
                    <td>${confirmationCount}</td>
                    <td>
                      <span class="badge ${confidence >= 0.8 ? 'badge-high' : confidence >= 0.5 ? 'badge-medium' : 'badge-low'}">
                        ${(confidence * 100).toFixed(0)}%
                      </span>
                    </td>
                    <td>${prioridad ? '🔴 Sí' : '⚪ No'}</td>
                    <td>${fecha}</td>
                    <td>
                      <button onclick="event.stopPropagation(); showReportDetails('${doc.id}')"
                              style="padding: 0.25rem 0.5rem; background: #667eea; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 0.85rem;">
                        Ver
                      </button>
                    </td>
                  </tr>
                `;
              }).join('')}
            </tbody>
          </table>
        </div>
      `;

      const loadingElement = document.querySelector('#reports .loading');
      if (loadingElement) loadingElement.outerHTML = table;
      else {
        const section = document.getElementById('reports');
        if (section) {
          const existingTable = section.querySelector('table');
          if (existingTable) existingTable.outerHTML = table;
          else section.insertAdjacentHTML('beforeend', table);
        }
      }

      document.getElementById('reportsCount').textContent = `${finalDocs.length} reportes`;
    } catch (error) {
      console.error('Error loading reports:', error);
      const loadingElement = document.querySelector('#reports .loading');
      const errorMsg = error.message.includes('permissions')
        ? '⚠️ Error de permisos. Verifica las reglas de Firestore. Los reportes requieren autenticación.'
        : 'Error al cargar reportes: ' + error.message;
      if (loadingElement) loadingElement.textContent = errorMsg;
      else document.getElementById('reports')?.insertAdjacentHTML('beforeend', `<div class="loading">${errorMsg}</div>`);
    }
  }

  async function clearAllReports() {
    if (!confirm('⚠️ ¿Estás seguro de que quieres MARCAR TODOS los reportes como eliminados?\n\nLos reportes se marcarán como "deleted" pero no se eliminarán físicamente.')) {
      return;
    }

    const statusDiv = document.getElementById('testToolsStatus');
    const btn = document.getElementById('clearReportsBtn');

    try {
      if (btn) btn.disabled = true;
      if (statusDiv) statusDiv.textContent = '🗑️ Marcando reportes como eliminados...';

      const snapshot = await db.collection('reports').get();
      const activeDocs = snapshot.docs.filter(doc => {
        const status = doc.data().status || 'active';
        return status !== 'deleted';
      });

      if (activeDocs.length === 0) {
        if (statusDiv) {
          statusDiv.innerHTML = 'ℹ️ No hay reportes activos para marcar como eliminados';
          statusDiv.style.color = '#666';
        }
        if (btn) btn.disabled = false;
        return;
      }

      const batchSize = 500;
      let totalProcessed = 0;

      for (let i = 0; i < activeDocs.length; i += batchSize) {
        const batch = db.batch();
        const batchDocs = activeDocs.slice(i, i + batchSize);
        batchDocs.forEach(doc => batch.update(doc.ref, { status: 'deleted' }));
        await batch.commit();
        totalProcessed += batchDocs.length;
        if (statusDiv) statusDiv.textContent = `🗑️ Procesando... ${totalProcessed}/${activeDocs.length}`;
      }

      if (statusDiv) {
        statusDiv.innerHTML = `✅ <strong>${totalProcessed} reportes marcados como eliminados</strong>`;
        statusDiv.style.color = '#28a745';
      }

      setTimeout(() => {
        loadRecentReports();
        window.loadStats?.();
      }, 1000);
    } catch (error) {
      console.error('Error clearing reports:', error);
      if (statusDiv) {
        statusDiv.innerHTML = `❌ Error: ${error.message}`;
        statusDiv.style.color = '#dc3545';
      }
    } finally {
      if (btn) btn.disabled = false;
    }
  }

  async function showReportStats() {
    const statusDiv = document.getElementById('testToolsStatus');
    const btn = document.getElementById('statsBtn');

    try {
      if (btn) btn.disabled = true;
      if (statusDiv) statusDiv.textContent = '📈 Calculando estadísticas...';

      const snapshot = await db.collection('reports').get();

      let stationReports = 0;
      let trainReports = 0;
      let activeReports = 0;
      let resolvedReports = 0;
      let falseReports = 0;
      let totalConfirmations = 0;
      let priorityReports = 0;
      let verifiedReports = 0;
      const categoryStats = { aglomeracion: 0, retraso: 0, servicio_normal: 0, falla_tecnica: 0 };

      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const tipo = data.tipo || data.scope || 'estacion';
        const estado = data.estado || data.status || 'activo';
        const categoria = data.categoria || 'aglomeracion';

        if (tipo === 'estacion') stationReports++;
        if (tipo === 'tren') trainReports++;

        totalConfirmations += (data.confirmation_count || data.confirmations || 0);

        if (estado === 'activo') activeReports++;
        else if (estado === 'resuelto') resolvedReports++;
        else if (estado === 'falso' || estado === 'deleted') falseReports++;

        if (data.prioridad) priorityReports++;

        const verificationStatus = data.verification_status || 'pending';
        if (verificationStatus === 'verified' || verificationStatus === 'community_verified') verifiedReports++;

        if (Object.prototype.hasOwnProperty.call(categoryStats, categoria)) categoryStats[categoria]++;
      });

      const stats = `
        <strong>📊 Estadísticas de Reportes:</strong><br>
        • Total: ${snapshot.size} reportes<br>
        • Estaciones: ${stationReports} | Trenes: ${trainReports}<br>
        • Activos: ${activeReports} | Resueltos: ${resolvedReports} | Falsos/Eliminados: ${falseReports}<br>
        • Prioritarios: ${priorityReports}<br>
        • Verificados: ${verifiedReports} (${snapshot.size > 0 ? ((verifiedReports / snapshot.size) * 100).toFixed(1) : 0}%)<br>
        • Total confirmaciones: ${totalConfirmations}<br>
        <br>
        <strong>Por Categoría:</strong><br>
        • Aglomeración: ${categoryStats.aglomeracion}<br>
        • Retraso: ${categoryStats.retraso}<br>
        • Servicio Normal: ${categoryStats.servicio_normal}<br>
        • Falla Técnica: ${categoryStats.falla_tecnica}
      `;

      if (statusDiv) {
        statusDiv.innerHTML = stats;
        statusDiv.style.color = '#333';
      }
    } catch (error) {
      console.error('Error getting stats:', error);
      if (statusDiv) {
        statusDiv.innerHTML = `❌ Error: ${error.message}`;
        statusDiv.style.color = '#dc3545';
      }
    } finally {
      if (btn) btn.disabled = false;
    }
  }

  function filterReportsListByStation(stationId) {
    const filterInput = document.getElementById('filterReports');
    if (filterInput) {
      filterInput.value = stationId;
      filterInput.dispatchEvent(new Event('input'));
      filterReportsAdvanced();
    }
  }

  window.loadRecentReports = loadRecentReports;
  window.filterReportsAdvanced = filterReportsAdvanced;
  window.filterReportsListByStation = filterReportsListByStation;
  window.clearAllReports = clearAllReports;
  window.showReportStats = showReportStats;
})();
