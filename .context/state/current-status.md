---
title: Estado Actual del Proyecto
type: state
tags: [state, status]
last-updated: 2026-02-13
---

# Estado Actual del Proyecto

## ✅ Completamente Implementado

- ✅ Autenticación (Email/Password, Google Sign-In)
- ✅ Modelos de datos (15 modelos)
- ✅ Sistema de reportes (creación, confirmación, verificación)
- ✅ Sistema simplificado de reportes (scope-based)
- ✅ Gamificación (puntos, niveles, 19 badges, rankings)
- ✅ Mapa interactivo con estaciones y trenes (Google Maps + overlay)
- ✅ Notificaciones push (FCM + local)
- ✅ Ads (Banner, Interstitial, Rewarded)
- ✅ Planificador de rutas
- ✅ Perfil de usuario con stats y badges
- ✅ Leaderboards (global, por línea)
- ✅ Cloud Functions básicas (4 funciones)
- ✅ Dashboard web admin (HTML/CSS/JS)
- ✅ Modo desarrollo (simulador, editor posiciones)
- ✅ 43 servicios de negocio
- ✅ 4 providers (state management)
- ✅ 33+ widgets reutilizables

## ⚠️ Parcialmente Implementado

- ⚠️ Tracking automático de ubicación (existe pero NO genera `user_signals`)
- ⚠️ Agregación de trenes virtuales (básica, no interpola, usa `trains/`)
- ⚠️ ETAs automáticos (simulados, no calculados desde datos reales)
- ⚠️ Confidence levels (solo para `report.confidence`, no para stations/trains)

## ❌ No Implementado (del Roadmap MVP)

- ❌ Colección `user_signals` con TTL
- ❌ Inferencia de estado del usuario (en estación / en tren)
- ❌ Posición interpolada en segmentos para `TrainModel`
- ❌ ETAs automáticos basados en `train_state`
- ❌ Resolución automática de reportes (`cleanupOldReports`)
- ❌ Confidence levels agregados para estaciones y trenes
- ❌ Migrar `linea` a 'L1'/'L2'
- ❌ Migrar `direccion` a 'A'/'B'
- ❌ Renombrar colección `trains/` a `train_state/`

## 📊 Estadísticas del Codebase

| Métrica              | Valor        |
| -------------------- | ------------ |
| Archivos Dart (lib/) | ~140         |
| Modelos              | 15           |
| Servicios            | 43           |
| Providers            | 4            |
| Screens (grupos)     | 13           |
| Widgets              | 33+          |
| Utilidades           | 7            |
| Cloud Functions      | 4            |
| Dashboard (web)      | ~40 archivos |
| Docs (legacy)        | 51 archivos  |
