---
title: Flujo de Datos
type: architecture
tags: [architecture, data-flow]
last-updated: 2026-02-13
---

# Flujo de Datos

## Patrón MVC con Provider

```
┌─────────────────────────────────────────┐
│           UI Layer (Screens)            │
│  home_screen, report_screen, etc.       │
└──────────────┬──────────────────────────┘
               │ consume / listen
┌──────────────▼──────────────────────────┐
│      State Management (Providers)       │
│  AuthProvider, MetroDataProvider, etc.  │
│  extends ChangeNotifier                 │
└──────────────┬──────────────────────────┘
               │ call methods
┌──────────────▼──────────────────────────┐
│         Business Logic (Services)       │
│  FirebaseService, GamificationService   │
│  (singletons / static methods)          │
└──────────────┬──────────────────────────┘
               │ CRUD
┌──────────────▼──────────────────────────┐
│         Data Layer                      │
│  Firestore, Models (fromFirestore/      │
│  toFirestore)                           │
└─────────────────────────────────────────┘
```

## Flujo típico de una acción

1. **Usuario toca** → Screen llama método del Provider
2. **Provider** → Llama al Service correspondiente
3. **Service** → Hace CRUD en Firestore
4. **Firestore Stream** → Notifica al Provider
5. **Provider** → `notifyListeners()`
6. **Screen** → Se reconstruye con nuevos datos

## Streams en tiempo real

- `MetroDataProvider` mantiene streams de estaciones, trenes y reportes
- `AuthProvider` mantiene stream de auth state
- `LocationProvider` mantiene stream de ubicación GPS
- `ReportProvider` mantiene stream de reportes activos

## Inyección de dependencias

- Los providers se registran en `main.dart` con `MultiProvider`
- Los services se acceden como singletons o métodos estáticos
- `FirebaseService` es el servicio central que habla con Firestore
