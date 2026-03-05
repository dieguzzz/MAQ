---
title: Patrones de Diseño
type: architecture
tags: [architecture, patterns, best-practice]
last-updated: 2026-02-13
---

# Patrones de Diseño

## MVC con Provider

- **Model**: Clases en `lib/models/` con `fromFirestore()` y `toFirestore()`
- **View**: Screens en `lib/screens/` y widgets en `lib/widgets/`
- **Controller**: Providers en `lib/providers/` + Services en `lib/services/`

## Provider Pattern (State Management)

- Se usa `ChangeNotifier` con `notifyListeners()`
- Providers se registran en `main.dart` con `MultiProvider`
- Consumers usan `Provider.of<T>(context)` o `context.watch<T>()`

### Los 4 Providers

| Provider            | Responsabilidad                         |
| ------------------- | --------------------------------------- |
| `AuthProvider`      | Auth state, login/logout, user data     |
| `MetroDataProvider` | Streams de estaciones, trenes, reportes |
| `LocationProvider`  | GPS, permisos, ubicación actual         |
| `ReportProvider`    | CRUD de reportes, confirmaciones        |

## Modelo Firestore

- Cada modelo tiene `factory fromFirestore(DocumentSnapshot doc)`
- Cada modelo tiene `Map<String, dynamic> toFirestore()`
- Nombres de campos en Firestore usan `snake_case`
- Nombres de campos en Dart usan `camelCase`
- Los Timestamps se convierten a DateTime y viceversa
- Los GeoPoint se mantienen como está (cloud_firestore)

## Singleton Pattern

- Algunos services se acceden como singletons o métodos estáticos
- `FirebaseService` es el servicio centralizado para Firestore

## Enum Pattern

- Estados tipados como enums Dart (`EstadoEstacion`, `EstadoTren`, etc.)
- Funciones `_parse...()` y `_...ToString()` para conversión String↔Enum
- Permite switch exhaustivo y type-safety

## Error Handling

- `ErrorHandlerService` centraliza el manejo de errores
- `DebugLogService` para logging en desarrollo
- Try/catch en providers, errores se propagan con contexto
