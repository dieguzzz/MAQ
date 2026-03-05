---
title: Trabajo Pendiente
type: state
tags: [state, pending]
last-updated: 2026-02-13
---

# Trabajo Pendiente

## Prioridad Alta (MVP)

### 1. Sistema de Señales de Usuario

- Implementar colección `user_signals/{uid}` con TTL 2-5 min
- Inferencia automática: ¿usuario en estación o en tren?
- Usar señales para calcular densidad por estación

### 2. Trenes Virtuales Mejorados

- Migrar colección `trains/` → `train_state/`
- Implementar posición interpolada en segmentos (0.0..1.0)
- Migrar `linea` de 'linea1'/'linea2' → 'L1'/'L2'
- Migrar `direccion` de 'norte'/'sur' → 'A'/'B'

### 3. ETAs Reales

- Calcular ETAs desde datos reales (no simulados)
- Agregar `etaMinutes: { next, next2 }` a `StationModel`

### 4. Resolución Automática de Reportes

- Cloud Function `cleanupOldReports`
- Auto-resolver reportes >25min sin confirmaciones

## Prioridad Media

### 5. Confidence Levels Agregados

- Implementar confidence para stations y trains (no solo reports)
- Actualizar `ConfidenceService` para agregar datos

### 6. Cloud Functions Separadas

- `updateStationCrowdFromSignals`
- `updateTrainStateFromSignals`

## Prioridad Baja

### 7. Limpieza de Código

- Consolidar los dos sistemas de reportes
- Eliminar referencias al naming viejo gradualmente
- Actualizar estadísticas en `ESTADO_ACTUAL.md` (desactualizado)

## Deuda Técnica

- El `custom_metro_map.dart` tiene 82KB → candidato a refactoring
- `station_report_sheet.dart` tiene 83KB → candidato a refactoring
- Dos sistemas de reportes coexistiendo (Legacy vs Simplificado)
- Naming inconsistente: mezcla español (Firestore legacy) e inglés (nuevo)
