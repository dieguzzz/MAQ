---
title: Estructura de Carpetas
type: architecture
tags: [architecture, folder-structure]
last-updated: 2026-02-13
---

# Estructura de Carpetas

## Raíz del proyecto

```
MAQ/
├── lib/                    # Código fuente Flutter
│   ├── main.dart           # Entry point + MultiProvider setup
│   ├── firebase_options.dart
│   ├── data/               # Datos estáticos (estaciones)
│   ├── models/             # 15 modelos de datos
│   ├── providers/          # 4 providers (state mgmt)
│   ├── services/           # 43 servicios de negocio
│   ├── screens/            # 13 grupos de pantallas
│   ├── widgets/            # 33+ widgets reutilizables
│   ├── utils/              # 7 utilidades
│   └── theme/              # Tema MetroPTY
├── dashboard/              # Dashboard web admin (HTML/CSS/JS)
├── functions/              # Cloud Functions (Node.js)
├── assets/                 # Imágenes e íconos
├── docs/                   # Documentación legacy (51 archivos)
├── .context/               # Este vault de contexto
├── android/                # Config nativa Android
├── ios/                    # Config nativa iOS
├── web/                    # Config web
├── test/                   # Tests
├── firebase.json           # Config Firebase CLI
├── firestore.rules         # Reglas de seguridad
├── firestore.indexes.json  # Índices Firestore
└── pubspec.yaml            # Dependencias
```

## Screens (13 grupos)

```
screens/
├── admin/          # Panel admin (2 screens)
├── auth/           # Login (1)
├── gamification/   # Perfil gamificación (3)
├── home/           # Pantalla principal + mapa (3)
├── leaderboards/   # Rankings (1)
├── learning/       # Machine learning admin (1)
├── legal/          # Términos y privacidad (2)
├── onboarding/     # Primer uso (1)
├── premium/        # Suscripción (1)
├── profile/        # Perfil usuario (4)
├── reports/        # Historial reportes (4)
├── routes/         # Planificador rutas (2)
└── settings/       # Configuración (2)
```

## Widgets clave

| Widget                               | Tamaño | Descripción                    |
| ------------------------------------ | ------ | ------------------------------ |
| `custom_metro_map.dart`              | 82KB   | Widget principal del mapa      |
| `station_report_sheet.dart`          | 83KB   | Bottom sheet reportes estación |
| `station_report_flow_widget.dart`    | 44KB   | Flujo de reporte de estación   |
| `confirm_reports_sheet.dart`         | 28KB   | Sheet para confirmar reportes  |
| `train_time_report_flow_widget.dart` | 27KB   | Flujo reportes de tren         |
| `quick_report_sheet.dart`            | 19KB   | Reporte rápido                 |
