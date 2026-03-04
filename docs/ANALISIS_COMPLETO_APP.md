# Análisis Completo - MetroPTY App
**Fecha:** 3 de marzo de 2026
**Archivos analizados:** 140 archivos Dart + Cloud Functions + Config
**Alcance:** Servicios, Pantallas, Modelos, Widgets, Utils, Providers, Tema, Seguridad

---

## Resumen Ejecutivo

| Severidad | Cantidad | Ejemplos clave |
|-----------|----------|----------------|
| **CRÍTICO** | 10 | Compras sin verificación servidor, memory leaks, race conditions auth |
| **ALTO** | 13 | 293 print() en producción, streams sin dispose, archivos de 1400+ líneas |
| **MEDIO** | 47 | Valores hardcodeados, validaciones faltantes, UX incompleta |
| **BAJO** | 41 | i18n, emojis, configuración, estética |

---

## 1. PROBLEMAS CRÍTICOS

### 1.1 Compras In-App sin Verificación del Servidor
**Archivo:** `lib/services/subscription_service.dart` (líneas 97-112)
**Problema:** La compra se activa directamente en Firestore sin verificar con un backend. Un usuario podría fabricar el status premium manipulando el productID.
**Código actual:**
```dart
final isPremium = purchase.productID.contains('premium');
if (isPremium) {
  await _firestore.collection('users').doc(userId).update({
    'premium': true,
  });
}
```
**Fix:** Implementar verificación server-side con Cloud Functions.

### 1.2 Memory Leak - ETA Subscriptions en Custom Metro Map
**Archivo:** `lib/widgets/custom_metro_map.dart` (líneas ~180-200)
**Problema:** Las suscripciones ETA se almacenan en `_etaSubscriptions` pero nunca se cancelan en `dispose()`. Se acumulan con cada rebuild.
**Fix:**
```dart
for (var sub in _etaSubscriptions.values) {
  sub.cancel();
}
_etaSubscriptions.clear();
```

### 1.3 Race Condition en Auth Provider
**Archivo:** `lib/providers/auth_provider.dart` (líneas 36-43)
**Problema:** `ensureStreamInitialized()` usa `addPostFrameCallback` que difiere la inicialización. Si `currentUser` se accede antes del callback, retorna null aunque el usuario esté logueado.
**Fix:** Mover la inicialización crítica fuera del callback o agregar mecanismo de espera explícito.

### 1.4 Race Conditions en Gamification Service
**Archivo:** `lib/services/gamification_service.dart` (líneas 87-89)
**Problema:** Leer datos, verificar badge, y luego actualizar NO es atómico. Dos llamadas concurrentes podrían ambas creer que el badge no existe y duplicarlo.
**Fix:** Usar transacciones de Firestore para operaciones de lectura-verificación-escritura.

### 1.5 Notification Service - Listeners Nunca Cancelados
**Archivo:** `lib/services/notification_service.dart` (líneas 47, 50, 53)
**Problema:** 3 stream listeners creados pero nunca almacenados como `StreamSubscription` ni cancelados. Memory leak permanente.
```dart
_firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);        // Nunca cancelado
FirebaseMessaging.onMessage.listen(_handleForegroundMessage);     // Nunca cancelado
FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage); // Nunca cancelado
```

### 1.6 Debug Logs Públicos en Firestore Rules
**Archivo:** `firestore.rules` (línea 169)
**Problema:** `allow read: if true;` en debug_logs. Cualquier persona puede leer logs de debug que podrían contener información sensible.
**Fix:** Restringir a usuarios autenticados o eliminar en producción.

### 1.7 Firebase N+1 Query - Reportes por Ubicación
**Archivo:** `lib/services/firebase_service.dart` (líneas 143-166)
**Problema:** Descarga TODOS los reportes activos y luego filtra por distancia en memoria. Con miles de reportes, esto es costoso en lecturas de Firestore y lento.
**Fix:** Implementar geo-hashing o usar extensiones de geoqueries.

### 1.8 Points Reward Animation - Overlays Huérfanos
**Archivo:** `lib/widgets/points_reward_animation.dart`
**Problema:** Los métodos estáticos crean overlay entries sin rastrearlos. Múltiples taps rápidos podrían crear overlays huérfanos que nunca se limpian.

### 1.9 Pulsing Button - Timer y Stream sin Cleanup
**Archivo:** `lib/widgets/pulsing_button.dart`
**Problema:** StreamSubscription a 'reports' y Timer de debounce creados sin garantía de cancelación en `dispose()`.

### 1.10 Package Name Hardcodeado
**Archivo:** `lib/screens/settings/settings_screen.dart` (línea 326)
**Problema:** `'com.example.metropty'` hardcodeado. No funcionará en producción con nombre de paquete diferente.

