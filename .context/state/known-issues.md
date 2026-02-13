---
title: Issues Conocidos
type: state
tags: [state, issues, bugs]
last-updated: 2026-02-13
---

# Issues Conocidos

## Naming Inconsistente

- Firestore legacy usa español (`estado_actual`, `ultima_actualizacion`)
- SimplifiedReportModel usa inglés (`stationCrowd`, `trainStatus`)
- `linea` field: legacy='linea1'/'linea2', nuevo='L1'/'L2'
- `direccion` field: legacy='norte'/'sur', nuevo='A'/'B'

## Archivos Muy Grandes

| Archivo                           | Tamaño | Acción sugerida        |
| --------------------------------- | ------ | ---------------------- |
| `custom_metro_map.dart`           | 82KB   | Extraer sub-widgets    |
| `station_report_sheet.dart`       | 83KB   | Dividir en componentes |
| `station_report_flow_widget.dart` | 44KB   | Refactorizar flujo     |
| `simplified_report_service.dart`  | 36KB   | Separar por scope      |
| `gamification_service.dart`       | 31KB   | Extraer badge logic    |

## Datos Simulados

- ETAs son simulados, no reales
- Posiciones de trenes son estimadas, no interpoladas
- Resolución automática de reportes no funciona

## Documentación Desactualizada

- `docs/ESTADO_ACTUAL.md` dice "24 archivos Dart" cuando hay 140+
- Muchos docs en `docs/` son redundantes o contradictorios
- El contrato de nombres no refleja el estado real del código
