---
title: Train Model
type: model
status: implemented
tags: [model, firestore, train]
source: lib/models/train_model.dart
collection: trains/{trainId}
last-updated: 2026-02-13
---

# Train Model

> Tren virtual con ubicación, velocidad y estado en tiempo real.

## Campos

| Campo               | Tipo          | Default  | Descripción             |
| ------------------- | ------------- | -------- | ----------------------- |
| id                  | String        | required | ID único                |
| linea               | String        | required | 'linea1' o 'linea2'     |
| direccion           | DireccionTren | required | norte o sur             |
| ubicacionActual     | GeoPoint      | required | Posición GPS actual     |
| velocidad           | double        | 0.0      | km/h                    |
| estado              | EstadoTren    | normal   | Estado actual           |
| aglomeracion        | int           | 1        | Nivel 1-5               |
| ultimaActualizacion | DateTime      | required | Última update           |
| confidence          | String?       | null     | 'high'\|'medium'\|'low' |
| isEstimated         | bool?         | false    | Si datos son estimados  |

## Enums

**EstadoTren**: `normal` | `retrasado` | `detenido`
**DireccionTren**: `norte` | `sur`

## Firestore mapping

| Dart                | Firestore                        |
| ------------------- | -------------------------------- |
| ubicacionActual     | ubicacion_actual                 |
| ultimaActualizacion | ultima_actualizacion (Timestamp) |
| isEstimated         | is_estimated                     |

## Aglomeración trenes

| Valor | Texto     |
| ----- | --------- |
| 1     | Vacío     |
| 2     | Moderado  |
| 3     | Lleno     |
| 4     | Muy Lleno |
| 5     | Sardina   |

## ⚠️ Pendiente MVP

- Falta `segment: { fromStationId, toStationId }`
- Falta `position: 0.0..1.0` (interpolada en segmento)
- `linea` debería ser 'L1'/'L2'
- `direccion` debería ser 'A'/'B'
- Colección debería ser `train_state/` en vez de `trains/`