---

## 2. PROBLEMAS ALTOS

### 2.1 293 Print Statements en Código de Producción
**Archivos más afectados:**

| Archivo | Cantidad |
|---------|----------|
| lib/main.dart | 32 |
| lib/services/gamification_service.dart | 22 |
| lib/services/station_update_service.dart | 22 |
| lib/services/simplified_report_service.dart | 20 |
| lib/services/report_validation_service.dart | 18 |
| lib/services/dev_service.dart | 15 |

**Riesgo:** Los logs son visibles via logcat (Android) y Console (iOS). Exponen lógica interna y posiblemente datos sensibles.
**Fix:** Reemplazar con servicio de logging propio o Firebase Crashlytics. Habilitar lint `avoid_print: true`.

### 2.2 Archivos Demasiado Grandes (Mantenibilidad)

| Archivo | Líneas | Recomendación |
|---------|--------|---------------|
| lib/screens/reports/report_history_screen.dart | ~1450 | Separar en componentes |
| lib/screens/home/home_screen.dart | ~1400 | Extraer widgets |
| lib/screens/home/map_widget.dart | ~1100 | Separar lógica de painter |
| lib/widgets/custom_metro_map.dart | ~2200+ | Dividir en capas |

### 2.3 SimulatedTimeService - Timer Post-Dispose
**Archivo:** `lib/services/simulated_time_service.dart` (líneas 57-68)
**Problema:** Timer.periodic puede ejecutar callback después de `dispose()`, accediendo a estado disposed.

### 2.4 Archivo Eliminado con Posibles Referencias
**Archivo:** `lib/screens/gamification/rankings_screen.dart` (eliminado en git)
**Problema:** El archivo está marcado como eliminado pero podría tener referencias de navegación en otros archivos.

### 2.5 DevService - Query de Limpieza Poco Confiable
**Archivo:** `lib/services/dev_service.dart` (líneas 360-394)
**Problema:** `where('usuario_id', isGreaterThan: 'dev_user_')` matchea ANY userId > 'dev_user_', incluyendo usuarios reales.

### 2.6 Custom Metro Map - Sin Error Boundary
**Archivo:** `lib/widgets/custom_metro_map.dart`
**Problema:** Si CustomPaint falla con datos corruptos, todo el mapa crashea sin fallback.

### 2.7 Train Sightings Sin TTL
**Archivo:** `lib/widgets/custom_metro_map.dart`
**Problema:** `_lastTrainSightings` acumula entries indefinidamente. Trenes que desaparecen nunca se limpian.

### 2.8 Auth Provider - Delete Account Incompleto
**Archivo:** `lib/providers/auth_provider.dart` (líneas 302-309)
**Problema:** Si falla la eliminación de imagen de perfil, el código continúa y puede eliminar la cuenta con imagen huérfana en Storage.

---

## 3. PROBLEMAS MEDIOS

### 3.1 Valores Hardcodeados que Deberían ser Configurables

| Archivo | Valor | Recomendación |
|---------|-------|---------------|
| `ad_session_service.dart` | `_maxInterstitialsPerDay = 3` | Firebase Remote Config |
| `schedule_service.dart` | Peak hours (6-9, 17-19) | Firestore para feriados |
| `time_estimation_service.dart` | `errorMarginMinutes = 2` | Data-driven |
| `accuracy_service.dart` | Pesos de confianza | Configurar desde backend |
| `level_service.dart` | Tabla de 50 niveles | Firebase Remote Config |
| `eta_validation_screen.dart` | Countdown 240 segundos | Configurable |
| `stats_screen.dart` | Max puntos = 1000 | Calcular de nivel/config |

### 3.2 Validaciones Faltantes

| Servicio | Problema |
|----------|----------|
| FirebaseService.createReport | Sin validación de stationId |
| ConfidenceService | No valida que reputación sea 0-100 |
| PointsRewardService | Puntos podrían ser negativos |
| SimplifiedReportService | Lista de issues podría tener duplicados |
| ReportModel | No valida que categoría sea válida para tipo |

### 3.3 Location Services - Excepciones No Capturadas
**Archivos:** `location_service.dart`, `background_location_service.dart`
**Problema:** `Geolocator.getCurrentPosition()` puede lanzar excepción que no se captura. Puede crashear la app.

### 3.4 Metro Data Provider - San Miguelito Hardcodeado
**Archivo:** `metro_data_provider.dart` (líneas 134-136)
**Problema:** Filtra estaciones 'l2_san_miguelito' y 'l2_san_miguelito_l1' hardcodeado en 3 lugares. Frágil.

