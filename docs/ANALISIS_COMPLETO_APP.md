# Análisis Completo - MetroPTY App
**Fecha análisis:** 3 de marzo de 2026
**Última actualización:** 4 de marzo de 2026
**Archivos analizados:** 140 archivos Dart + Cloud Functions + Config
**Alcance:** Servicios, Pantallas, Modelos, Widgets, Utils, Providers, Tema, Seguridad

---

## Estado General

| Severidad | Total | ✅ Corregidos | ⏳ Pendientes |
|-----------|-------|--------------|--------------|
| **CRÍTICO** | 10 | **10** | 0 |
| **ALTO** | 13 | 0 | 13 |
| **MEDIO** | 47 | 0 | 47 |
| **BAJO** | 41 | 0 | 41 |

---

## SECCIÓN 1: PROBLEMAS CRÍTICOS

### ✅ 1.1 Compras In-App sin Verificación del Servidor
**Archivo:** `lib/services/subscription_service.dart`
**Problema:** La compra se activaba directamente en Firestore sin verificar con un backend. Un usuario podría fabricar el status premium manipulando el productID.
**Código problemático:**
```dart
final isPremium = purchase.productID.contains('premium');
if (isPremium) {
  await _firestore.collection('users').doc(userId).update({'premium': true});
}
```
**Fix aplicado (04/03/2026):** Servicio completamente deshabilitado con stub hasta que se implemente verificación server-side. El servicio retorna `isAvailable = false` y todos los métodos son no-ops.
**Deuda técnica:** Cuando se reactive, requiere Cloud Function que verifique el recibo con Google Play / App Store antes de actualizar Firestore.

---

### ✅ 1.2 Memory Leak - ETA Subscriptions en Custom Metro Map
**Archivo:** `lib/widgets/custom_metro_map.dart`
**Análisis:** El agente reportó que las suscripciones ETA nunca se cancelaban en `dispose()`. Al verificar el código, el `dispose()` SÍ las cancela correctamente:
```dart
@override
void dispose() {
  _trainSightingsSub?.cancel();
  for (final sub in _etaSubscriptions.values) {
    sub.cancel();
  }
  _etaSubscriptions.clear();
  // ...
}
```
**Estado:** Sin acción requerida. Falso positivo del análisis automatizado.

---

### ✅ 1.3 Race Condition en Auth Provider
**Archivo:** `lib/providers/auth_provider.dart` (línea 36)
**Problema:** `ensureStreamInitialized()` difería toda la inicialización con `addPostFrameCallback`. Si `currentUser` era accedido en el primer frame, retornaba `null` aunque el usuario estuviera logueado, causando un flash de pantalla de login.
**Fix aplicado (04/03/2026):** Chequeo síncrono de Firebase Auth antes del callback. Si hay usuario, se establece `_isLoading = true` inmediatamente para señalizar "hay usuario, aún cargando":
```dart
void ensureStreamInitialized() {
  if (_streamInitialized) return;
  _streamInitialized = true;

  // Prevenir flash de "no autenticado": si hay usuario en Firebase, marcar loading
  if (_firebaseService.getCurrentUser() != null) {
    _isLoading = true;
  }

  SchedulerBinding.instance.addPostFrameCallback((_) {
    _init();
  });
}
```

---

### ✅ 1.4 Race Condition - Badges Duplicados en Gamification
**Archivo:** `lib/services/gamification_service.dart` (línea 224)
**Problema:** `_awardBadge()` hacía read → check → write de forma no atómica. Dos llamadas concurrentes podían ambas pasar el check y duplicar el badge.
**Fix aplicado (04/03/2026):** Migrado a `runTransaction` de Firestore:
```dart
await _firestore.runTransaction((transaction) async {
  final userDoc = await transaction.get(userRef);
  final currentBadges = List<dynamic>.from(gamification?['badges'] ?? []);
  final hasBadge = currentBadges.any((b) => b['type'] == badgeType.toString());
  if (hasBadge) return; // Transacción atómica: safe
  currentBadges.add(badge.toFirestore());
  transaction.update(userRef, {'gamification.badges': currentBadges});
});
```

---

