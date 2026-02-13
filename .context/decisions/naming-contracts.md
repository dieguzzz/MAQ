---
title: Contrato de Nombres
type: decision
tags: [decision, naming, contract]
last-updated: 2026-02-13
---

# Contrato de Nombres

## Colecciones Firestore (Estado actual)

| Colección                 | Uso                                 |
| ------------------------- | ----------------------------------- |
| `users/{uid}`             | Perfil + gamificación               |
| `stations/{stationId}`    | Estaciones                          |
| `trains/{trainId}`        | Trenes (⚠️ MVP dice `train_state/`) |
| `reports/{reportId}`      | Reportes legacy                     |
| `simplified_reports/{id}` | Reportes nuevo sistema              |

## Campos clave: Estado actual vs MVP

### linea

| Actual                  | MVP recomendado | Migrado? |
| ----------------------- | --------------- | -------- |
| `'linea1'` / `'linea2'` | `'L1'` / `'L2'` | ❌ No    |

### direccion (trenes)

| Actual              | MVP recomendado | Migrado? |
| ------------------- | --------------- | -------- |
| `'norte'` / `'sur'` | `'A'` / `'B'`   | ❌ No    |

### estado estación

| Actual                                              | MVP recomendado             | Migrado?   |
| --------------------------------------------------- | --------------------------- | ---------- |
| `'normal'` / `'moderado'` / `'lleno'` / `'cerrado'` | + `'retraso'` / `'unknown'` | ⚠️ Parcial |

### estado tren

| Actual                                    | MVP recomendado                     | Migrado? |
| ----------------------------------------- | ----------------------------------- | -------- |
| `'normal'` / `'retrasado'` / `'detenido'` | `'moving'` / `'slow'` / `'stopped'` | ❌ No    |

## Source of Truth (Prioridad)

1. **Reportes `community_verified`** → máxima prioridad para estado
2. **Señales automáticas** → velocidad, ETA (cuando se implementen)
3. **Conflictos**: reporte verificado > señal automática (para estado)
4. **Señales**: siempre mandan en velocidad y ETA si son más recientes
