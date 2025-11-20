# MetroPTY - App de Estado del Metro en Tiempo Real

Aplicación colaborativa para conocer el estado en tiempo real del Metro de Panamá mediante reportes de usuarios.

## 🚀 Inicio Rápido

### Clonar el Repositorio

```bash
git clone https://github.com/dieguzzz/MAQ.git
cd MAQ
flutter pub get
```

### Configuración Inicial

1. **Configurar Firebase**: Ver `FIREBASE_SETUP.md`
2. **Configurar Google Maps**: Ver `CONFIGURACION_PASO_A_PASO.md`
3. **Ejecutar**: `flutter run`

## 📚 Documentación

- **[GUIA_OTRA_COMPUTADORA.md](GUIA_OTRA_COMPUTADORA.md)** - Guía para trabajar desde otra computadora
- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Configuración detallada de Firebase
- **[CONFIGURACION_PASO_A_PASO.md](CONFIGURACION_PASO_A_PASO.md)** - Configuración paso a paso
- **[SETUP.md](SETUP.md)** - Guía de configuración general
- **[ESTADO_ACTUAL.md](ESTADO_ACTUAL.md)** - Estado del proyecto

## 🛠️ Stack Tecnológico

- **Frontend**: Flutter
- **Backend**: Firebase (Firestore, Auth, Cloud Messaging)
- **Mapas**: Google Maps Platform
- **Estado**: Provider

## 📱 Funcionalidades

- 🗺️ Mapa en tiempo real con estado de estaciones y trenes
- 📝 Sistema de reportes colaborativos
- 🚇 Planificador de rutas
- 🔔 Notificaciones push
- ⭐ Sistema de reputación de usuarios

## 📋 Requisitos

- Flutter SDK (>=3.0.0)
- Android Studio (para Android)
- Xcode (para iOS - solo Mac)
- Cuenta de Firebase
- API Key de Google Maps

## 🔧 Instalación

```bash
# 1. Clonar repositorio
git clone https://github.com/dieguzzz/MAQ.git
cd MAQ

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase (ver FIREBASE_SETUP.md)
# 4. Configurar Google Maps (ver CONFIGURACION_PASO_A_PASO.md)
# 5. Ejecutar
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
  models/          # Modelos de datos
  services/        # Servicios (Firebase, Location, etc.)
  providers/       # State management con Provider
  screens/         # Pantallas de la aplicación
  widgets/         # Widgets reutilizables
  utils/           # Utilidades y constantes
```

## 🔐 Seguridad

Los archivos sensibles están en `.gitignore`:
- `google-services.json`
- `GoogleService-Info.plist`
- API Keys

Debes descargarlos desde Firebase Console y Google Cloud Console.

## 📝 Licencia

Este proyecto es privado.

## 👤 Autor

Diego - [GitHub](https://github.com/dieguzzz)

---

**Para más información, consulta la documentación en los archivos `.md` del proyecto.**
