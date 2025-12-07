---
name: Sistema de Horarios Base y Reportes de Llegada - Fase 1
overview: ""
todos:
  - id: 1ff92768-5a96-4b08-b927-a07d1964f982
    content: "Expandir BadgeType enum con más badges según el plan (25+ logros): precisión 80%, helper 50, influencer 100, línea 1 experto, línea 2 maestro, eventos panameños"
    status: pending
  - id: 09f4bd20-e5c1-4339-b208-48ded3f6bcba
    content: "Agregar leaderboards especializados: por línea (Línea 1 y Línea 2), semanal, precisión, streak, helpers"
    status: pending
  - id: dbfb177f-44ea-4702-ace8-d7cb7b9ecf8a
    content: Actualizar LeaderboardScreen para incluir selector de tipos de leaderboard y mostrar diferentes rankings
    status: pending
  - id: d1c3bcdf-82b5-4fa9-823e-890596d4d0ab
    content: Implementar verificación automática de nuevos badges en GamificationService
    status: pending
  - id: 4ab49c23-abc0-485b-a583-3575e54ef084
    content: Agregar índices de Firestore para leaderboards especializados (puntos por línea, precisión, streak)
    status: pending
  - id: 95baccfd-bcec-464c-a8af-bb5e5296194a
    content: Remover imports no usados (scheduler.dart, user_model.dart en confidence_service, firebase_messaging en alert_service, train_simulation_table en custom_metro_map, geolocator y metro_data_provider en enhanced_report_modal)
    status: pending
  - id: 742e50fa-cc25-4d05-9d73-0cc8eb584cc9
    content: Remover campos no usados (_tempImageUrl en edit_profile_screen, _firebaseService en accuracy_service y report_validation_service, _firestore en accuracy_service, _orderedStations en custom_metro_map)
    status: pending
  - id: 1a50c3fe-fabb-45a8-a542-6f7825611762
    content: Remover variables locales no usadas (userId y gamificationService en quick_report_sheet, tipo y tenMinutesAgo en alert_service)
    status: pending
  - id: edab6492-6d77-40a8-8e33-5f0b2f9a88b2
    content: Corregir use_build_context_synchronously en notification_settings_screen, enhanced_report_modal y quick_report_sheet
    status: pending
  - id: 0e92dbf4-b1b6-4c13-b8c9-655ef85c610f
    content: Agregar const donde sea posible (prefer_const_constructors y prefer_const_literals_to_create_immutables)
    status: pending
  - id: a9de1ebb-2468-476c-9dbf-61bd219aa59a
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: 1d5b9448-5c0d-41ae-9b5c-a0b1709bc667
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: 7ac22eae-4ef6-4161-abf7-2d8b9b8170f7
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: 2473ad90-30e3-494c-a445-8b3fc67fcba1
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: f82db983-c40c-49b6-a3ec-fdb17cc7d6cd
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: 48a8367e-ad80-47ed-a0ff-91fa48aa2e8a
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: 6b67c27c-e787-4f1d-8307-6f23a37ec51e
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: 678a1621-19ce-451b-adc1-7573599360b5
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: e65e9d9a-7b50-4aa3-92da-be604dcc849b
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: 9a3a467d-b923-4329-96ef-e7c55febf833
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: cfcb4f73-bd2c-4e8f-bca4-c2a2ab626550
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: f788f81e-6e8f-404d-a5a4-e429e2d7b566
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: 9de55c83-a74a-4896-931a-bb2f52d6c541
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: 3bd661a2-e7f2-4ede-99ac-87683ec90880
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: 91f1cd1d-146c-4d89-8e89-6f95557c9a95
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: c37d0100-722e-4daa-8377-820d5511e775
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: ec3cae1f-b658-4334-b950-b3d79f785af8
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: 4d5cfb6a-dc69-4e84-96d8-ff61c9a7457c
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: 7ab23603-584f-4a6d-bb20-300d5dbef12e
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
  - id: 0b538a60-657d-4b94-a302-c5fb4daf709f
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: d44fa868-3e8b-455a-8317-3364bad78999
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: 8f87877d-bf95-4f22-885b-35edc0401fb0
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: 55b63554-e942-48dc-afc9-27f566773056
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: 5d059190-51da-42a0-9319-3d2e4a4efe4a
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: d9204a4e-69a9-4c67-a1a8-2344e78bf24f
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: 3df0cf52-b7dd-4f72-b29e-5ddca1604533
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: 6b19abf2-6e9f-4840-a85c-7489b978402b
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: abc85d23-399c-423e-a08e-6bba35b70486
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: 76a7795d-94b1-4ce1-9b00-c47d12334279
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: 54867edb-50cd-4e63-a29e-d3a12b66b058
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: 5265495d-7761-486e-843d-e87650246ac6
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: 505d4910-aa2a-4a60-8cd3-4e812864ab64
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: 0241fa9d-efae-4aa4-8074-c8fb9a5b01ae
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: 4e24a048-ef7c-4db5-a8fe-906d5e3e813f
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: cc816af3-f5d2-4b4f-b8ec-46a0d46438fe
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: 733f21bf-94c1-4d41-9132-65ab90a12cbb
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: c7fc91d1-fad0-4ede-81f3-b61511acbdc8
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: 14bb2903-0e61-4c9b-8e17-2fea138d40b2
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
  - id: 68dd563e-902f-4b5b-b420-27a4085c7f06
    content: "Expandir BadgeType enum con más badges según el plan (25+ logros): precisión 80%, helper 50, influencer 100, línea 1 experto, línea 2 maestro, eventos panameños"
    status: pending
  - id: 7619ae04-27b9-41fb-935b-7920c3bc74d7
    content: "Agregar leaderboards especializados: por línea (Línea 1 y Línea 2), semanal, precisión, streak, helpers"
    status: pending
  - id: adabfd6d-0951-4d80-9812-90e7668fadde
    content: Actualizar LeaderboardScreen para incluir selector de tipos de leaderboard y mostrar diferentes rankings
    status: pending
  - id: b600c641-6a40-4c5b-991c-f192b23f368d
    content: Implementar verificación automática de nuevos badges en GamificationService
    status: pending
  - id: 1df9cf22-032c-49b5-8996-9d191a4e5790
    content: Agregar índices de Firestore para leaderboards especializados (puntos por línea, precisión, streak)
    status: pending
  - id: 7e8cf1ea-fdba-4380-9282-fcd60614df51
    content: Remover imports no usados (scheduler.dart, user_model.dart en confidence_service, firebase_messaging en alert_service, train_simulation_table en custom_metro_map, geolocator y metro_data_provider en enhanced_report_modal)
    status: pending
  - id: b3d55098-6962-4c16-888e-17082874420c
    content: Remover campos no usados (_tempImageUrl en edit_profile_screen, _firebaseService en accuracy_service y report_validation_service, _firestore en accuracy_service, _orderedStations en custom_metro_map)
    status: pending
  - id: 3fe57fb3-2879-47af-b831-5541092d18f7
    content: Remover variables locales no usadas (userId y gamificationService en quick_report_sheet, tipo y tenMinutesAgo en alert_service)
    status: pending
  - id: 291e94c6-90d0-41fc-b47d-3b42d9d64080
    content: Corregir use_build_context_synchronously en notification_settings_screen, enhanced_report_modal y quick_report_sheet
    status: pending
  - id: 6221037d-1b35-4a79-9470-e443e2c19fb9
    content: Agregar const donde sea posible (prefer_const_constructors y prefer_const_literals_to_create_immutables)
    status: pending
  - id: a17a036e-0fb7-4e26-b619-359912059960
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: e19cefc7-d64d-44af-83ba-099deacb18f9
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: 5ccceae5-7204-4056-84d6-e67d588c38a4
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: e70400bd-b948-4f97-8c46-35afd3802ea0
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: 3b249d7a-ed68-4058-a92a-df4c2a92d547
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: 1822a3e5-29cf-4592-a11a-a614ac40b6af
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: 7668008e-a204-4851-a71a-e71680914884
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: 5d6d09cc-c096-4fa8-930c-75b844dcfd80
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: 7933b262-f874-465a-9afd-a72549f0e176
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: 85ed4a8f-fee3-40da-8453-6e9e841bc337
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: eb45396c-8f2a-45c8-814a-c5f17b457fbc
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: ce9e85d7-5d42-4c7c-b577-9c473314ab16
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: b815d0b0-bd50-4c78-9c27-528f701d9f86
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: 0b3d4bc9-db4e-49ad-b504-0d621168b3b4
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: 72641034-d24d-4964-b4a4-e25567086669
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: 33a94841-bc5f-42c0-bd79-52da3e6184ff
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: 165a2b1f-552a-4812-99c5-94c58dd26f98
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: fb9cc612-7de0-4fef-a428-d10c0c0698cd
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: ae0ee804-12b3-4eb3-95e0-1b137b8a450a
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
  - id: 2d8fc53c-6bfe-4bfb-92f0-9e23fb0f2d73
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: 65ed1920-5ce1-47aa-a44c-f1eeb7269155
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: aee87575-e119-4967-9480-20ff262e2d74
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: d08b4b52-975b-4854-a08b-285d39b0d39b
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: 17b08307-39cb-4f43-bf8e-f0f30f3ed74a
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: 7f348ab1-263b-4656-a332-88e883dead43
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: 155534a9-9d8d-44fe-a9e6-2ba27061d9ef
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: c096b573-2fd3-4488-8fa0-32c4109ec1e5
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: 75a56775-d179-49fa-bd3d-4185ac3955f5
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: 2b6db96d-b4db-412c-a570-2255f9516602
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: d71c997e-cdbf-42aa-a0e3-0d8291806de8
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: f31eff94-6d1a-4240-86c7-909bf45791e1
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: a6a84c64-c15b-4d54-83e0-ff9688f533fe
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: e7d89ebf-284c-4cbb-83f5-168631cf5687
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: d0a6b0e4-11e1-435a-918b-f791149bde73
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: c39b29ac-9366-4dfd-babc-74555062ff3d
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: 4c440366-1ff9-4e3d-b52d-7d6fca177265
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: e31624a8-effb-42ba-8964-74d840f23bfd
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: 8c15b25e-cc99-4a60-bb9f-d168bc477eaa
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
  - id: a8739c50-db20-42b1-99b6-070882c79ac0
    content: "Expandir BadgeType enum con más badges según el plan (25+ logros): precisión 80%, helper 50, influencer 100, línea 1 experto, línea 2 maestro, eventos panameños"
    status: pending
  - id: 263a6b11-cf9b-450a-a231-9423b99e26da
    content: "Agregar leaderboards especializados: por línea (Línea 1 y Línea 2), semanal, precisión, streak, helpers"
    status: pending
  - id: 442e9646-7ab9-4e03-b6de-750e9d98d3ca
    content: Actualizar LeaderboardScreen para incluir selector de tipos de leaderboard y mostrar diferentes rankings
    status: pending
  - id: 95f819fb-380a-468c-9577-cf7544ca5322
    content: Implementar verificación automática de nuevos badges en GamificationService
    status: pending
  - id: 15a9157f-4036-4175-a629-39f0b79f8078
    content: Agregar índices de Firestore para leaderboards especializados (puntos por línea, precisión, streak)
    status: pending
  - id: 3656f80d-0fb6-4552-9120-467a24346d53
    content: Remover imports no usados (scheduler.dart, user_model.dart en confidence_service, firebase_messaging en alert_service, train_simulation_table en custom_metro_map, geolocator y metro_data_provider en enhanced_report_modal)
    status: pending
  - id: c204bddf-2801-4690-9d09-ab2f919fd0a4
    content: Remover campos no usados (_tempImageUrl en edit_profile_screen, _firebaseService en accuracy_service y report_validation_service, _firestore en accuracy_service, _orderedStations en custom_metro_map)
    status: pending
  - id: 8a303560-0d51-4301-8f6d-ed6731dd63e5
    content: Remover variables locales no usadas (userId y gamificationService en quick_report_sheet, tipo y tenMinutesAgo en alert_service)
    status: pending
  - id: fbd4d383-108a-4355-938f-2fa23761b5bd
    content: Corregir use_build_context_synchronously en notification_settings_screen, enhanced_report_modal y quick_report_sheet
    status: pending
  - id: 796d697d-a951-4c74-ad36-1c30e0fd8565
    content: Agregar const donde sea posible (prefer_const_constructors y prefer_const_literals_to_create_immutables)
    status: pending
  - id: 2a9ef1a9-a174-4765-9a32-b248f6299615
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: c8d04aea-1d16-41ef-a4c9-28f26ae3d87f
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: bfeb9ddd-bd1e-4684-8837-e818a625d8b2
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: 1d398534-2a98-4ea0-b1fe-bb73fc17c3a4
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: ba2be83f-555b-44c4-bb4a-2219af439093
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: 999ae1f1-bf6e-4663-9387-be2807fd347a
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: 50cf6817-e665-46a7-bf6c-628f96f52227
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: 8fba5447-48d1-4f5c-b60f-8300912aa296
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: 6d8016d7-6e6b-40d8-9696-8e831c161f01
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: 9705b2ee-125d-4963-99dc-f94d061c729d
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: de32fa78-0e99-4a3a-b7e5-eda06bf82d7c
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: 98e4fda4-6aee-4ad2-8f87-f35363f36239
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: 68fee54a-5384-4c30-8ad5-4afe8f712976
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: 92ddfc53-c7c4-43ac-8dfd-3c4cdf31d16c
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: c743c221-e615-4a73-aa5f-9692f73c9d53
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: 8c944a7d-7a0b-4bc5-87ed-1e2f7dc22ad7
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: 81f1e5d9-9039-4274-a449-d27651f1313a
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: dc10b0e4-74ee-4b30-bf31-6b45441e5dcb
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: 1a66f6f6-44cf-4bff-ad32-8abdece4e9a0
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
  - id: 0778db2c-da0b-43dd-a257-dc718c071b12
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: d7dd0a08-25e6-4229-8b2b-7a9db1beba22
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: f7ad256f-41a2-4232-ab18-66b0efead19f
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: df5d3505-a83e-4c8d-ac22-cb3cd7c1b6cf
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: 1182618d-1014-48fd-ba81-6f106494be9f
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: 2eeb42f4-b681-4826-868a-05235a0812ee
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: 959cfdbb-8df1-434b-af11-937390eb7cf4
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: 7fcceaac-1c49-42fc-84aa-62955e93393e
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: 997c1727-bea1-4a30-a3d3-86d99beb8af4
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: 5ce3f6a1-959d-48e1-bf0c-1bd92f0be01a
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: 8832e306-8f44-4008-b639-c8a76063b6df
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: 57e543c2-71aa-4e74-a7f9-0d55e080fa2f
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: 7d8e3c76-1e98-4d90-98b6-e2baac63fc2d
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: a1f8b328-b157-4bf0-b6de-9af0890b4118
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: 00fdc06e-6fab-4765-a8e3-3225e6d21aee
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: 3025b4ab-f0dd-45b6-a6f4-c530087243dc
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: 152f21cc-6a27-471f-91b8-f61f50fc9595
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: 598c04e7-9bd6-49c4-a3ee-c24bc4f086ca
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: 2520eb4f-025d-44f8-8055-8c32952182a0
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
  - id: b3da5738-c309-4211-9261-236d8f305250
    content: "Expandir BadgeType enum con más badges según el plan (25+ logros): precisión 80%, helper 50, influencer 100, línea 1 experto, línea 2 maestro, eventos panameños"
    status: pending
  - id: 2d719539-ffa5-4998-800d-ace68c10d50b
    content: "Agregar leaderboards especializados: por línea (Línea 1 y Línea 2), semanal, precisión, streak, helpers"
    status: pending
  - id: 76365faa-9aa9-4236-aa15-65a94afcfe2e
    content: Actualizar LeaderboardScreen para incluir selector de tipos de leaderboard y mostrar diferentes rankings
    status: pending
  - id: bf899761-1725-49c2-b301-86a5377a1aff
    content: Implementar verificación automática de nuevos badges en GamificationService
    status: pending
  - id: 38152446-54d8-437f-a4aa-4c87f0b269ce
    content: Agregar índices de Firestore para leaderboards especializados (puntos por línea, precisión, streak)
    status: pending
  - id: bc430d25-f4f5-4b45-91e8-be7a30ec6211
    content: Remover imports no usados (scheduler.dart, user_model.dart en confidence_service, firebase_messaging en alert_service, train_simulation_table en custom_metro_map, geolocator y metro_data_provider en enhanced_report_modal)
    status: pending
  - id: 39f586c3-d450-4b06-b7c0-79140e1b04ba
    content: Remover campos no usados (_tempImageUrl en edit_profile_screen, _firebaseService en accuracy_service y report_validation_service, _firestore en accuracy_service, _orderedStations en custom_metro_map)
    status: pending
  - id: 9559fbb4-653f-4f26-a1a2-ba96603845fd
    content: Remover variables locales no usadas (userId y gamificationService en quick_report_sheet, tipo y tenMinutesAgo en alert_service)
    status: pending
  - id: 978ddfa1-16ff-479b-9b13-01a6176ae19f
    content: Corregir use_build_context_synchronously en notification_settings_screen, enhanced_report_modal y quick_report_sheet
    status: pending
  - id: 0be6fd5e-2f00-42b1-a2f0-8a791a0d8534
    content: Agregar const donde sea posible (prefer_const_constructors y prefer_const_literals_to_create_immutables)
    status: pending
  - id: 0de85470-8546-46ab-9272-dba7d525a109
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: 748f7cf0-5fa6-4352-a56d-1a13ea807183
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: 2f79c14a-801d-4fa1-9cef-0c90a1462a42
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: b5e1f6d8-3d07-49b8-8f63-f38105263d3e
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: 6d423b2d-72e0-4b3c-859b-184ed61cfaf1
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: cb48f929-dd44-4ec2-8e52-e6f08120fb13
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: fb4232b5-499b-4fb8-8d3b-9163a7cb1c85
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: 981a75fd-d622-49b7-becb-bde74c3744e7
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: 1a205fa7-4b0b-485a-9381-18907056a367
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: ff805b0a-a62e-473b-9da3-1450f8f56a3f
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: 5f4b1441-1368-40e7-8597-74c8dcd9234a
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: a3ae7ee2-52fb-4c07-a73e-b50a9f4f86ae
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: de3eb86b-703d-4634-8089-d4bb9473fc63
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: e5941785-e6ab-49cf-bdce-3e3eadaae095
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: b66ef8fc-5997-49ef-8835-a79fdff700ce
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: 834bebed-a3f7-4096-ace8-c0c44ad061f6
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: 71566d8b-9193-46d8-856b-002d4c61534b
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: 1b019c2d-28fa-41d2-ac2d-498e6ce289c4
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: a0f0cff3-cf72-4274-ba37-809c40b715fd
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
  - id: 48abc282-5fc9-4a49-a1af-e9d2e96b5827
    content: Crear UI para confirmar reportes de otros usuarios (botón de confirmación en reportes)
    status: pending
  - id: 20535317-7192-47dd-a8e0-dfccb5d8f23c
    content: Implementar cálculo de confidence basado en confirmaciones y reputación del usuario
    status: pending
  - id: 4e9abd61-036d-44ff-b5f3-d179fa003e24
    content: Implementar verificación automática cuando hay 3+ confirmaciones
    status: pending
  - id: 629ae24f-4bf0-4d1f-abee-5025296ff670
    content: Actualizar estado de estación/tren basado en reportes verificados
    status: pending
  - id: f4b32041-01bd-4369-8672-0c74e5ae58bc
    content: Crear Cloud Functions para procesamiento en tiempo real de reportes
    status: pending
  - id: 2c44ca20-f682-4670-96d7-e65777f08000
    content: Implementar notificaciones automáticas cuando se crea un reporte relevante
    status: pending
  - id: cc265f27-c4b9-42c5-8175-064f4c46bd63
    content: Implementar sistema de alertas inteligentes para usuarios afectados
    status: pending
  - id: 627a4bcd-10e0-4fba-90b6-1b9d3a00197f
    content: Implementar alertas prioritarias para reportes críticos
    status: pending
  - id: 8fdcac8d-88eb-4060-acd5-4a3e912b7308
    content: Implementar sistema de precisión de reportes por usuario
    status: pending
  - id: 3f102cac-1a2d-4114-9ac2-821b2e3b0e65
    content: Agregar badges avanzados basados en precisión y contribuciones
    status: pending
  - id: dfd99ac7-f458-46f7-8704-e1ff3f00c114
    content: "Mejoras opcionales: Agregar pull-to-refresh en historial de reportes"
    status: pending
  - id: d5ace46b-3e2c-49c0-b5a6-6ebe677b4c01
    content: "Mejoras opcionales: Agregar filtros por estado en historial de reportes"
    status: pending
  - id: fbfa3c1b-0df0-4719-af83-bf1d8cb14513
    content: "Mejoras opcionales: Agregar búsqueda en historial de reportes"
    status: pending
  - id: 3eb8cd22-1929-43bb-9a59-43b2ff806ff3
    content: "Extender ReportModel con nuevos campos: estadoPrincipal, problemasEspecificos, prioridad, fotoUrl, confidence, verificationStatus, confirmationCount"
    status: pending
  - id: c868599e-1300-4940-a56a-37d66cf3b06c
    content: Crear EnhancedReportModal con header, botones de estado principal, problemas específicos, prioridad y foto opcional
    status: pending
  - id: 99c35ca6-4393-4050-8efb-64df64095019
    content: Integrar modal en map_widget.dart y custom_metro_map.dart para abrir al tocar estación/tren
    status: pending
  - id: cfc695df-4a9f-4116-9890-b3dc32ad6081
    content: Crear ReportValidationService con validación anti-spam y de ubicación
    status: pending
  - id: b0abf8f2-f1b2-49bd-8202-b9e41d85a48b
    content: Actualizar ReportProvider para aceptar nuevos campos y usar validación
    status: pending
  - id: 4942afa7-bc11-4c17-a3c2-83df5ea1f51b
    content: Actualizar FirebaseService.createReport para guardar nuevos campos y agregar findSimilarReports
    status: pending
---

# Sistema de Horarios Base y Reportes de Llegada - Fase 1

## Objetivo

Implementar horarios base predeterminados del metro diferenciados por weekdays/weekends y UI para que usuarios reporten llegadas reales, creando la base de datos necesaria para un futuro algoritmo de aprendizaje automático.

## Priorización por Sprints

### SPRINT 1 (Crítico - 3-4 días): Horarios Base Funcionando

- `schedule_service.dart` - Horarios inteligentes (weekdays/weekends)
- `time_estimation_service.dart` - Integración con horarios base
- Validación básica de ubicación

### SPRINT 2 (Crítico - 3-4 días): Reportes de Llegada Básicos

- `learning_report_model.dart` - Modelo de datos
- `learning_