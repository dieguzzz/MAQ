---
title: User Model
type: model
status: implemented
tags: [model, firestore, user, gamification]
source: lib/models/user_model.dart
collection: users/{uid}
last-updated: 2026-02-13
---

# User Model

> Perfil de usuario con datos de autenticación, reputación y gamificación.

## Campos

| Campo           | Tipo               | Default  | Descripción                        |
| --------------- | ------------------ | -------- | ---------------------------------- |
| uid             | String             | required | ID único (Firebase Auth UID)       |
| email           | String             | required | Email del usuario                  |
| nombre          | String             | required | Nombre display                     |
| fotoUrl         | String?            | null     | URL foto de perfil                 |
| reputacion      | int                | 50       | Reputación (1-100)                 |
| reportesCount   | int                | 0        | Total reportes realizados          |
| precision       | double             | 0.0      | Precisión (0.0-100.0)              |
| creadoEn        | DateTime           | required | Fecha creación                     |
| ultimaUbicacion | GeoPoint?          | null     | Última ubicación                   |
| gamification    | GamificationStats? | null     | Stats de gamificación (sub-objeto) |
| appMode         | String?            | null     | 'development' o 'test'             |

## Campos derivados (getters)

- `level` → int (1-50) calculado con `LevelService.calculateLevel(puntos)`
- `levelName` → String con emoji del nivel
- `levelProgress` → double (0.0-1.0) progreso al siguiente nivel

## Firestore mapping

| Dart            | Firestore             |
| --------------- | --------------------- |
| fotoUrl         | foto_url              |
| reportesCount   | reportes_count        |
| creadoEn        | creado_en (Timestamp) |
| ultimaUbicacion | ultima_ubicacion      |
| appMode         | app_mode              |

## Tiene `copyWith()` ✅