### 3.5 Metro Data Provider - Sin Recuperación de Errores
**Problema:** Si Firebase streams fallan, cae a datos estáticos sin retry. Usuario atrapado con datos viejos.

### 3.6 Debounce de Metro Data Provider
**Problema:** Debounce solo para reportes de estación. Cambios simultáneos estación+tren bypasean el debounce.

### 3.7 Modelo de Reporte - Categoría/Tipo Sin Validación Cruzada
**Archivo:** `report_model.dart`
**Problema:** Podría aceptar reporte de "aglomeración" para un tren (combinación inválida).

### 3.8 Simplified Report Model - Scope Sin Validación
**Archivo:** `simplified_report_model.dart`
**Problema:** Acepta issueType sin validar contra tipos permitidos por scope.

### 3.9 Ad Service - Test IDs en Producción
**Archivo:** `lib/services/ad_service.dart` (líneas 14-24)
**Problema:** IDs de test que podrían no validar correctamente en producción.

### 3.10 Map Widget - Sin Error Handling en Inicialización
**Archivo:** `custom_map_screen.dart`
**Problema:** Si la inicialización del mapa falla, no hay catch ni fallback UI.

### 3.11 Custom Metro Map - Taps Sin Debounce
**Problema:** GestureDetectors superpuestos sin debounce. Taps rápidos podrían abrir múltiples diálogos.

### 3.12 Points Reward Listener - Deduplicación Defectuosa
**Archivo:** `points_reward_listener.dart`
**Problema:** Usa `Set<String>` para transacciones mostradas, pero reconexiones podrían entregar la misma transacción dos veces.

### 3.13 Image Upload Sin Validación de Tamaño
**Archivo:** `edit_profile_screen.dart`
**Problema:** Sin validación de tamaño de imagen antes de subir. Podría subir imágenes enormes.

### 3.14 Route Results - Sin Loading State
**Archivo:** `route_results.dart`
**Problema:** Sin indicador de carga mientras calcula la ruta. El usuario no sabe qué está pasando.

### 3.15 Admin Learning Service - Test Data Mezclada
**Archivo:** `admin_learning_service.dart`
**Problema:** Datos de test mezclados con user ID real (`simulated_${user.uid}`), difícil de limpiar.

---

## 4. SEGURIDAD

### 4.1 Firestore Rules - Análisis

| Colección | Lectura | Escritura | Evaluación |
|-----------|---------|-----------|------------|
| stations | Pública | Auth + condiciones | ✅ Aceptable (datos públicos) |
| trains | Pública | Auth + condiciones | ✅ Aceptable |
| routes | Pública | Auth | ✅ Aceptable |
| reports | Auth | Auth + validaciones | ✅ Bien implementado |
| users | Solo propietario | Solo propietario | ✅ Correcto |
| debug_logs | **Pública** | Auth | ❌ Debe restringirse |
| model_metrics | Auth | **Cualquier auth** | ⚠️ Restringir a admin |

### 4.2 Firebase Options en Version Control
**Archivo:** `lib/firebase_options.dart`
**Estado:** API keys expuestas en git. Aunque las API keys de Firebase son "públicas" por diseño, deben estar restringidas en Firebase Console a dominios/apps autorizados.

### 4.3 Auth Checks Faltantes en Código

| Método | Problema |
|--------|----------|
| `confirmReport()` | Valida que user existe pero no ownership |
| `deleteUserData()` | No verifica que requesting user = target user |

---

## 5. TESTING

### Estado Actual: SIN TESTS ACTIVOS

**Archivo:** `test/widget_test.dart` - Único test, comentado:
```dart
void main() {
  // TODO: Configurar Firebase para tests
  // testWidgets('App smoke test', ...);
}
```

**Recomendación:** Configurar Firebase Emulator para tests y crear suite mínima:
- Tests unitarios para servicios (ConfidenceService, LevelService, etc.)
- Tests de widget para componentes principales
- Tests de integración para flujos críticos (login, reportes)

---

## 6. CONFIGURACIÓN Y LINT

### analysis_options.yaml
**Problema:** `avoid_print: false` - Deshabilitado explícitamente.
**Fix:** Cambiar a `true` y migrar a logging service.

### Dependencias (pubspec.yaml)
**Estado:** Todas actualizadas (versiones 2024-2025). Sin paquetes deprecados detectados.

---

## 7. TEMA Y UI

### metro_theme.dart
**Estado:** Bien implementado. Material 3, Google Fonts (Inter/Montserrat), soporte dark mode.
**Sin problemas encontrados.**

### Problemas de UI Generales