### ✅ 1.5 Notification Service - Listeners Nunca Cancelados
**Archivo:** `lib/services/notification_service.dart` (líneas 47-53)
**Problema:** 3 stream listeners de FCM creados pero nunca almacenados ni cancelados. Memory leak permanente, los listeners se acumulaban si `initialize()` era llamado varias veces.
**Fix aplicado (04/03/2026):** Añadidos 3 campos `StreamSubscription` y método `dispose()`:
```dart
StreamSubscription<String>? _tokenRefreshSubscription;
StreamSubscription<RemoteMessage>? _foregroundSubscription;
StreamSubscription<RemoteMessage>? _backgroundSubscription;

void dispose() {
  _tokenRefreshSubscription?.cancel();
  _foregroundSubscription?.cancel();
  _backgroundSubscription?.cancel();
}
```

---

### ✅ 1.6 Debug Logs Públicos en Firestore Rules
**Archivo:** `firestore.rules` (línea 169)
**Problema:** `allow read: if true;` en la colección `debug_logs`. Cualquier persona sin autenticar podía leer todos los logs de debug, exponiendo potencialmente información sensible del sistema.
**Fix aplicado (04/03/2026):**
```
// Antes:
allow read: if true;

// Después:
allow read: if request.auth != null;
```

---

### ✅ 1.7 N+1 Query - Reportes por Ubicación
**Archivo:** `lib/services/firebase_service.dart` (línea 143)
**Problema:** `getReportsByLocation()` descargaba TODOS los reportes activos de Firestore y filtraba por distancia en memoria. Con miles de reportes, esto era costoso en lecturas y lento.
**Fix aplicado (04/03/2026):** Añadido filtro temporal (últimas 24h) y límite de documentos:
```dart
final cutoff = DateTime.now().subtract(const Duration(hours: 24));

final snapshot = await _firestore
    .collection('reports')
    .where('estado', isEqualTo: 'activo')
    .where('creado_en', isGreaterThan: Timestamp.fromDate(cutoff))
    .orderBy('creado_en', descending: true)
    .limit(300)  // Máximo 300 docs en lugar de todos
    .get();
```
**Deuda técnica:** La solución óptima es geohashing. Requiere almacenar lat/lng como campos numéricos separados y migrar datos existentes. Documentado con TODO en el código.

---

### ✅ 1.8 Overlays Huérfanos - Points Reward Animation
**Archivo:** `lib/widgets/points_reward_animation.dart`
**Problema:** El método estático `show()` creaba un `OverlayEntry` cada vez que se llamaba sin rastrear el anterior. Taps rápidos podían apilar múltiples overlays que nunca se limpiaban.
**Fix aplicado (04/03/2026):** Añadido tracker estático `_activeOverlay`. Cada llamada reemplaza el overlay anterior:
```dart
static OverlayEntry? _activeOverlay;

static OverlayEntry? show(...) {
  // Remover overlay anterior si sigue activo
  if (_activeOverlay != null && _activeOverlay!.mounted) {
    _activeOverlay!.remove();
  }
  // ... crear nuevo overlay
  _activeOverlay = overlayEntry;
}
```

---

### ✅ 1.9 Pulsing Button - Timer y Stream sin Cleanup
**Archivo:** `lib/widgets/pulsing_button.dart`
**Análisis:** El agente reportó que el Timer y el StreamSubscription no tenían cleanup garantizado. Al revisar el código, `dispose()` los cancela correctamente:
```dart
@override
void dispose() {
  _subscription?.cancel();
  _pulseTimer?.cancel();
  _pulseController.dispose();
  super.dispose();
}
```
**Estado:** Sin acción requerida. Falso positivo del análisis automatizado.

---

### ✅ 1.10 Package Name Hardcodeado en Settings
**Archivo:** `lib/screens/settings/settings_screen.dart` (línea 326)
**Problema:** `'com.example.metropty'` hardcodeado para abrir settings de Android. En producción con un package name diferente, esto no abría la pantalla correcta.
**Fix aplicado (04/03/2026):** Reemplazado por `AppSettings.openAppSettings()` del paquete `app_settings` (ya en pubspec.yaml). Funciona en Android e iOS sin hardcodear nada:
```dart
// Antes: Platform.isAndroid → Uri('package:com.example.metropty') + url_launcher
// Después:
await AppSettings.openAppSettings();
```
También se eliminaron los imports innecesarios de `dart:io` y `url_launcher`.

---

## SECCIÓN 2: PROBLEMAS ALTOS (Pendientes)

