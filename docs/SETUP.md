# Guía de Configuración - MetroPTY

## Requisitos Previos

1. Flutter SDK (última versión estable)
2. Cuenta de Firebase
3. Cuenta de Google Cloud Platform (para Google Maps)

## Pasos de Configuración

### 1. Configurar Firebase

1. Crear un nuevo proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Habilitar los siguientes servicios:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Messaging

3. **Para Android:**
   - Agregar app Android en Firebase Console
   - Descargar `google-services.json`
   - Colocar en `android/app/google-services.json`

4. **Para iOS:**
   - Agregar app iOS en Firebase Console
   - Descargar `GoogleService-Info.plist`
   - Colocar en `ios/Runner/GoogleService-Info.plist`

5. Configurar reglas de Firestore:
   - Copiar el contenido de `firestore.rules` a Firebase Console > Firestore > Rules

### 2. Configurar Google Maps

1. Obtener API Key de [Google Cloud Console](https://console.cloud.google.com/)
2. Habilitar las siguientes APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API (opcional)

3. **Para Android:**
   - Agregar en `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="TU_API_KEY_AQUI"/>
   ```

4. **Para iOS:**
   - Agregar en `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("TU_API_KEY_AQUI")
   ```

### 3. Instalar Dependencias

```bash
flutter pub get
```

### 4. Configurar Permisos

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrar el estado del metro</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Necesitamos tu ubicación para actualizar reportes en tiempo real</string>
```

### 5. Cloud Functions (Opcional - Para producción)

Las Cloud Functions mencionadas en la especificación deben implementarse por separado:

- `onUserLocationUpdate`: Actualizar estado de trenes/estaciones
- `onNewReport`: Procesar y validar reportes
- `calculateRouteTime`: Calcular tiempos de ruta
- `verifyReports`: Verificar reportes antiguos (cron job)

### 6. Ejecutar la Aplicación

```bash
flutter run
```

## Estructura de Datos Inicial

La aplicación inicializará automáticamente las estaciones del Metro de Panamá en Firestore al primer inicio.

## Notas Importantes

- Las coordenadas de las estaciones en `metro_data.dart` son aproximadas y deben actualizarse con las coordenadas reales
- Las Cloud Functions deben implementarse para funcionalidad completa
- Configurar notificaciones push requiere configuración adicional en Firebase Console