| Problema | Pantallas afectadas |
|----------|---------------------|
| Sin loading states | route_results, varios widgets |
| Sin empty states | Varias listas |
| Strings hardcodeados (español) | Toda la app (sin i18n) |
| Emojis como iconos | badges_data, admin panels |
| Colores hardcodeados | custom_metro_map (hex inline) |

---

## 8. MEMORY LEAKS - RESUMEN

| Componente | Tipo | Estado |
|------------|------|--------|
| NotificationService | 3 StreamSubscription | ❌ Nunca cancelados |
| Custom Metro Map | ETA Subscriptions | ❌ Nunca cancelados |
| Custom Metro Map | Train Sightings Map | ❌ Crece sin límite |
| Points Reward Animation | Overlay Entries | ❌ No rastreados |
| Pulsing Button | Timer + Stream | ❌ Sin cleanup garantizado |
| SimulatedTimeService | Timer | ✅ Properly disposed |
| SubscriptionService | StreamSubscription | ✅ Properly disposed |
| BackgroundLocationService | StreamSubscription | ✅ Properly disposed |
| TrainSimulationService | Maps | ✅ Cleared in dispose |

---

## 9. DEAD CODE Y TODOs

### TODOs Pendientes

| Archivo | TODO |
|---------|------|
| notification_service.dart:125 | Manejar solicitudes de confirmación |
| notification_service.dart:128 | Manejar logros desbloqueados |
| notification_service.dart:131 | Manejar alertas de estación |
| profile_badges_preview.dart:75 | Navegar a pantalla completa de badges |
| functions/index.js:725 | Mejorar cuando tengamos trainId |
| functions/index.js:1241 | Mejorar asociación tren-estación |

### Dead Code
- `SimplifiedReportService.pickImageWithSourceChoice()` - Siempre retorna null
- `AppModeService` - Solo usa 'development', nunca cambia
- `TrainSimulationService.start()/stop()` - Métodos vacíos

---

## 10. PRIORIDADES DE CORRECCIÓN

### Sprint Inmediato (Críticos)
1. ✅ Verificación server-side de compras in-app
2. ✅ Cancelar ETA subscriptions en custom_metro_map dispose()
3. ✅ Fix race condition en auth_provider
4. ✅ Cancelar listeners en notification_service
5. ✅ Restringir debug_logs en Firestore rules

### Sprint Siguiente (Altos)
1. Reemplazar 293 print() con logging service
2. Refactorizar archivos >1000 líneas
3. Fix timer post-dispose en SimulatedTimeService
4. Verificar referencias al rankings_screen.dart eliminado
5. Fix query de limpieza en dev_service

### Backlog (Medios)
1. Mover valores hardcodeados a Firebase Remote Config
2. Agregar validaciones de modelos
3. Implementar error recovery en metro_data_provider
4. Agregar loading/empty states faltantes
5. Setup test suite con Firebase Emulator
6. Implementar geoqueries para reportes por ubicación

### Nice to Have (Bajos)
1. Internacionalización (i18n)
2. Reemplazar emojis con iconos Material
3. Centralizar extensiones de color
4. Documentar TODOs en issue tracker

---

## 11. ARQUITECTURA GENERAL

```
lib/
├── main.dart              # Entry point, providers, routing
├── data/                  # Datos estáticos (badges, simulación)
├── models/                # 12 modelos de datos
├── providers/             # 4 providers (auth, metro_data, location, report)
├── screens/               # 26 pantallas en 12 carpetas
│   ├── admin/             # Paneles de administración/testing
│   ├── auth/              # Login
│   ├── gamification/      # Stats, puntos
│   ├── home/              # Home, mapa
│   ├── leaderboards/      # Rankings
│   ├── learning/          # Leaderboard de teachers
│   ├── legal/             # Privacidad, términos
│   ├── onboarding/        # Onboarding
│   ├── premium/           # Suscripción premium
│   ├── profile/           # Perfil, achievements
│   ├── reports/           # Reportes, historial, ETA
│   ├── routes/            # Planificador de rutas
│   └── settings/          # Configuración, notificaciones
├── services/              # 43 servicios
├── theme/                 # Tema Material 3
├── utils/                 # Constantes, helpers, metro data
└── widgets/               # 25+ widgets reutilizables
    ├── admin/             # Widgets de admin
    └── dev/               # Herramientas de desarrollo
```

**Patrón:** Provider + Services (no BLoC ni Riverpod)
**Backend:** Firebase (Firestore, Auth, Storage, Messaging, Functions)
**Monetización:** Google Ads + In-App Purchases
**Mapa:** Google Maps + Custom Metro Map (Canvas)

---

*Documento generado por análisis automatizado de 140 archivos Dart.*
