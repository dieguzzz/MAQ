---
title: Providers - Map of Content
type: moc
tags: [provider, state, moc]
last-updated: 2026-02-13
---

# 🔄 Providers (State Management)

4 providers en `lib/providers/`, todos extienden `ChangeNotifier`.

## AuthProvider (12KB)

**Archivo**: `auth_provider.dart`
**Responsabilidad**: Autenticación y datos de usuario

- Login/logout con Email/Password y Google Sign-In
- Stream de auth state
- Gestión de perfil de usuario
- Modo dev/test toggle

## MetroDataProvider (14KB)

**Archivo**: `metro_data_provider.dart`
**Responsabilidad**: Datos del metro en tiempo real

- Streams de estaciones (Firestore)
- Streams de trenes (Firestore)
- Streams de reportes activos
- Datos estáticos de estaciones como fallback

## LocationProvider (7KB)

**Archivo**: `location_provider.dart`
**Responsabilidad**: Ubicación del usuario

- Permisos GPS
- Stream de posición actual
- Detección de estación más cercana
- Conversión Position → GeoPoint

## ReportProvider (14KB)

**Archivo**: `report_provider.dart`
**Responsabilidad**: CRUD de reportes

- Crear reporte (con validación)
- Confirmar reporte
- Stream de reportes del usuario
- Lógica de reporte rápido

## Registro en main.dart

Todos se registran con `MultiProvider` en el widget raíz.
