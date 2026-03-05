---
title: Stack Tecnológico
type: architecture
tags: [architecture, stack]
last-updated: 2026-02-13
---

# Stack Tecnológico

## Frontend

| Componente | Tecnología                   | Versión            |
| ---------- | ---------------------------- | ------------------ |
| Framework  | Flutter                      | SDK >=3.0.0 <4.0.0 |
| Lenguaje   | Dart                         | 3.x                |
| State Mgmt | Provider                     | ^6.1.1             |
| Mapas      | google_maps_flutter          | ^2.5.0             |
| Ubicación  | geolocator                   | ^14.0.2            |
| Fonts      | google_fonts                 | ^6.1.0             |
| UI Icons   | cupertino_icons, flutter_svg | -                  |

## Backend (Firebase)

| Servicio       | Paquete            | Versión |
| -------------- | ------------------ | ------- |
| Core           | firebase_core      | ^4.3.0  |
| Database       | cloud_firestore    | ^6.1.1  |
| Auth           | firebase_auth      | ^6.1.3  |
| Messaging      | firebase_messaging | ^16.1.0 |
| Storage        | firebase_storage   | ^13.0.5 |
| Functions      | cloud_functions    | ^6.0.5  |
| Google Sign-In | google_sign_in     | ^7.2.0  |

## Monetización

| Componente | Paquete           | Versión |
| ---------- | ----------------- | ------- |
| Ads        | google_mobile_ads | ^7.0.0  |
| IAP        | in_app_purchase   | ^3.2.0  |

## Utilidades

| Componente     | Paquete                             |
| -------------- | ----------------------------------- |
| HTTP           | http ^1.1.0                         |
| URLs           | url_launcher ^6.2.0                 |
| Storage local  | shared_preferences ^2.2.2           |
| Notificaciones | flutter_local_notifications ^19.5.0 |
| Cámara         | image_picker ^1.0.7                 |
| Settings       | app_settings ^5.1.1                 |

## Dashboard Web

- HTML/CSS/JS estático en `dashboard/`
- Se despliega en Firebase Hosting
