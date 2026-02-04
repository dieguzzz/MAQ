(function () {
  const { db } = window.Dashboard;
  const { escapeHtml } = window.Dashboard.utils;

  async function showReportDetails(reportId) {
    const modal = document.getElementById('reportModal');
    const modalBody = document.getElementById('reportModalBody');

    modal.classList.add('active');
    modalBody.innerHTML = '<div class="loading">Cargando detalles...</div>';

    try {
      const doc = await db.collection('reports').doc(reportId).get();
      if (!doc.exists) {
        modalBody.innerHTML = '<div class="loading" style="color: #dc3545;">Reporte no encontrado</div>';
        return;
      }

      const data = doc.data();

      const tipo = data.tipo || data.scope || 'estacion';
      const objetivoId = data.objetivo_id || data.stationId || 'N/A';
      const usuarioId = data.usuario_id || data.userId || 'N/A';
      const categoria = data.categoria || 'aglomeracion';
      const estadoPrincipal = data.estado_principal || '-';
      const problemasEspecificos = data.problemas_especificos || [];
      const prioridad = data.prioridad || false;
      const descripcion = data.descripcion || 'Sin descripción';
      const fotoUrl = data.foto_url || null;
      const verificationStatus = data.verification_status || 'pending';
      const confirmationCount = data.confirmation_count || data.confirmations || 0;
      const estado = data.estado || data.status || 'activo';

      let confidence = 0.5;
      if (typeof data.confidence === 'number') confidence = data.confidence;
      else if (data.confidence === 'high') confidence = 0.9;
      else if (data.confidence === 'medium') confidence = 0.6;
      else if (data.confidence === 'low') confidence = 0.3;

      let fecha = 'N/A';
      if (data.creado_en) fecha = new Date(data.creado_en.toMillis ? data.creado_en.toMillis() : data.creado_en).toLocaleString('es-PA');
      else if (data.createdAt) fecha = new Date(data.createdAt.toMillis ? data.createdAt.toMillis() : data.createdAt).toLocaleString('es-PA');

      let ubicacionText = 'N/A';
      if (data.ubicacion) {
        ubicacionText = `${data.ubicacion.latitude.toFixed(6)}, ${data.ubicacion.longitude.toFixed(6)}`;
      }

      const tiempoEstimadoReportado = data.tiempo_estimado_reportado || null;
      const tiempoEstimadoValidado = data.tiempo_estimado_validado !== undefined ? data.tiempo_estimado_validado : null;

      // Nombre estación (si aplica)
      let objetivoNombre = objetivoId;
      try {
        if (tipo === 'estacion') {
          const stationDoc = await db.collection('stations').doc(objetivoId).get();
          if (stationDoc.exists) objetivoNombre = stationDoc.data().nombre || objetivoId;
        }
      } catch (e) {
        console.log('No se pudo obtener nombre de estación:', e);
      }

      // Nombre usuario (si aplica)
      let usuarioNombre = usuarioId.substring(0, 8);
      try {
        const userDoc = await db.collection('users').doc(usuarioId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          usuarioNombre = userData.nombre || userData.email || usuarioId.substring(0, 8);
        }
      } catch (e) {
        console.log('No se pudo obtener nombre de usuario:', e);
      }

      const html = `
        <div class="modal-section">
          <h3>Información Básica</h3>
          <div class="modal-field"><span class="modal-field-label">ID:</span><span class="modal-field-value">${doc.id}</span></div>
          <div class="modal-field"><span class="modal-field-label">Tipo:</span><span class="modal-field-value">${tipo === 'tren' ? '🚇 Tren' : '🏢 Estación'}</span></div>
          <div class="modal-field"><span class="modal-field-label">Objetivo:</span><span class="modal-field-value">${objetivoNombre}</span></div>
          <div class="modal-field">
            <span class="modal-field-label">Categoría:</span>
            <span class="modal-field-value">
              <span class="badge badge-category-${categoria}">
                ${categoria === 'aglomeracion' ? 'Aglomeración' : categoria === 'retraso' ? 'Retraso' : categoria === 'servicio_normal' ? 'Servicio Normal' : 'Falla Técnica'}
              </span>
            </span>
          </div>
          <div class="modal-field"><span class="modal-field-label">Estado Principal:</span><span class="modal-field-value">${estadoPrincipal}</span></div>
          <div class="modal-field"><span class="modal-field-label">Estado:</span><span class="modal-field-value">${estado}</span></div>
          <div class="modal-field">
            <span class="modal-field-label">Prioridad:</span>
            <span class="modal-field-value">
              ${prioridad ? '<span class="badge badge-priority">🔴 Prioritario</span>' : '<span class="badge">⚪ Normal</span>'}
            </span>
          </div>
        </div>

        <div class="modal-section">
          <h3>Usuario y Verificación</h3>
          <div class="modal-field"><span class="modal-field-label">Usuario:</span><span class="modal-field-value">${usuarioNombre}</span></div>
          <div class="modal-field">
            <span class="modal-field-label">Estado de Verificación:</span>
            <span class="modal-field-value">
              <span class="badge ${verificationStatus === 'verified' ? 'badge-high' : verificationStatus === 'community_verified' ? 'badge-medium' : 'badge-low'}">
                ${verificationStatus === 'verified' ? '✓ Verificado' : verificationStatus === 'community_verified' ? '✓ Verificado por Comunidad' : '⏳ Pendiente'}
              </span>
            </span>
          </div>
          <div class="modal-field"><span class="modal-field-label">Confirmaciones:</span><span class="modal-field-value">${confirmationCount}</span></div>
          <div class="modal-field">
            <span class="modal-field-label">Confianza:</span>
            <span class="modal-field-value">
              <span class="badge ${confidence >= 0.8 ? 'badge-high' : confidence >= 0.5 ? 'badge-medium' : 'badge-low'}">
                ${(confidence * 100).toFixed(0)}%
              </span>
            </span>
          </div>
        </div>

        ${problemasEspecificos.length > 0 ? `
        <div class="modal-section">
          <h3>Problemas Específicos</h3>
          <div class="modal-field">
            <span class="modal-field-value">
              ${problemasEspecificos.map(p => `<span class="problem-tag">${p}</span>`).join('')}
            </span>
          </div>
        </div>
        ` : ''}

        ${descripcion && descripcion !== 'Sin descripción' ? `
        <div class="modal-section">
          <h3>Descripción</h3>
          <div class="modal-field"><span class="modal-field-value">${escapeHtml(descripcion)}</span></div>
        </div>
        ` : ''}

        ${fotoUrl ? `
        <div class="modal-section">
          <h3>Foto</h3>
          <div class="modal-field">
            <img src="${fotoUrl}" alt="Foto del reporte" class="modal-photo" onclick="window.open('${fotoUrl}', '_blank')" style="cursor: pointer;">
          </div>
        </div>
        ` : ''}

        <div class="modal-section">
          <h3>Ubicación y Tiempo</h3>
          <div class="modal-field"><span class="modal-field-label">Ubicación:</span><span class="modal-field-value">${ubicacionText}</span></div>
          <div class="modal-field"><span class="modal-field-label">Fecha de Creación:</span><span class="modal-field-value">${fecha}</span></div>
          ${tiempoEstimadoReportado !== null ? `
          <div class="modal-field"><span class="modal-field-label">Tiempo Estimado Reportado:</span><span class="modal-field-value">${tiempoEstimadoReportado} minutos</span></div>
          ${tiempoEstimadoValidado !== null ? `
          <div class="modal-field">
            <span class="modal-field-label">Tiempo Validado:</span>
            <span class="modal-field-value">
              ${tiempoEstimadoValidado ? '<span style="color: #28a745;">✓ Válido</span>' : '<span style="color: #dc3545;">✗ Inválido</span>'}
            </span>
          </div>
          ` : ''}
          ` : ''}
        </div>
      `;

      modalBody.innerHTML = html;
    } catch (error) {
      console.error('Error loading report details:', error);
    }
  }

  function closeReportModal() {
    const modal = document.getElementById('reportModal');
    if (modal) modal.classList.remove('active');
  }

  window.showReportDetails = showReportDetails;
  window.closeReportModal = closeReportModal;
})();



