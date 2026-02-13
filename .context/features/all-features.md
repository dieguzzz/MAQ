---
title: Features - Resumen de todas las funcionalidades
type: feature
tags: [feature]
last-updated: 2026-02-13
---

# Features Implementadas

## 🗺️ Mapa Interactivo

- Google Maps con overlay personalizado
- Líneas dibujadas como polylines (L1 azul, L2 verde)
- Estaciones como marcadores circulares con color por estado
- Trenes virtuales animados moviéndose sobre las líneas
- Tocar estación → bottom sheet con detalles y opción reportar
- Tocar tren → info de velocidad, ocupación, estado
- Widget: `custom_metro_map.dart` (82KB, el más grande)

## 📝 Sistema de Reportes

**Dos sistemas coexisten** (ver [[report-models]]):

- **Legacy** (`ReportModel`): Más campos, categorías, verificación
- **Simplificado** (`SimplifiedReportModel`): scope-based, más limpio

**Flujo de reporte**:

1. Seleccionar estación/tren → elegir estado → problemas opcionales → enviar
2. Validación: GPS ≤500m, no duplicados en 5min, autenticado
3. Cloud Function verifica automaticamente (2+ similares = `verified`)
4. 3+ confirmaciones manuales = `community_verified`

## 🏆 Gamificación

- **Puntos**: reporte verificado (10), confirmar (5), épico (100), racha (2)
- **50 niveles** con nombres del Metro (Pasajero → Leyenda)
- **Badges**: 19 tipos (precisión, rachas, eventos culturales, comunidad)
- **Rachas**: días consecutivos reportando, badges a 7 y 30 días
- **Rankings**: global, por línea, por categoría (top 100)

## 🗂️ Planificador de Rutas

- Seleccionar origen → destino → ruta óptima
- Tiempo estimado + estado de la ruta
- Considera retrasos e incidencias activas

## 🔔 Notificaciones

- **Push** (FCM): reportes críticos a usuarios cercanos (5km)
- **In-app**: badges, niveles, verificaciones
- **Tipos críticos**: lleno, cerrado, detenido, sardina

## 💰 Ads y Monetización

- **Banner**: fijo en la parte inferior del mapa
- **Interstitial**: pantalla completa, max 1/120s, solo baja fricción
- **Rewarded**: quitar ads 1h, duplicar puntos 30min
- **Suscripción**: premium features (in_app_purchase)

## 🛠️ Modo Desarrollo

- Activación: **7 taps** en el logo
- Simulador de ubicación GPS
- Editor de posiciones de estaciones
- Escenarios de test predefinidos
- Modo test para reportes sin impactar prod
