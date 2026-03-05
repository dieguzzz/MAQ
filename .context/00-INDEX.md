---
title: MetroPTY - Índice Principal
type: index
last-updated: 2026-02-13
---

# 🚇 MetroPTY — Context Vault

## Quick Context (lee esto primero)

**MetroPTY** es una app móvil colaborativa (estilo Waze) para el **Metro de Panamá**.
Los usuarios reportan el estado en tiempo real de estaciones y trenes.

| Aspecto     | Detalle                                                   |
| ----------- | --------------------------------------------------------- |
| **Stack**   | Flutter/Dart + Firebase (Firestore, Auth, FCM, Functions) |
| **Mapas**   | Google Maps SDK + Custom Overlays                         |
| **Estado**  | Provider (ChangeNotifier)                                 |
| **Ads**     | Google AdMob (Banner, Interstitial, Rewarded)             |
| **Repo**    | `c:\Users\Diegu\MAQ`                                      |
| **Package** | `metropty`                                                |
| **SDK**     | Dart >=3.0.0 <4.0.0                                       |

### Líneas del Metro

- **Línea 1**: 14 estaciones (Albrook → San Isidro)
- **Línea 2**: 8 estaciones (Nuevo Tocumen → San Miguelito)

### Colecciones Firestore

- `users/{uid}` — Perfil + gamificación
- `stations/{stationId}` — Estado en tiempo real
- `trains/{trainId}` — Trenes virtuales
- `reports/{reportId}` — Reportes de usuarios
- `simplified_reports/{id}` — Sistema nuevo de reportes

### Patrón de Arquitectura

```
Screens → Providers → Services → Firebase/Models
```

---

## 📂 Maps of Content (MOCs)

### Arquitectura y Código

- [[architecture/_MOC]] — Stack, patrones, flujo de datos, estructura de carpetas
- [[models/_MOC]] — Modelos de datos (User, Station, Train, Report, etc.)
- [[services/_MOC]] — Servicios de negocio (43 servicios)
- [[providers/_MOC]] — State management (4 providers)

### Firebase y Backend

- [[firebase/_MOC]] — Colecciones, reglas, Cloud Functions, config

### Features

- [[features/_MOC]] — Mapa, reportes, gamificación, rutas, notificaciones

### Dashboard

- [[dashboard/_MOC]] — Dashboard web admin

### Decisiones y Estado

- [[decisions/_MOC]] — Contratos de nombres, ADRs
- [[state/current-status]] — ✅ Qué está hecho, ⚠️ parcial, ❌ pendiente
- [[state/known-issues]] — Bugs y problemas conocidos
- [[state/pending-work]] — Trabajo pendiente (MVP)

---

## 🏷️ Tags Rápidos

- `#model` — Modelos de datos
- `#service` — Servicios
- `#provider` — Providers
- `#firebase` — Todo Firebase
- `#feature` — Features de la app
- `#pending` — Cosas pendientes
- `#best-practice` — Buenas prácticas del proyecto

---

## 🔄 Regla de Auto-Actualización

> **OBLIGATORIO**: Al terminar un módulo, feature, o cambio significativo, el AI DEBE
> ejecutar `/update-context` para mantener este vault sincronizado con el código.
>
> Esto incluye:
>
> - Al completar una tarea o módulo
> - Antes de cada commit
> - Al agregar/eliminar servicios, modelos, o providers
> - Al cambiar esquemas de Firestore
>
> **No se considera terminado el trabajo hasta que el vault esté actualizado.**
