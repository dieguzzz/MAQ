---
title: Cloud Functions
type: firebase
tags: [firebase, cloud-functions]
last-updated: 2026-02-13
---

# Cloud Functions

**Ubicación**: `functions/index.js`

## Funciones implementadas

### processNewReport

**Trigger**: `onCreate` en `reports/{reportId}`

1. Busca reportes similares (mismo objetivo, mismo estado, últimos 10 min)
2. Si hay 2+: marca como `verified`, confidence = 0.8
3. Si `community_verified`: actualiza estación/tren
4. Si crítico: envía push notifications a usuarios cercanos

### processReportConfirmation

**Trigger**: `onCreate` en `reports/{reportId}/confirmations/{userId}`

1. Incrementa `confirmationCount`
2. Si ≥3: marca como `community_verified`, confidence = 0.9
3. Actualiza estado de estación/tren
4. Notifica al reportero original

### calculateTrainPositions (básica)

**Trigger**: Cron cada 1 minuto

1. Busca usuarios con ubicación reciente (5 min)
2. Agrupa por estación cercana
3. Actualiza contadores de usuarios por estación
4. Calcula posiciones estimadas de trenes

- ⚠️ Básica: no usa `user_signals` ni segmentos

### processUserLocation

**Trigger**: `onCreate` en `users/{userId}/location_history/{locationId}`

1. Encuentra estación más cercana (≤500m)
2. Incrementa contador `usuarios_cercanos`

- ⚠️ Solo incrementa contador, no genera `user_signals`

## Funciones recomendadas (no implementadas)

- `updateStationCrowdFromSignals` — Densidad por estación
- `updateTrainStateFromSignals` — Estado trenes desde signals
- `cleanupOldReports` — Resolver reportes viejos automáticamente

## Parámetros del sistema

| Parámetro                    | Valor | Descripción                            |
| ---------------------------- | ----- | -------------------------------------- |
| signalTTLMinutes             | 3     | TTL de user_signals                    |
| reportDuplicateWindowMinutes | 5     | Ventana anti-duplicados                |
| reportResolveMinutes         | 25    | Auto-resolver reportes                 |
| communityVerifyThreshold     | 3     | Confirmaciones para community_verified |
| criticalRadiusKm             | 5     | Radio notificaciones críticas          |
| trainCronIntervalSeconds     | 60    | Intervalo cron trenes                  |
