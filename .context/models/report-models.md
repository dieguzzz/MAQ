---
title: Report Model (Legacy + Simplified)
type: model
status: implemented
tags: [model, firestore, report]
source: lib/models/report_model.dart, lib/models/simplified_report_model.dart
last-updated: 2026-02-13
---

# Report Models

> Hay DOS sistemas de reportes coexistiendo.

## 1. ReportModel (Legacy)

**Colección**: `reports/{reportId}`
**Archivo**: `lib/models/report_model.dart`

### Campos principales

| Campo                | Tipo             | Descripción                                 |
| -------------------- | ---------------- | ------------------------------------------- |
| id                   | String           | ID único                                    |
| usuarioId            | String           | UID del reportero                           |
| tipo                 | TipoReporte      | `estacion` o `tren`                         |
| objetivoId           | String           | ID estación/tren                            |
| categoria            | CategoriaReporte | Tipo de reporte                             |
| estadoPrincipal      | String?          | Estado reportado                            |
| problemasEspecificos | List\<String\>   | Lista de problemas                          |
| confidence           | double           | 0.0-1.0                                     |
| verificationStatus   | String           | 'pending'\|'verified'\|'community_verified' |
| confirmationCount    | int              | Confirmaciones recibidas                    |

### Enums

- **TipoReporte**: `estacion` | `tren`
- **CategoriaReporte**: `aglomeracion` | `retraso` | `servicioNormal` | `fallaTecnica`
- **EstadoReporte**: `activo` | `resuelto` | `falso`
- **EstadoPrincipalEstacion**: `normal` | `moderado` | `lleno` | `retraso` | `cerrado`
- **EstadoPrincipalTren**: `asientosDisponibles` | `dePieComodo` | `sardina` | `express` | `lento` | `detenido`
- **ProblemaEspecifico**: `aireAcondicionado` | `puertas` | `limpieza` | `mantenimiento` | `sonido` | `luces`

---

## 2. SimplifiedReportModel (Nuevo)

**Colección**: `simplified_reports/{id}`
**Archivo**: `lib/models/simplified_report_model.dart`

### Diferencia clave

Usa `scope: 'station' | 'train'` en vez de `TipoReporte` enum.

### Campos únicos del simplificado

| Campo              | Tipo            | Descripción                                                            |
| ------------------ | --------------- | ---------------------------------------------------------------------- |
| scope              | String          | 'station' o 'train'                                                    |
| stationOperational | String?         | 'yes'\|'partial'\|'no'                                                 |
| stationCrowd       | int?            | 1-5                                                                    |
| issueType          | String?         | 'ac'\|'escalator'\|'elevator'\|'atm'\|'recharge'\|'bathroom'\|'lights' |
| issueLocation      | String?         | Ubicación del problema (texto libre)                                   |
| issueStatus        | String?         | 'not_working'\|'working_poorly'\|'out_of_service'                      |
| trainCrowd         | int?            | 1-5                                                                    |
| trainLine          | String?         | 'L1'\|'L2'                                                             |
| direction          | String?         | 'A'\|'B'                                                               |
| etaBucket          | String?         | '1-2'\|'3-5'\|'6-8'\|'9+'\|'unknown'                                   |
| trainStatus        | String?         | 'normal'\|'slow'\|'stopped'                                            |
| isPanelTime        | bool?           | Si viene del panel digital oficial                                     |
| basePoints         | int             | Puntos base                                                            |
| bonusPoints        | int             | Puntos bonus                                                           |
| totalPoints        | int             | Total puntos                                                           |
| confidenceReasons  | List\<String\>? | Razones de confianza                                                   |

> **Nota**: El SimplifiedReportModel usa la nomenclatura del MVP ('L1'/'L2', 'A'/'B') mientras el ReportModel legacy usa la vieja ('linea1'/'linea2', 'norte'/'sur').
