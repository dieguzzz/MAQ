# Configuración Paso a Paso - MetroPTY

## ✅ Paso 1: Dependencias Instaladas

Las dependencias de Flutter ya están instaladas correctamente.

## 📱 Paso 2: Configurar Firebase

### 2.1 Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Nombre del proyecto: `MetroPTY` (o el que prefieras)
4. Desactiva Google Analytics (opcional) o actívalo si lo deseas
5. Haz clic en "Crear proyecto"

### 2.2 Configurar Firebase para Android

1. En Firebase Console, haz clic en el ícono de Android
2. **Package name**: `com.metropty.app` (o el que prefieras, debe coincidir con `android/app/build.gradle`)
3. **App nickname**: MetroPTY Android (opcional)
4. Haz clic en "Registrar app"
5. Descarga el archivo `google-services.json`
6. **Coloca el archivo en**: `android/app/google-services.json`

### 2.3 Configurar Firebase para iOS

1. En Firebase Console, haz clic en el ícono de iOS
2. **Bundle ID**: `com.metropty.app` (debe coincidir con el de Xcode)
3. **App nickname**: MetroPTY iOS (opcional)
4. Haz clic en "Registrar app"
5. Descarga el archivo `GoogleService-Info.plist`
6. **Coloca el archivo en**: `ios/Runner/GoogleService-Info.plist`

### 2.4 Habilitar Servicios en Firebase

1. **Authentication**:
   - Ve a Authentication > Sign-in method
   - Habilita "Email/Password"
   - Guarda los cambios

2. **Cloud Firestore**:
   - Ve a Firestore Database
   - Haz clic en "Crear base de datos"
   - Selecciona "Modo de prueba" (luego actualiza las reglas)
   - Selecciona la ubicación más cercana (ej: us-central1)
   - Haz clic en "Habilitar"

3. **Cloud Messaging**:
   - Ve a Cloud Messaging
   - Ya está habilitado por defecto

### 2.5 Configurar Reglas de Firestore

1. Ve a Firestore Database > Reglas
2. Copia el contenido del archivo `firestore.rules` del proyecto
3. Pega las reglas en Firebase Console
4. Haz clic en "Publicar"

## 🗺️ Paso 3: Configurar Google Maps

### 3.1 Obtener API Key

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Ve a "APIs y servicios" > "Biblioteca"
4. Busca y habilita:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Places API** (opcional, para búsqueda de lugares)

### 3.2 Crear API Key

1. Ve a "APIs y servicios" > "Credenciales"
2. Haz clic en "Crear credenciales" > "Clave de API"
3. Copia la API Key generada
4. (Opcional) Restringe la clave por aplicación para mayor seguridad

### 3.3 Configurar API Key en Android

1. Abre el archivo: `android/app/src/main/AndroidManifest.xml`
2. Agrega dentro de `<application>`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="TU_API_KEY_AQUI"/>
   ```

### 3.4 Configurar API Key en iOS

1. Abre el archivo: `ios/Runner/AppDelegate.swift`
2. Agrega al inicio del archivo (después de los imports):
   ```swift
   import GoogleMaps
   ```
3. En el método `application(_:didFinishLaunchingWithOptions:)`, agrega:
   ```swift
   GMSServices.provideAPIKey("TU_API_KEY_AQUI")
   ```

## 📝 Paso 4: Verificar Configuración

### 4.1 Verificar AndroidManifest.xml

El archivo debe tener estos permisos:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 4.2 Verificar Info.plist (iOS)

El archivo debe tener estas claves:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrar el estado del metro</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Necesitamos tu ubicación para actualizar reportes en tiempo real</string>
```

## 🚀 Paso 5: Probar la Aplicación

1. Conecta un dispositivo o inicia un emulador
2. Ejecuta:
   ```bash
   flutter run
   ```

## ⚠️ Solución de Problemas

### Error: "google-services.json not found"
- Verifica que el archivo esté en `android/app/google-services.json`
- Verifica que el package name coincida

### Error: "API Key not valid"
- Verifica que la API Key esté correctamente configurada
- Verifica que las APIs estén habilitadas en Google Cloud Console

### Error: "Permission denied"
- Verifica los permisos en AndroidManifest.xml e Info.plist
- Asegúrate de solicitar permisos en tiempo de ejecución

## 📚 Recursos Adicionales

- [Documentación de Firebase Flutter](https://firebase.flutter.dev/)
- [Documentación de Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Guía de Geolocator](https://pub.dev/packages/geolocator)

