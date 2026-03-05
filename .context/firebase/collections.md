---
title: Colecciones Firestore
type: firebase
tags: [firebase, firestore, collections]
last-updated: 2026-02-13
---

# Colecciones Firestore

## Colecciones activas

### `users/{uid}`

Perfil de usuario + gamificación embebida.
→ Ver [[user-model]] para campos completos.

### `stations/{stationId}`

Estado en tiempo real de estaciones.
→ Ver [[station-model]] para campos completos.

- 22 documentos (14 L1 + 8 L2)

### `trains/{trainId}`

Trenes virtuales con ubicación y estado.
→ Ver [[train-model]] para campos completos.

- ⚠️ MVP recomienda renombrar a `train_state/`

### `reports/{reportId}`

Reportes del sistema legacy.
→ Ver [[report-models]] para campos.

- Sub-colección: `confirmations/{userId}`

### `simplified_reports/{id}`

Reportes del sistema nuevo.
→ Ver [[report-models]] para campos.

## Colecciones pendientes (no implementadas)

- `user_signals/{uid}` — Tracking ubicación con TTL 2-5 min

## Contrato de nombres Firestore

| Campo Dart      | Campo Firestore   |
| --------------- | ----------------- |
| camelCase       | snake_case        |
| DateTime        | Timestamp         |
| GeoPoint        | GeoPoint (nativo) |
| Enum            | String            |
| bool/int/double | bool/int/double   |
| List            | Array             |
| Map             | Map               |
