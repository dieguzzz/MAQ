# MetroPTY - App de Estado del Metro en Tiempo Real

Aplicación colaborativa para conocer el estado en tiempo real del Metro de Panamá mediante reportes de usuarios.

## Stack Tecnológico

- **Frontend**: Flutter
- **Backend**: Firebase (Firestore, Auth, Cloud Messaging)
- **Mapas**: Google Maps Platform
- **Estado**: Provider

## Configuración Inicial

1. Instalar dependencias:
```bash
flutter pub get
```

2. Configurar Firebase:
   - Agregar archivos de configuración Firebase (`google-services.json` para Android, `GoogleService-Info.plist` para iOS)
   - Configurar las reglas de seguridad de Firestore

3. Configurar Google Maps:
   - Obtener API key de Google Maps Platform
   - Agregar la key en los archivos de configuración de Android/iOS

## Estructura del Proyecto

```
lib/
  models/          # Modelos de datos
  services/        # Servicios (Firebase, Location, etc.)
  providers/       # State management con Provider
  screens/         # Pantallas de la aplicación
  widgets/         # Widgets reutilizables
  utils/           # Utilidades y constantes
```

## Funcionalidades

- 🗺️ Mapa en tiempo real con estado de estaciones y trenes
- 📝 Sistema de reportes colaborativos
- 🚇 Planificador de rutas
- 🔔 Notificaciones push
- ⭐ Sistema de reputación de usuarios

