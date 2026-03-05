---
title: Buenas Prácticas del Proyecto
type: architecture
tags: [architecture, best-practice, rules]
last-updated: 2026-02-13
---

# Buenas Prácticas y Reglas del Proyecto

## 🔑 Reglas de Oro

### 1. Convenciones de Nombres

- **Colecciones Firestore**: `snake_case` plural (`stations`, `reports`)
- **Campos Firestore**: `snake_case` (`estado_actual`, `ultima_actualizacion`)
- **Variables Dart**: `camelCase` (`estadoActual`, `ultimaActualizacion`)
- **Clases Dart**: `PascalCase` (`StationModel`, `FirebaseService`)
- **Archivos Dart**: `snake_case.dart` (`station_model.dart`)
- **Enums**: `PascalCase` nombre, `camelCase` valores

### 2. Modelos de Datos

- SIEMPRE tener `fromFirestore()` factory y `toFirestore()` method
- SIEMPRE convertir `Timestamp` → `DateTime` y viceversa
- SIEMPRE manejar campos nullable con `??` defaults
- SIEMPRE usar enums para estados tipados
- Mantener `copyWith()` en modelos que lo necesiten (ej: `UserModel`)
- Los campos opcionales usan `final Type?` con `this.field`

### 3. Providers

- SIEMPRE extender `ChangeNotifier`
- SIEMPRE llamar `notifyListeners()` después de cambiar estado
- NUNCA hacer lógica de negocio pesada en el provider — delegarlo a services
- Mantener streams activos con subscriptions y cancelarlos en `dispose()`

### 4. Reportes — Sistema Dual

El proyecto tiene **DOS sistemas de reportes** (legacy y simplificado):

- `ReportModel` → colección `reports/` (sistema original, más complejo)
- `SimplifiedReportModel` → colección `simplified_reports/` (sistema nuevo, más limpio)
- El sistema simplificado soporta `scope: 'station' | 'train'`
- Ambos sistemas coexisten actualmente

### 5. Validación de Reportes

- Usuario debe estar a **≤500m** de la estación/tren para reportar
- **No duplicados**: mismo tipo, mismo objetivo, últimos **5 minutos**
- Usuario debe estar **autenticado**
- `ReportValidationService` centraliza todas las validaciones

### 6. Sistema de Confianza (Confidence)

- Reporte nuevo: `confidence = 0.5`
- Verificado automáticamente (2+ similares en 10 min): `confidence = 0.8`
- Verificado por comunidad (3+ confirmaciones): `confidence = 0.9`
- Niveles: `'high'` | `'medium'` | `'low'`

### 7. Gamificación

- **Crear reporte verificado**: 10 puntos
- **Confirmar reporte**: 5 puntos
- **Reporte épico**: 100 puntos
- **Racha diaria**: 2 puntos
- **50 niveles** con nombres temáticos del Metro
- Badges por logros, precisión, rachas, eventos culturales

### 8. Estaciones — Valores de Aglomeración

| Valor | Texto    | Color       |
| ----- | -------- | ----------- |
| 1     | Vacía    | 🟢 Verde    |
| 2     | Baja     | 🟢 Verde    |
| 3     | Media    | 🟡 Amarillo |
| 4     | Alta     | 🔴 Rojo     |
| 5     | Muy Alta | 🔴 Rojo     |

### 9. Trenes — Valores de Aglomeración

| Valor | Texto     |
| ----- | --------- |
| 1     | Vacío     |
| 2     | Moderado  |
| 3     | Lleno     |
| 4     | Muy Lleno |
| 5     | Sardina   |

### 10. Estados

**Estaciones**: `normal` | `moderado` | `lleno` | `cerrado`
**Trenes**: `normal` | `retrasado` | `detenido`
**Reportes**: `activo` | `resuelto` | `falso`
**Verificación**: `pending` | `verified` | `community_verified`

## ⚠️ Cosas Importantes a Recordar

1. El campo `linea` usa `'linea1'` / `'linea2'` en el código (el MVP recomienda `'L1'` / `'L2'` pero NO se ha migrado)
2. El campo `direccion` usa `'norte'` / `'sur'` (el MVP recomienda `'A'` / `'B'` pero NO se ha migrado)
3. Los trenes usan colección `trains/` (el MVP recomienda `train_state/` pero NO se ha migrado)
4. Los ETAs son simulados, NO calculados desde datos reales
5. La resolución automática de reportes NO está implementada
6. El `custom_metro_map.dart` es el widget más grande y complejo (82KB)
7. El modo desarrollo se activa con **7 taps** en el logo

## 🚫 NO Hacer

- NO silenciar errores — siempre loguear con contexto
- NO hacer requests a Firestore directamente desde Screens — usar Provider→Service
- NO usar `dynamic` donde se pueda tipar
- NO mezclar lógica de presentación con lógica de negocio
- NO crear reportes sin validar ubicación primero
- NO subir a Git: `google-services.json`, `GoogleService-Info.plist`, API keys reales
