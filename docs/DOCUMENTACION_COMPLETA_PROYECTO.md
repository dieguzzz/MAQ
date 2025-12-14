# 📚 Documentación Completa del Proyecto MetroPTY

**Versión:** 1.0 | **Fecha:** 2025-12-14

---

## 📋 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Contrato de Nombres (Fuente de verdad)](#contrato-de-nombres-fuente-de-verdad)
3. [Reglas de Prioridad (Source of Truth)](#reglas-de-prioridad-source-of-truth)
4. [Autenticación (MVP vs Producción)](#autenticación-mvp-vs-producción)
5. [Parámetros del sistema (tuning)](#parámetros-del-sistema-tuning)
6. [Reglas Firestore (mínimo)](#reglas-firestore-mínimo)
7. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
8. [Modelos de Datos](#modelos-de-datos)
9. [Servicios Principales](#servicios-principales)
10. [Flujos de Trabajo](#flujos-de-trabajo)
11. [Funcionalidades Implementadas](#funcionalidades-implementadas)
12. [Gamificación](#gamificación)
13. [Sistema de Reportes](#sistema-de-reportes)
14. [Mapas y Visualización](#mapas-y-visualización)
15. [Notificaciones](#notificaciones)
16. [Monetización (Ads)](#monetización-ads)
17. [Cloud Functions](#cloud-functions)
18. [Estructura de Archivos](#estructura-de-archivos)
19. [Resumen de Estado](#resumen-de-estado)
20. [Configuración Requerida](#configuración-requerida)
21. [Notas Finales](#notas-finales)

---

## 1. Visión General

### ¿Qué es MetroPTY?

MetroPTY es una aplicación móvil colaborativa (tipo Waze) que permite a los usuarios conocer el estado en tiempo real del Metro de Panamá mediante reportes de la comunidad. La app muestra un mapa interactivo con estaciones, líneas y trenes virtuales que se actualizan en tiempo real.

### Objetivo Principal

Proporcionar información precisa y actualizada sobre:
- Estado de las estaciones (normal, moderado, lleno, cerrado)
- Estado de los trenes (ocupación, retrasos, incidencias)
- Tiempos estimados de llegada (ETAs)
- Alertas y notificaciones de incidencias

### Stack Tecnológico

| Componente | Tecnología |
|------------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Firebase (Firestore, Auth, Cloud Functions, FCM) |
| **Mapas** | Google Maps SDK + Custom Overlays |
| **Estado** | Provider (State Management) |
| **Ads** | Google AdMob |
| **Notificaciones** | Firebase Cloud Messaging (FCM) |

---

## 2. Contrato de Nombres (Fuente de verdad)

Para asegurar la coherencia en todo el proyecto y evitar inconsistencias, se establece el siguiente contrato de nombres:

### Colecciones Firestore

- `users/{uid}`
- `stations/{stationId}`
- `reports/{reportId}`
- `trains/{trainId}` (Actualmente en uso. Según el documento MVP se recomienda `train_state/{trainId}`, pero el código actual utiliza `trains/`)
- `user_signals/{uid}` (Colección pendiente de implementación para tracking de ubicación con TTL 2-5 minutos, para agregación)

> **Nota:** Si existe `trains/{trainId}`, se debe decidir si se elimina o se convierte en alias de `train_state`. Actualmente el proyecto utiliza `trains/` en todo el código.

### Normalización de campos clave (actualmente en código)

- `linea`: 'linea1' | 'linea2' (se utiliza en código Flutter y Firestore. Según MVP se recomienda 'L1' | 'L2', pero el código actual usa 'linea1'/'linea2')
- `direccion`: 'norte' | 'sur' (se utiliza en código Flutter para trenes. Según MVP se recomienda 'A' | 'B', pero el código actual usa 'norte'/'sur')
- `station.estadoActual`: 'normal'|'moderado'|'lleno'|'cerrado' (se debe considerar añadir 'retraso' y 'unknown' si se implementan los ETAs y confianza del MVP)
- `train.estado`: 'normal'|'retrasado'|'detenido' (se utiliza en código Flutter. Según MVP se recomienda 'moving'|'slow'|'stopped', pero el código actual usa 'normal'/'retrasado'/'detenido')

---

## 3. Reglas de Prioridad (Source of Truth)

Para mantener la consistencia del estado de estaciones y trenes, se establecen las siguientes reglas de prioridad para las actualizaciones:

1. **Reportes `community_verified`**: Tienen la máxima prioridad para actualizar `station.estadoActual` y `station.aglomeracion` (crowdLevel).

2. **Señales automáticas (`user_signals`)**: Una vez implementadas, se usarán para:
   - `trains.velocidad` (speedKmh)
   - `trains.estado` (status: 'moving'|'slow'|'stopped')
   - `etaMinutes` (ETA del próximo tren a la estación, si no hay reportes verificados recientes para ese dato).

3. **Conflictos de información**:
   - Si hay un conflicto entre un reporte `community_verified` y una señal automática en el "estado" de una estación/tren, el **reporte verificado manda**.
   - Las señales automáticas siempre mandarán en "velocidad" y "ETA" si están disponibles y son más recientes.

---

## 4. Autenticación (MVP vs Producción)

Para la gestión de usuarios, se considera la siguiente estrategia:

- **MVP:** Se permite la autenticación anónima para reducir la fricción de entrada y facilitar las pruebas iniciales. Esto permite a los usuarios reportar sin la necesidad inmediata de crear una cuenta completa.

- **Producción:** Se recomienda la autenticación mediante Email/Password o Google Sign-In (ya implementados) para mejorar la robustez del sistema, permitir la gestión de reputación a largo plazo y facilitar la implementación de medidas anti-abuso.

---

## 5. Parámetros del sistema (tuning)

Los siguientes parámetros controlan el comportamiento del sistema y deben ser configurables, idealmente desde un sistema de gestión remoto (como Firebase Remote Config) o en las Cloud Functions:

- `signalTTLMinutes = 3`: Tiempo de vida de los `user_signals` en minutos antes de ser considerados obsoletos.
- `reportDuplicateWindowMinutes = 5`: Período en minutos durante el cual no se permiten reportes duplicados del mismo tipo y objetivo por el mismo usuario.
- `reportResolveMinutes = 25`: Tiempo en minutos después del cual un reporte `activo` sin nuevas confirmaciones se considera `resolved` automáticamente.
- `communityVerifyThreshold = 3`: Número de confirmaciones necesarias para que un reporte pase a ser `community_verified`.
- `criticalRadiusKm = 5`: Radio en kilómetros para enviar notificaciones de alertas a usuarios cercanos.
- `trainCronIntervalSeconds = 60`: Intervalo en segundos de ejecución de las Cloud Functions programadas para la agregación de señales y actualización de trenes.

---

## 6. Reglas Firestore (mínimo)

Las reglas de seguridad de Firestore son fundamentales para proteger los datos. A continuación se presentan las reglas mínimas recomendadas, alineadas con el MVP:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Colección de Usuarios
    match /users/{userId} {
      allow read: if request.auth != null; // Usuarios autenticados pueden leer
      allow write: if request.auth != null && request.auth.uid == userId; // Solo el propio usuario puede escribir/actualizar su perfil
      allow create: if request.auth != null && request.auth.uid == userId; // Solo el propio usuario puede crear su perfil
      allow update: if request.auth != null && request.auth.uid == userId; // Solo el propio usuario puede actualizar su perfil
      allow delete: if false; // No permitir eliminar usuarios directamente
    }

    // Colección de Estaciones
    match /stations/{stationId} {
      allow read: if true; // Todos pueden leer
      // Escritura permitida solo si el documento no existe (inicialización) o desde Cloud Functions (admin)
      allow write: if !exists(/databases/$(database)/documents/stations/$(stationId)) || request.auth.uid == 'admin_functions';
      allow delete: if false; // No permitir eliminar estaciones
    }

    // Colección de Trenes (actualmente `trains`, en el MVP `train_state`)
    match /trains/{trainId} {
      allow read: if true; // Todos pueden leer
      // Escritura permitida solo si el documento no existe (inicialización) o desde Cloud Functions (admin)
      allow write: if !exists(/databases/$(database)/documents/trains/$(trainId)) || request.auth.uid == 'admin_functions';
      allow delete: if false; // No permitir eliminar trenes
    }

    // Colección de Reportes
    match /reports/{reportId} {
      allow read: if request.auth != null; // Usuarios autenticados pueden leer
      allow create: if request.auth != null && request.resource.data.usuario_id == request.auth.uid; // Solo el creador puede crear
      allow update: if request.auth != null
        && (resource.data.usuario_id == request.auth.uid // El creador puede actualizar algunos campos
            || request.resource.data.diff(resource.data).affectedKeys()
                .hasOnly(['confirmation_count', 'verification_status', 'confidence', 'estado'])); // Permitir actualizaciones de confirmaciones y estado por el sistema/otros usuarios
      allow delete: if false; // No permitir eliminar reportes directamente

      // Subcolección de Confirmaciones para Reportes
      match /confirmations/{userId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null
          && request.auth.uid == userId
          && !exists(/databases/$(database)/documents/reports/$(reportId)/confirmations/$(userId)); // Solo crear si no existe y es el propio usuario
        allow update: if false; // No permitir actualizar confirmaciones
        allow delete: if false; // No permitir eliminar confirmaciones
      }
    }

    // Colección user_signals (pendiente de implementación)
    match /user_signals/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid; // Solo el propio usuario puede leer
      allow write: if request.auth != null && request.auth.uid == uid; // Solo el propio usuario puede escribir
      allow delete: if request.auth != null && request.auth.uid == uid; // Permitir eliminar por el propio usuario o TTL
    }

    // Otras colecciones (ej. routes, learning_reports, model_metrics)
    match /{collection}/{document} {
      allow read: if request.auth != null; // Por defecto, autenticados pueden leer
      // Las escrituras deben ser restringidas a Cloud Functions o admins explícitamente.
      // Ej: allow write: if request.auth.uid == 'admin_functions';
    }
  }
}
```

> **Nota:** Las reglas actuales del proyecto (`firestore.rules`) permiten escritura de usuarios autenticados en `stations` y `trains`. Según el MVP, estas colecciones deberían ser actualizadas solo por Cloud Functions. Se recomienda migrar a las reglas propuestas para mayor seguridad.

---

## 7. Arquitectura del Proyecto

### Patrón de Arquitectura

El proyecto sigue una arquitectura **MVC (Model-View-Controller)** con separación de responsabilidades:

```
┌─────────────────────────────────────────┐
│           UI Layer (Screens)            │
│  (home_screen, report_screen, etc.)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      State Management (Providers)         │
│  (auth_provider, report_provider, etc.) │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Business Logic (Services)       │
│  (firebase_service, gamification, etc.) │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer (Models)              │
│  (user_model, station_model, etc.)      │
└──────────────────────────────────────────┘
```

### Flujo de Datos

1. **Usuario interactúa** → Screen
2. **Screen llama** → Provider
3. **Provider usa** → Service
4. **Service accede** → Firebase/Model
5. **Cambios se propagan** → Provider notifica → Screen se actualiza

---

## 3. Modelos de Datos

### 3.1 UserModel (Usuario)

Representa un usuario de la aplicación.

```dart
class UserModel {
  final String uid;              // ID único del usuario
  final String email;           // Email
  final String nombre;           // Nombre del usuario
  final String? fotoUrl;        // URL de foto de perfil
  final int reputacion;         // Reputación (1-100)
  final int reportesCount;      // Total de reportes realizados
  final double precision;      // Precisión (0.0-100.0)
  final DateTime creadoEn;      // Fecha de creación
  final GeoPoint? ultimaUbicacion; // Última ubicación conocida
  final GamificationStats? gamification; // Estadísticas de gamificación
  final String? appMode;        // Modo de app ('development' o 'test')
}
```

**Colección Firestore:** `users/{uid}`

### 3.2 StationModel (Estación)

Representa una estación del Metro.

**Estado actual del modelo:**
```dart
class StationModel {
  final String id;              // ID único de la estación
  final String nombre;          // Nombre de la estación
  final String linea;           // 'linea1' o 'linea2'
  final GeoPoint ubicacion;     // Coordenadas GPS
  final EstadoEstacion estadoActual; // Estado actual
  final int aglomeracion;       // Nivel de aglomeración (1-5)
  final DateTime ultimaActualizacion; // Última actualización
  // Pendiente: `etaMinutes`, `confidence` (según documento MVP)
}

enum EstadoEstacion {
  normal,    // 🟢 Normal
  moderado,  // 🟡 Moderado
  lleno,     // 🔴 Lleno
  cerrado,   // ⚫ Cerrado
  // Pendiente: `retraso`, `unknown` (según documento MVP)
}
```

**Colección Firestore:** `stations/{stationId}`

**Recomendación del MVP (pendiente de implementación):**
Según el documento técnico MVP, el `StationModel` debería incluir:
- `status`: 'normal'|'moderate'|'crowded'|'delay'|'closed'|'unknown'
- `etaMinutes`: { next: number|null, next2: number|null }
- `confidence`: 'high'|'medium'|'low'

**Datos Estáticos:**
- Línea 1: 14 estaciones (desde Albrook hasta San Isidro)
- Línea 2: 8 estaciones (desde Nuevo Tocumen hasta San Miguelito)

### 3.3 TrainModel (Tren)

Representa un tren virtual en el sistema.

**Estado actual del modelo:**
```dart
class TrainModel {
  final String id;              // ID único del tren
  final String linea;           // 'linea1' o 'linea2'
  final DireccionTren direccion; // norte o sur
  final GeoPoint ubicacionActual; // Ubicación actual (GeoPoint)
  final double velocidad;       // Velocidad en km/h
  final EstadoTren estado;      // Estado del tren
  final int aglomeracion;       // Nivel de ocupación (1-5)
  final DateTime ultimaActualizacion; // Última actualización
}

enum EstadoTren {
  normal,    // 🚇 Normal
  retrasado, // ⚠️ Retrasado
  detenido,  // 🛑 Detenido
}

enum DireccionTren {
  norte,  // Hacia Albrook
  sur,    // Hacia San Isidro
}
```

**Colección Firestore:** `trains/{trainId}` (Actualmente en uso. Según MVP se recomienda `train_state/{trainId}`)

**Recomendación del MVP (pendiente de implementación):**
Según el documento técnico MVP, el `TrainModel` debería modelarse como un tren virtual usando segmentos y posición interpolada:

```dart
// Modelo recomendado (MVP) - PENDIENTE DE IMPLEMENTAR
class TrainModel {
  final String id;
  final String linea;           // 'L1' | 'L2' (según MVP)
  final String direction;       // 'A' | 'B' (según MVP)
  final Map<String, String> segment; // { fromStationId, toStationId }
  final double position;        // 0.0..1.0 interpolada en el segmento
  final double speedKmh;        // Velocidad en km/h
  final String status;          // 'moving'|'slow'|'stopped'
  final int crowdLevel;         // 1-5
  final String confidence;      // 'high'|'medium'|'low'
  final DateTime updatedAt;
  
  // Si se mantiene ubicacionActual, debe ser derivada:
  // Se calcula interpolando el segmento usando position (0.0..1.0)
  final GeoPoint? ubicacionActual; // DERIVADA: calculada desde segment + position
}
```

> **Nota:** El modelo actual utiliza `ubicacionActual` como GeoPoint directo. Si se mantiene este campo, debe aclararse que es derivada: se calcula interpolando el segmento usando la posición (0.0..1.0).

### 3.4 ReportModel (Reporte)

Representa un reporte de un usuario sobre una estación o tren.

```dart
class ReportModel {
  final String id;                    // ID único del reporte
  final String usuarioId;             // ID del usuario que reporta
  final TipoReporte tipo;             // 'estacion' o 'tren'
  final String objetivoId;            // ID de estación o tren
  final CategoriaReporte categoria; // Tipo de reporte
  final String? descripcion;          // Descripción opcional
  final GeoPoint ubicacion;          // Ubicación donde se hizo el reporte
  final int verificaciones;           // Número de verificaciones
  final EstadoReporte estado;        // Estado del reporte
  final DateTime creadoEn;            // Fecha de creación
  
  // Campos adicionales
  final String? estadoPrincipal;      // Estado principal reportado
  final List<String> problemasEspecificos; // Lista de problemas
  final bool prioridad;               // Si es prioritario
  final String? fotoUrl;              // URL de foto adjunta
  final double confidence;           // Confianza (0.0-1.0)
  final String verificationStatus;    // Estado de verificación
  final int confirmationCount;       // Contador de confirmaciones
  final int? tiempoEstimadoReportado; // Tiempo estimado reportado
  final bool? tiempoEstimadoValidado; // Si el tiempo es válido
}

enum TipoReporte {
  estacion,  // Reporte sobre estación
  tren,      // Reporte sobre tren
}

enum CategoriaReporte {
  aglomeracion,    // Nivel de aglomeración
  retraso,         // Retraso en servicio
  servicioNormal,  // Servicio normal
  fallaTecnica,   // Falla técnica
}

enum EstadoReporte {
  activo,    // Reporte activo
  resuelto, // Reporte resuelto
  falso,    // Reporte marcado como falso
}
```

**Colección Firestore:** `reports/{reportId}`

### 3.5 GamificationStats (Gamificación)

Estadísticas de gamificación del usuario.

```dart
class GamificationStats {
  final int puntos;              // Puntos totales
  final int nivel;              // Nivel actual (1-50)
  final int streak;              // Días consecutivos reportando
  final double precision;       // Precisión (0.0-1.0)
  final int reportesVerificados; // Reportes confirmados por otros
  final int verificacionesHechas; // Reportes de otros que confirmó
  final int seguidores;          // Número de seguidores
  final int ranking;            // Ranking global
  final int rankingLinea1;      // Ranking en Línea 1
  final int rankingLinea2;      // Ranking en Línea 2
  final List<Badge> badges;     // Badges desbloqueados
  final DateTime? ultimoReporte; // Fecha del último reporte
  final Map<String, int> puntosPorLinea; // Puntos por línea
  final int teachingReportsCount; // Reportes de enseñanza
  final int teachingScore;       // Puntuación como profesor
}
```

**Almacenado en:** `users/{uid}/gamification` (subdocumento)

### 3.6 Badge (Insignia)

Representa una insignia/medalla desbloqueada.

```dart
class Badge {
  final BadgeType type;          // Tipo de badge
  final String nombre;           // Nombre del badge
  final String descripcion;      // Descripción
  final String icono;            // Emoji del badge
  final DateTime? desbloqueadoEn; // Fecha de desbloqueo
}

enum BadgeType {
  primerReporte,        // 🎯 Primer reporte
  verificador,          // ✅ Verificador
  ojoDeAguila,          // 👁️ Ojo de águila
  salvavidas,           // 🆘 Salvavidas
  metroMaster,          // 🏆 Maestro del Metro
  streakSemana,         // 🔥 Racha de una semana
  streakMes,            // 🔥🔥 Racha de un mes
  topContribuidor,      // ⭐ Top contribuidor
  francotirador,        // 🎯 95%+ precisión
  detective,            // 🔍 85%+ precisión
  observador,           // 👀 70%+ precisión
  ojoDeAguila80,        // 👁️ 80%+ precisión
  ayudanteComunidad,    // 🤝 50 verificaciones
  influencerMetro,      // 📢 100+ personas ayudadas
  expertoLinea1,        // 🚇 Experto Línea 1
  maestroLinea2,        // 🚇 Maestro Línea 2
  almaPollera,          // 🇵🇦 Reportar durante mes patrio
  reyCarnaval,          // 🎉 Reportar durante carnavales
  profesorDelMetro,     // 🎓 10+ reportes de enseñanza
}
```

---

## 4. Servicios Principales

### 4.1 FirebaseService

Servicio principal para interactuar con Firebase.

**Funcionalidades:**
- Operaciones CRUD de usuarios
- Streams de estaciones y trenes en tiempo real
- Creación y gestión de reportes
- Operaciones de rutas
- Gestión de confirmaciones de reportes

**Métodos principales:**
```dart
// Usuarios
Future<void> createUser(UserModel user)
Future<UserModel?> getUser(String uid)
Stream<UserModel?> getUserStream(String uid)

// Estaciones
Stream<List<StationModel>> getStationsStream()
Future<List<StationModel>> getStations()
Future<void> updateStation(String id, Map<String, dynamic> data)

// Trenes
Stream<List<TrainModel>> getTrainsStream()
Future<List<TrainModel>> getTrains()

// Reportes
Future<String> createReport(ReportModel report)
Stream<List<ReportModel>> getActiveReportsStream()
Future<void> confirmReport(String reportId, String userId)
```

### 4.2 GamificationService

Gestiona el sistema de gamificación.

**Funcionalidades:**
- Otorgar puntos por acciones
- Calcular niveles
- Desbloquear badges
- Gestionar rachas (streaks)
- Calcular precisión

**Puntos por acción:**
- Reporte verificado: **10 puntos**
- Confirmar reporte: **5 puntos**
- Reporte épico: **100 puntos**
- Racha diaria: **2 puntos**

**Sistema de niveles:**
- 50 niveles totales
- Cada nivel requiere más puntos que el anterior
- Nombres temáticos del Metro (Ej: "Pasajero Novato", "Conductor Experto", etc.)

### 4.3 LocationService

Gestiona la ubicación del usuario.

**Funcionalidades:**
- Verificar permisos de ubicación
- Obtener ubicación actual
- Stream de ubicación en tiempo real
- Conversión de Position a GeoPoint

**Métodos:**
```dart
Future<LocationPermissionStatus> checkLocationStatus()
Future<bool> checkLocationPermission()
Future<Position?> getCurrentPosition()
Stream<Position> getPositionStream()
GeoPoint positionToGeoPoint(Position position)
```

### 4.4 NotificationService

Gestiona notificaciones push y locales.

**Funcionalidades:**
- Solicitar permisos de notificaciones
- Inicializar notificaciones locales
- Manejar mensajes en foreground y background
- Obtener y guardar FCM token

### 4.5 AdService

Gestiona los anuncios de AdMob.

**Tipos de anuncios:**
- **Banner:** Anuncio fijo en la parte inferior
- **Interstitial:** Anuncio de pantalla completa (con frequency capping)
- **Rewarded:** Anuncio con recompensa (quitar ads temporalmente)

**Frequency Capping:**
- Máximo 1 interstitial cada 120 segundos
- Solo en eventos de baja fricción (cambio de línea, abrir planificador)

### 4.6 ReportValidationService

Valida reportes antes de enviarlos.

**Validaciones:**
- Verificar que el usuario esté cerca de la estación/tren
- Validar coherencia de datos
- Verificar que no haya reportes duplicados recientes

### 4.7 ConfidenceService

Calcula niveles de confianza de reportes.

**Estado real de Confidence:**
- `ConfidenceService` existe (código), pero actualmente:
  - No actualiza `stations.confidence` ni `trains.confidence` de forma consistente.
  - Se usa solo para `report.confidence` (si aplica).
- **Pendiente:** implementar la lógica para actualizar la confianza agregada para `stations` y `trains` según las reglas del documento MVP.

**Niveles (para reportes):**
- **Alta:** 5+ reportes confirmados en últimos 10 min
- **Media:** 2-4 reportes en últimos 15 min
- **Baja:** 1 reporte o datos antiguos (>20 min)

### 4.8 TimeEstimationService

Calcula tiempos estimados de llegada.

**Funcionalidades:**
- Calcular ETA basado en reportes
- Validar tiempos reportados por usuarios
- Proporcionar estimaciones cuando no hay datos suficientes

---

## 5. Flujos de Trabajo

### 5.1 Flujo de Inicio de Sesión

```
1. Usuario abre la app
   ↓
2. Verificar si hay sesión activa (Firebase Auth)
   ↓
3. Si no hay sesión:
   - Mostrar pantalla de login
   - Opciones: Email/Password o Google Sign-In
   ↓
4. Si hay sesión:
   - Obtener datos del usuario desde Firestore
   - Verificar si es primera vez (onboarding)
   ↓
5. Inicializar servicios:
   - NotificationService
   - AdService
   - LocationService
   ↓
6. Cargar datos:
   - Estaciones (desde Firestore o datos estáticos)
   - Trenes (desde Firestore)
   - Reportes activos
   ↓
7. Mostrar pantalla principal (Home)
```

### 5.2 Flujo de Creación de Reporte

```
1. Usuario toca estación o botón "Reporte Rápido"
   ↓
2. Seleccionar tipo de reporte:
   - Estación o Tren
   ↓
3. Seleccionar estado principal:
   - Normal, Moderado, Lleno, Retraso, Cerrado
   ↓
4. (Opcional) Seleccionar problemas específicos:
   - Aire acondicionado, Puertas, Limpieza, etc.
   ↓
5. (Opcional) Agregar descripción o foto
   ↓
6. Validar reporte:
   - Verificar ubicación del usuario
   - Verificar coherencia de datos
   ↓
7. Crear reporte en Firestore
   ↓
8. Cloud Function se activa (processNewReport):
   - Verificación automática
   - Actualizar estado de estación/tren
   - Enviar notificaciones
   ↓
9. Otorgar puntos al usuario (GamificationService)
   ↓
10. Actualizar UI con nuevo reporte
```

### 5.3 Flujo de Confirmación de Reporte

```
1. Usuario ve un reporte activo en el mapa
   ↓
2. Toca el reporte para ver detalles
   ↓
3. Presiona botón "Confirmar"
   ↓
4. Validar que el usuario no haya confirmado antes
   ↓
5. Incrementar confirmationCount del reporte (transacción)
   ↓
6. Si confirmationCount >= 3:
   - Marcar reporte como 'community_verified'
   - Aumentar confidence a 0.9
   - Actualizar estado de estación/tren
   ↓
7. Otorgar puntos:
   - 5 puntos al confirmador
   - 10 puntos al reportero (si es primera vez que se verifica)
   ↓
8. Verificar badges:
   - Badge "Verificador" si es primera confirmación
   - Badge "Ayudante de Comunidad" si tiene 50+ confirmaciones
   ↓
9. Actualizar UI
```

### 5.4 Flujo de Gamificación

```
1. Usuario realiza una acción (reporte, confirmación, etc.)
   ↓
2. GamificationService calcula puntos a otorgar
   ↓
3. Actualizar puntos en Firestore
   ↓
4. Calcular nuevo nivel (LevelService)
   ↓
5. Verificar si desbloquea algún badge:
   - Primer reporte
   - Racha de 7 días
   - Racha de 30 días
   - Precisión alta
   - Etc.
   ↓
6. Si desbloquea badge:
   - Agregar badge a la lista
   - Mostrar modal de logro
   ↓
7. Actualizar rankings:
   - Ranking global
   - Ranking por línea
   ↓
8. Actualizar UI (perfil, leaderboard)
```

### 5.5 Flujo de Notificaciones

```
1. Se crea un reporte crítico (lleno, cerrado, detenido)
   ↓
2. Cloud Function (processNewReport) detecta reporte crítico
   ↓
3. Buscar usuarios afectados:
   - Usuarios cercanos (dentro de 5 km)
   - Usuarios con estación favorita
   ↓
4. Preparar mensajes FCM:
   - Título: "🚨 Alerta en Estación"
   - Cuerpo: Descripción del reporte
   - Data: ID del reporte, tipo, objetivo
   ↓
5. Enviar notificaciones push
   ↓
6. Usuario recibe notificación:
   - Si app está en foreground: Mostrar notificación local
   - Si app está en background: Mostrar notificación del sistema
   ↓
7. Usuario toca notificación:
   - Abrir app
   - Navegar a la estación/tren afectado
   - Mostrar detalles del reporte
```

---

## 6. Funcionalidades Implementadas

### 6.1 Mapa Interactivo

**Características:**
- Mapa base de Google Maps
- Overlay personalizado con líneas del Metro
- Estaciones como marcadores con colores según estado
- Trenes virtuales animados
- Zoom y pan interactivos
- Tocar estación/tren muestra detalles

**Estados visuales:**
- 🟢 Verde: Normal
- 🟡 Amarillo: Moderado
- 🔴 Rojo: Lleno/Crítico
- ⚫ Gris: Cerrado

### 6.2 Sistema de Reportes

**Tipos de reportes:**
- **Por Estación:**
  - Estado: Normal, Moderado, Lleno, Retraso, Cerrado
  - Problemas: Aire acondicionado, Puertas, Limpieza, etc.
  
- **Por Tren:**
  - Ocupación: Asientos disponibles, De pie cómodo, Sardina
  - Estado: Express, Lento, Detenido
  - Problemas técnicos

**Características:**
- Reporte rápido (1-2 taps)
- Validación de ubicación
- Fotos opcionales
- Confirmaciones colaborativas
- Verificación automática

### 6.3 Planificador de Rutas

**Funcionalidades:**
- Seleccionar estación de origen
- Seleccionar estación de destino
- Calcular ruta óptima
- Mostrar tiempo estimado
- Mostrar estado de la ruta
- Considerar retrasos e incidencias

### 6.4 Perfil de Usuario

**Información mostrada:**
- Nombre y foto
- Nivel y puntos
- Reputación
- Badges desbloqueados
- Estadísticas (reportes, verificaciones, precisión)
- Ranking global y por línea
- Historial de reportes

### 6.5 Leaderboards (Clasificaciones)

**Tipos de rankings:**
- Global (todos los usuarios)
- Por Línea (Línea 1 y Línea 2)
- Por categoría (reportes, verificaciones, precisión)

**Actualización:**
- Tiempo real mediante streams de Firestore
- Ordenados por puntos
- Muestra top 100 usuarios

### 6.6 Modo Desarrollo

**Características:**
- Activación secreta (7 taps en logo)
- Simulador de ubicación
- Editor de posiciones de estaciones
- Métricas de rendimiento
- Escenarios de prueba
- Modo test para reportes

---

## 7. Gamificación

### 7.1 Sistema de Puntos

**Puntos otorgados por:**
- Crear reporte: **0 puntos** (solo si se verifica)
- Reporte verificado: **10 puntos**
- Confirmar reporte: **5 puntos**
- Reporte épico (muy útil): **100 puntos**
- Racha diaria: **2 puntos**

### 7.2 Sistema de Niveles

**50 niveles totales:**
- Nivel 1-10: Pasajero Novato
- Nivel 11-20: Viajero Frecuente
- Nivel 21-30: Conductor Experto
- Nivel 31-40: Maestro del Metro
- Nivel 41-50: Leyenda del Metro

**Cálculo de nivel:**
```dart
nivel = LevelService.calculateLevel(puntos)
```

### 7.3 Badges (Insignias)

**Categorías:**
- **Inicio:** Primer reporte
- **Verificación:** Verificador, Ojo de águila
- **Precisión:** Francotirador (95%+), Detective (85%+), Observador (70%+)
- **Comunidad:** Ayudante de comunidad, Influencer del Metro
- **Especialización:** Experto Línea 1, Maestro Línea 2
- **Eventos:** Alma Pollera (mes patrio), Rey Carnaval
- **Enseñanza:** Profesor del Metro

### 7.4 Rachas (Streaks)

**Sistema:**
- Contador de días consecutivos reportando
- Se reinicia si no reporta en 24 horas
- Badges especiales:
  - Racha de 7 días
  - Racha de 30 días

### 7.5 Precisión

**Cálculo:**
- Basado en reportes verificados vs reportes rechazados
- Fórmula: `(reportes_verificados / total_reportes) * 100`
- Afecta la reputación del usuario

---

## 8. Sistema de Reportes

### 8.1 Creación de Reportes

**Proceso:**
1. Usuario selecciona estación o tren
2. Elige tipo de reporte
3. Selecciona estado principal
4. (Opcional) Agrega problemas específicos
5. (Opcional) Agrega descripción o foto
6. Valida ubicación
7. Crea reporte en Firestore

**Validaciones:**
- Usuario debe estar cerca de la estación/tren (500m)
- No puede crear reportes duplicados (mismo tipo, mismo objetivo, últimos 5 min)
- Debe estar autenticado

### 8.2 Verificación de Reportes

**Niveles de verificación:**
1. **Pending:** Recién creado, sin confirmaciones
2. **Verified:** 2+ reportes similares en últimos 10 min (automático)
3. **Community Verified:** 3+ confirmaciones manuales

**Confianza (Confidence):**
- **0.5:** Reporte nuevo
- **0.8:** Verificado automáticamente
- **0.9:** Verificado por la comunidad

### 8.3 Confirmaciones

**Proceso:**
- Usuario toca reporte activo
- Presiona "Confirmar"
- Se incrementa `confirmationCount`
- Si alcanza 3: se marca como `community_verified`
- Se otorgan puntos a confirmador y reportero

**Restricciones:**
- No puede confirmar su propio reporte
- No puede confirmar el mismo reporte dos veces
- Debe estar cerca de la estación/tren

### 8.4 Resolución de Reportes

**Estados:**
- **Activo:** Reporte reciente y relevante
- **Resuelto:** Reporte antiguo (>20-30 min) sin confirmaciones
- **Falso:** Reporte marcado como incorrecto por múltiples usuarios

**Nota:** La resolución automática aún no está implementada completamente.

---

## 9. Mapas y Visualización

### 9.1 CustomMetroMap

Widget personalizado que dibuja el mapa del Metro sobre Google Maps.

**Componentes:**
- **Líneas:** Dibujadas como polilíneas (L1 azul, L2 verde)
- **Estaciones:** Marcadores circulares con colores según estado
- **Trenes:** Íconos animados que se mueven sobre las líneas
- **Overlays:** ETAs, niveles de confianza, badges

### 9.2 Estados Visuales

**Estaciones:**
- 🟢 Verde: Normal (aglomeración 1-2)
- 🟡 Amarillo: Moderado (aglomeración 3)
- 🔴 Rojo: Lleno (aglomeración 4-5)
- ⚫ Gris: Cerrado

**Trenes:**
- 🚇 Normal: Velocidad > 35 km/h
- 🐌 Lento: Velocidad 15-35 km/h
- 🛑 Detenido: Velocidad < 15 km/h

### 9.3 Interacciones

**Tocar estación:**
- Muestra bottom sheet con:
  - Nombre de la estación
  - Estado actual
  - Nivel de aglomeración
  - ETA del próximo tren
  - Reportes activos
  - Botón para crear reporte

**Tocar tren:**
- Muestra información del tren:
  - Línea y dirección
  - Velocidad actual
  - Estado
  - Ocupación
  - Ubicación aproximada

---

## 10. Notificaciones

### 10.1 Tipos de Notificaciones

**Alertas de Reportes:**
- Se envían cuando hay reportes críticos
- Solo a usuarios cercanos (5 km) o con estación favorita
- Tipos críticos: Lleno, Cerrado, Detenido, Sardina

**Notificaciones de Verificación:**
- Se envía al reportero cuando su reporte alcanza 3 confirmaciones
- Mensaje: "🎉 ¡Tu reporte fue verificado!"

**Notificaciones de Gamificación:**
- Badge desbloqueado
- Nuevo nivel alcanzado
- Racha mantenida

### 10.2 Implementación

**Foreground:**
- Notificaciones locales usando `flutter_local_notifications`
- Se muestran como overlay en la app

**Background:**
- Notificaciones del sistema
- Se manejan mediante `FirebaseMessaging.onBackgroundMessage`

**Data Payload:**
```json
{
  "type": "report",
  "reportId": "...",
  "objetivoId": "...",
  "tipo": "estacion"
}
```

---

## 11. Monetización (Ads)

### 11.1 Tipos de Anuncios

**Banner:**
- Fijo en la parte inferior del mapa
- Siempre visible
- No interrumpe la experiencia

**Interstitial:**
- Pantalla completa
- Solo en eventos de baja fricción:
  - Cambio de línea en el mapa
  - Abrir planificador de rutas
- Frequency capping: máximo 1 cada 120 segundos

**Rewarded:**
- Anuncio con recompensa
- Recompensas:
  - Quitar ads por 1 hora
  - Duplicar puntos por 30 minutos
- Opcional, el usuario decide verlo

### 11.2 Implementación

**AdService:**
- Gestiona inicialización de AdMob
- Crea y carga anuncios
- Maneja eventos (cargado, error, cerrado)

**AdSessionService:**
- Controla frequency capping
- Rastrea última vez que se mostró interstitial
- Gestiona sesiones de usuario

**IDs de Test:**
- Android: `ca-app-pub-3940256099942544/...`
- iOS: `ca-app-pub-3940256099942544/...`
- **Nota:** Reemplazar con IDs reales en producción

---

## 12. Cloud Functions

### 12.1 processNewReport

**Trigger:** Se crea un nuevo documento en `reports/{reportId}`

**Proceso:**
1. **Verificación automática:**
   - Busca reportes similares (mismo objetivo, mismo estado, últimos 10 min)
   - Si hay 2+: marca como `verified` con confidence 0.8

2. **Actualizar estado:**
   - Si está `community_verified`: actualiza estado de estación/tren
   - Calcula consenso de reportes recientes
   - Actualiza `stations/{stationId}` o `trains/{trainId}`

3. **Notificaciones:**
   - Si es crítico: busca usuarios cercanos
   - Envía notificaciones push

4. **Rutas:**
   - Actualiza estimaciones de rutas afectadas

### 12.2 processReportConfirmation

**Trigger:** Se crea un documento en `reports/{reportId}/confirmations/{userId}`

**Proceso:**
1. Obtiene el reporte
2. Incrementa `confirmationCount`
3. Si `confirmationCount >= 3`:
   - Marca como `community_verified`
   - Aumenta confidence a 0.9
   - Actualiza estado de estación/tren
   - Notifica al reportero

### 12.3 Cloud Functions (separación recomendada)

Las funciones actuales de `calculateTrainPositions` y `processUserLocation` tienen responsabilidades combinadas. Se recomienda separarlas para una lógica más clara y alineada con el MVP:

**Funciones actuales (básicas):**

- `calculateTrainPositions` (cada 1 minuto):
  - Obtiene usuarios con ubicación reciente (últimos 5 min)
  - Agrupa usuarios por estación cercana
  - Actualiza contadores de usuarios por estación
  - Calcula posiciones estimadas de trenes
  - **Nota:** Esta función es básica y no agrupa por segmentos ni usa `user_signals`.

- `processUserLocation` (trigger: `users/{userId}/location_history/{locationId}`):
  - Obtiene todas las estaciones
  - Encuentra estación más cercana (dentro de 500m)
  - Incrementa contador `usuarios_cercanos` de la estación
  - **Nota:** Esta función solo incrementa un contador, no genera `user_signals`.

**Funciones recomendadas (según MVP):**

- `updateStationCrowdFromSignals` (cada `trainCronIntervalSeconds`):
  - Estima la densidad de personas por estación (basado en usuarios cercanos y reportes).
  - Actualiza `stations.aglomeracion` y `stations.ultimaActualizacion`.

- `updateTrainStateFromSignals` (cada `trainCronIntervalSeconds`):
  - Utiliza `user_signals` (una vez implementado).
  - Agrupa señales por línea/dirección/segmento.
  - Actualiza `trains/{trainId}` (o la futura colección `train_state`) con `speedKmh`, `status` y `position` interpolada.

- `cleanupOldReports` (cada `reportResolveMinutes`):
  - Resuelve reportes antiguos (`status = 'resolved'`) que ya no son relevantes o no han sido confirmados.

---

## 13. Estructura de Archivos

```
lib/
├── main.dart                    # Punto de entrada
├── models/                      # Modelos de datos
│   ├── user_model.dart
│   ├── station_model.dart
│   ├── train_model.dart
│   ├── report_model.dart
│   ├── gamification_model.dart
│   ├── badge_model.dart
│   ├── route_model.dart
│   └── ...
├── services/                    # Lógica de negocio
│   ├── firebase_service.dart
│   ├── gamification_service.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   ├── ad_service.dart
│   ├── report_validation_service.dart
│   └── ...
├── providers/                   # State management
│   ├── auth_provider.dart
│   ├── location_provider.dart
│   ├── metro_data_provider.dart
│   └── report_provider.dart
├── screens/                     # Pantallas
│   ├── auth/
│   ├── home/
│   ├── reports/
│   ├── profile/
│   ├── leaderboards/
│   └── ...
├── widgets/                     # Widgets reutilizables
│   ├── custom_metro_map.dart
│   ├── station_bottom_sheet.dart
│   ├── enhanced_report_modal.dart
│   └── ...
├── utils/                       # Utilidades
│   ├── constants.dart
│   ├── helpers.dart
│   └── metro_data.dart
└── theme/                       # Tema de la app
    └── metro_theme.dart

functions/                       # Cloud Functions
└── index.js

docs/                            # Documentación
├── DOCUMENTACION_COMPLETA_PROYECTO.md
├── DOCUMENTO_TECNICO_MVP.md
└── ...
```

---

## 19. Resumen de Estado

### ✅ Completamente Implementado

- ✅ Autenticación (Email/Password, Google Sign-In)
- ✅ Modelos de datos básicos
- ✅ Sistema de reportes (creación, confirmación, verificación)
- ✅ Gamificación (puntos, niveles, badges, rankings)
- ✅ Mapa interactivo con estaciones y trenes (basado en `GeoPoint`)
- ✅ Notificaciones push
- ✅ Ads (Banner, Interstitial, Rewarded)
- ✅ Planificador de rutas
- ✅ Perfil de usuario
- ✅ Leaderboards
- ✅ Cloud Functions básicas (`processNewReport`, `processReportConfirmation`, `calculateTrainPositions`, `processUserLocation`)

### ⚠️ Parcialmente Implementado

- ⚠️ Tracking automático de ubicación (existe pero no genera `user_signals` ni infiere estado)
- ⚠️ Agregación de trenes virtuales (básica, no usa `user_signals`, no interpola posición, usa `trains/` en lugar de `train_state/`)
- ⚠️ ETAs automáticos (simulados, no calculados desde `train_state`)
- ⚠️ Confidence levels (solo implementado para `report.confidence`)

### ❌ No Implementado (Según Documento Técnico MVP)

- ❌ Colección `user_signals` con TTL
- ❌ Inferencia de estado del usuario (en estación/en tren)
- ❌ Posición interpolada en segmentos para `TrainModel`
- ❌ ETAs automáticos basados en `train_state`
- ❌ Resolución automática de reportes (`cleanupOldReports`)
- ❌ Confidence levels agregados para estaciones y trenes

---

## 20. Configuración Requerida

### Firebase
- Proyecto Firebase creado
- Firestore habilitado
- Authentication habilitado (Email/Password, Google)
- Cloud Functions desplegadas
- FCM configurado

### Google Maps
- Proyecto en Google Cloud Console
- Maps SDK for Android habilitado
- Maps SDK for iOS habilitado
- API Key creada y configurada

### AdMob
- Cuenta de AdMob creada
- App registrada
- Ad Units creados (Banner, Interstitial, Rewarded)
- IDs configurados en código

---

## 21. Notas Finales

Este documento describe el estado actual del proyecto MetroPTY, incorporando las observaciones y recomendaciones para alinear la documentación y el código con las mejores prácticas y el documento técnico MVP.

**Última actualización:** 2025-12-14

---

**¿Necesitas más detalles sobre alguna sección específica?** Consulta los archivos de código fuente o la documentación técnica para más información.
