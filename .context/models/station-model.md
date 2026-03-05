---
title: Station Model
type: model
status: implemented
tags: [model, firestore, station]
source: lib/models/station_model.dart
collection: stations/{stationId}
last-updated: 2026-02-13
---

# Station Model

> Estación del Metro con estado en tiempo real y nivel de aglomeración.

## Campos

| Campo               | Tipo           | Default  | Descripción             |
| ------------------- | -------------- | -------- | ----------------------- |
| id                  | String         | required | ID único                |
| nombre              | String         | required | Nombre de estación      |
| linea               | String         | required | 'linea1' o 'linea2'     |
| ubicacion           | GeoPoint       | required | Coordenadas GPS         |
| estadoActual        | EstadoEstacion | normal   | Estado actual           |
| aglomeracion        | int            | 1        | Nivel 1-5               |
| ultimaActualizacion | DateTime       | required | Última update           |
| confidence          | String?        | null     | 'high'\|'medium'\|'low' |
| isEstimated         | bool?          | false    | Si datos son estimados  |

## Enum EstadoEstacion

`normal` | `moderado` | `lleno` | `cerrado`

## Aliases en parsing

- `'congestionado'` → `moderado`
- `'critico'` → `lleno`

## Factories

- `fromFirestore(DocumentSnapshot)` — desde Firestore
- `fromStaticData({id, nombre, linea, ubicacion})` — desde datos estáticos

## Firestore mapping

| Dart                | Firestore                        |
| ------------------- | -------------------------------- |
| estadoActual        | estado_actual (String)           |
| ultimaActualizacion | ultima_actualizacion (Timestamp) |
| isEstimated         | is_estimated                     |

## Datos estáticos

- **Línea 1**: 14 estaciones (Albrook → San Isidro)
- **Línea 2**: 8 estaciones (Nuevo Tocumen → San Miguelito)
- Definidos en `lib/data/`

## ⚠️ Pendiente MVP

- Falta `etaMinutes: { next, next2 }`
- `linea` debería migrar a 'L1'/'L2' (actualmente 'linea1'/'linea2')