### 2.1 293 Print Statements en Producción
**Archivos más afectados:** `main.dart` (32), `gamification_service.dart` (22), `station_update_service.dart` (22), `simplified_report_service.dart` (20)
**Riesgo:** Exposición de lógica interna y datos via logcat/Console en dispositivos.
**Fix recomendado:** Crear `AppLogger` wrapper y reemplazar todos los `print()`. Habilitar `avoid_print: true` en `analysis_options.yaml`.
**Esfuerzo:** Alto (búsqueda y reemplazo sistemático en 30+ archivos).

### 2.2 Archivos Demasiado Grandes

| Archivo | Líneas | Acción |
|---------|--------|--------|
| `screens/reports/report_history_screen.dart` | ~1450 | Separar en widgets |
| `screens/home/home_screen.dart` | ~1400 | Extraer componentes |
| `screens/home/map_widget.dart` | ~1100 | Separar lógica de painter |
| `widgets/custom_metro_map.dart` | ~2200 | Dividir en capas |

### 2.3 Timer Post-Dispose en SimulatedTimeService
**Análisis:** Reportado como crítico pero el `dispose()` llama `stop()` que cancela el timer antes de que pueda ejecutar. Dart es single-threaded, no hay riesgo real. **Falso positivo.**

### 2.4 Rankings Screen Eliminado
**Archivo:** `lib/screens/gamification/rankings_screen.dart` (eliminado en git)
**Acción:** Verificar que ningún archivo tenga navegación a esta pantalla.
```bash
grep -r "rankings" lib/ --include="*.dart"
```

### 2.5 DevService - Query de Limpieza Peligrosa
**Archivo:** `lib/services/dev_service.dart` (líneas 360-394)
**Problema:** `where('usuario_id', isGreaterThan: 'dev_user_')` puede matchear usuarios reales.
**Fix:** Usar prefijo único para test data y query exacta.

### 2.6 Custom Metro Map - Sin Error Boundary
**Archivo:** `lib/widgets/custom_metro_map.dart`
**Problema:** Si CustomPaint falla con datos corruptos, todo el mapa crashea.
**Fix:** Wrap del painter en try-catch con UI de fallback.

### 2.7 Auth Provider - Delete Account Puede Dejar Imágenes Huérfanas
**Archivo:** `lib/providers/auth_provider.dart` (líneas 302-309)
**Problema:** Si falla la eliminación de imagen, la cuenta se elimina igualmente dejando la imagen en Storage.

### 2.8 Model Metrics - Write sin Restricción
**Archivo:** `firestore.rules`
**Problema:** `allow write: if request.auth != null;` — cualquier usuario autenticado puede escribir métricas.
**Fix:** Restringir a rol admin.

### 2.9 Auth Provider - DeleteAccount + StreamSubscription
**Archivo:** `lib/providers/auth_provider.dart`
**Problema:** `_userStreamSubscription?.cancel()` no usa `await`, la suscripción puede no cancelarse completamente.

### 2.10 Metro Data Provider - Sin Recuperación de Errores
**Problema:** Si Firebase streams fallan, cae a datos estáticos sin retry.

### 2.11 GestureDetectors Sin Debounce en Custom Metro Map
**Problema:** Taps rápidos pueden abrir múltiples diálogos simultáneos.

### 2.12 Points Reward Listener - Deduplicación Defectuosa
**Archivo:** `lib/widgets/points_reward_listener.dart`
**Problema:** Reconexiones pueden duplicar la misma animación de puntos.

### 2.13 Image Upload Sin Validación de Tamaño
**Archivo:** `lib/screens/profile/edit_profile_screen.dart`

---

## SECCIÓN 3: PROBLEMAS MEDIOS (Pendientes)

### 3.1 Valores Hardcodeados que Deberían ser Configurables

| Archivo | Valor | Recomendación |
|---------|-------|---------------|
| `ad_session_service.dart` | `_maxInterstitialsPerDay = 3` | Firebase Remote Config |
| `schedule_service.dart` | Peak hours (6-9, 17-19) | Firestore para feriados |
| `time_estimation_service.dart` | `errorMarginMinutes = 2` | Data-driven |
| `accuracy_service.dart` | Pesos de confianza | Configurable desde backend |
| `level_service.dart` | Tabla de 50 niveles | Firebase Remote Config |
| `eta_validation_screen.dart` | Countdown 240 segundos | Configurable |
| `stats_screen.dart` + `report_summary_screen.dart` | Max puntos = 1000 | Calcular de nivel/config |

### 3.2 Validaciones Faltantes

| Servicio/Modelo | Problema |
|-----------------|----------|
| `FirebaseService.createReport` | Sin validación de stationId existente |
| `ConfidenceService` | No valida reputación en rango 0-100 |
| `PointsRewardService` | Puntos podrían ser negativos |
| `ReportModel` | No valida que categoría sea válida para tipo (estacion/tren) |
| `SimplifiedReportModel` | issueType no validado contra scope |

### 3.3 Location Services - Excepciones No Capturadas
**Archivos:** `location_service.dart`, `background_location_service.dart`
**Problema:** `Geolocator.getCurrentPosition()` puede lanzar excepción sin capturar. Puede crashear la app.

### 3.4 Metro Data Provider - San Miguelito Hardcodeado
**Problema:** IDs de estación filtrados en 3 lugares hardcodeados. Agregar comentario explicativo + flag de configuración.

### 3.5 Debounce de Metro Data Provider Incompleto
**Problema:** Solo aplica a reportes de estación, no a cambios combinados estación+tren.

### 3.6 Route Results - Sin Loading State
**Problema:** Sin indicador de carga mientras calcula la ruta.

### 3.7 Admin Learning Service - Test Data Mezclada
**Problema:** Datos de test usan `simulated_${user.uid}`, mezclando IDs reales.

### 3.8 Ad Service - Gestión de Test IDs
**Archivo:** `lib/services/ad_service.dart`
**Problema:** Verificar que IDs de test no lleguen a producción.

### 3.9 FirebaseService - N+1 Queries Adicionales
**Método:** `getLineaLeaderboardStream()` obtiene top 100 y filtra en memoria.

---

## SECCIÓN 4: SEGURIDAD

### Firestore Rules - Estado Actual

| Colección | Lectura | Escritura | Estado |
|-----------|---------|-----------|--------|
| stations | Pública | Auth + cond. | ✅ OK (datos públicos) |
| trains | Pública | Auth + cond. | ✅ OK |
| routes | Pública | Solo Cloud Fn | ✅ OK |
| reports | Auth | Auth + validaciones | ✅ Bien implementado |
| users | Solo propietario | Solo propietario | ✅ Correcto |
| debug_logs | ~~Pública~~ → **Auth** | Auth | ✅ **CORREGIDO** |
| model_metrics | Auth | Cualquier auth | ⚠️ Restringir a admin |
| learning_reports | Auth | Auth + owner check | ✅ OK |
| eta_groups | Auth | Solo Cloud Fn | ✅ OK |

### Firebase Options en VCS
`lib/firebase_options.dart` contiene API keys. Son "públicas por diseño" en Firebase, pero deben estar restringidas en Firebase Console / Google Cloud Console a dominios y apps autorizadas.

---

## SECCIÓN 5: TESTING

**Estado: SIN TESTS ACTIVOS**

`test/widget_test.dart` tiene el único test comentado. Para activar:
1. Configurar Firebase Emulator Suite
2. Usar `firebase_app_check` en modo debug
3. Crear tests unitarios para: `ConfidenceService`, `LevelService`, `AccuracyService`
4. Crear widget tests para flujos críticos: login, crear reporte, confirmar reporte

---

## SECCIÓN 6: CONFIGURACIÓN

### analysis_options.yaml
```yaml
# Estado actual - PROBLEMA
avoid_print: false  # Permite 293 print() en producción

# Fix recomendado
avoid_print: true
```

### Dependencias (pubspec.yaml)
Estado: Todas actualizadas (versiones 2024-2025). Sin paquetes deprecados.

---

## SECCIÓN 7: ARQUITECTURA

```
lib/
├── main.dart              # Entry point, providers, routing (32 prints)
├── data/                  # Datos estáticos (badges, simulación)
├── models/                # 12 modelos de datos
├── providers/             # 4 providers (auth, metro_data, location, report)
├── screens/               # 26 pantallas en 12 carpetas
│   ├── admin/             # Paneles de testing (solo modo dev)
│   ├── auth/              # Login
│   ├── gamification/      # Stats, puntos
│   ├── home/              # Home, mapa (~1400 líneas)
│   ├── leaderboards/      # Rankings
│   ├── learning/          # Leaderboard de teachers
│   ├── legal/             # Privacidad, términos
│   ├── onboarding/        # Onboarding
│   ├── premium/           # Suscripción (DESHABILITADA)
│   ├── profile/           # Perfil, achievements
│   ├── reports/           # Reportes, historial (~1450 líneas), ETA
│   ├── routes/            # Planificador de rutas
│   └── settings/          # Configuración, notificaciones
├── services/              # 43 servicios
├── theme/                 # Tema Material 3 (bien implementado)
├── utils/                 # Constantes, helpers, metro data
└── widgets/               # 25+ widgets reutilizables
    ├── admin/             # Widgets de admin
    └── dev/               # Herramientas de desarrollo (solo modo dev)
```

**Patrón:** Provider + Services
**Backend:** Firebase (Firestore, Auth, Storage, Messaging, Functions)
**Monetización:** Google Ads (activo) + In-App Purchases (DESHABILITADO)
**Mapa:** Google Maps + Custom Metro Map (Canvas, ~2200 líneas)

---

## SECCIÓN 8: MEMORY LEAKS - ESTADO FINAL

| Componente | Tipo | Estado |
|------------|------|--------|
| NotificationService | 3 StreamSubscription | ✅ **CORREGIDO** |
| Custom Metro Map ETA | StreamSubscription Map | ✅ Ya estaba correcto |
| Points Reward Animation | Overlay Entries | ✅ **CORREGIDO** |
| Pulsing Button | Timer + Stream | ✅ Ya estaba correcto |
| SimulatedTimeService | Timer | ✅ Correcto (Dart single-thread) |
| SubscriptionService | StreamSubscription | ✅ **DESHABILITADO** |
| BackgroundLocationService | StreamSubscription | ✅ Correcto |
| TrainSimulationService | Maps | ✅ Correcto |

---

## SECCIÓN 9: REGISTRO DE CAMBIOS

### 04/03/2026 - Sprint Críticos
| # | Archivo | Cambio |
|---|---------|--------|
| 1 | `subscription_service.dart` | Servicio deshabilitado completamente (stub) |
| 2 | `notification_service.dart` | Añadidos 3 `StreamSubscription` + `dispose()` |
| 3 | `gamification_service.dart` | `_awardBadge()` usa `runTransaction` |
| 4 | `points_reward_animation.dart` | Static `_activeOverlay` tracker |
| 5 | `settings_screen.dart` | `AppSettings.openAppSettings()` reemplaza hardcode |
| 6 | `firestore.rules` | `debug_logs` restringido a `auth != null` |
| 7 | `auth_provider.dart` | Check síncrono de Firebase user en `ensureStreamInitialized` |
| 8 | `firebase_service.dart` | `getReportsByLocation` con filtro temporal + limit(300) |
| 9 | `docs/ANALISIS_COMPLETO_APP.md` | Documento de análisis creado |

### Commits relacionados
- `ba98944` - Fix critical issues: disable subscription, fix memory leaks and race conditions
- `cfffca6` - UI improvements, remove rankings screen, add full app analysis doc

---

## SECCIÓN 10: PRÓXIMOS PASOS RECOMENDADOS

### Sprint siguiente (Altos)
1. Reemplazar 293 `print()` con servicio de logging (`AppLogger`)
2. Habilitar `avoid_print: true` en `analysis_options.yaml`
3. Refactorizar `home_screen.dart` y `report_history_screen.dart`
4. Verificar referencias al `rankings_screen.dart` eliminado
5. Añadir error boundary al custom metro map painter
6. Fix `getLineaLeaderboardStream()` - filtra en servidor no en memoria

### Backlog (Medios)
1. Mover valores hardcodeados a Firebase Remote Config
2. Añadir validaciones de modelos (categoría/tipo en ReportModel)
3. Error recovery en `metro_data_provider` (retry en fallos de stream)
4. Loading state en `route_results.dart`
5. Validación de tamaño de imagen en upload de perfil
6. Setup test suite con Firebase Emulator

### Deuda técnica documentada
- **Geohashing** en `getReportsByLocation` - requiere migración de datos
- **Verificación server-side de compras** - requiere Cloud Function antes de reactivar subscription
- **Restricción de `model_metrics`** a rol admin en Firestore Rules

---

*Análisis realizado con 4 agentes en paralelo sobre 140 archivos Dart.*
*Falsos positivos identificados: ETA subscriptions (#1.2), Pulsing button (#1.9), SimulatedTimeService timer (#2.3) — todos verificados manualmente.*
