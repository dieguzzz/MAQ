# 👥 Guía para Colaboradores - MetroPTY

## 📋 Lo que necesitas después de clonar el repositorio

### ✅ Paso 1: Instalar Dependencias

```bash
cd MAQ
flutter pub get
```

---

## 🔥 Paso 2: Configurar Firebase

### Opción A: Usar el mismo proyecto de Firebase (Recomendado para desarrollo)

**Necesitas que el dueño del proyecto te comparta:**

1. **Archivo `google-services.json`** (para Android)
   - Ubicación: `android/app/google-services.json`
   - El dueño debe descargarlo desde Firebase Console y compartirlo contigo

2. **Archivo `GoogleService-Info.plist`** (para iOS, si desarrollas para iOS)
   - Ubicación: `ios/Runner/GoogleService-Info.plist`
   - El dueño debe descargarlo desde Firebase Console y compartirlo contigo

3. **Archivo `firebase_options.dart`**
   - Ubicación: `lib/firebase_options.dart`
   - El dueño debe compartir este archivo contigo

**⚠️ IMPORTANTE:** Estos archivos contienen credenciales sensibles. Compártelos de forma segura (no los subas a GitHub).

### Opción B: Crear tu propio proyecto de Firebase

Si prefieres usar tu propio proyecto:

1. **Crear proyecto en Firebase Console**
   - Ve a https://console.firebase.google.com/
   - Crea un nuevo proyecto
   - Sigue las instrucciones en `FIREBASE_SETUP.md`

2. **Configurar Android**
   - Agrega app Android con package name: `com.example.metropty`
   - Descarga `google-services.json` y colócalo en `android/app/`

3. **Configurar iOS** (si desarrollas para iOS)
   - Agrega app iOS con bundle ID: `com.example.metropty`
   - Descarga `GoogleService-Info.plist` y colócalo en `ios/Runner/`

4. **Generar firebase_options.dart**
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

5. **Habilitar servicios en Firebase**
   - Authentication → Email/Password → Habilitar
   - Firestore Database → Crear base de datos
   - Cloud Messaging (ya está habilitado)

6. **Configurar reglas de Firestore**
   - Copia el contenido de `firestore.rules` a Firebase Console > Firestore > Rules

---

## 🗺️ Paso 3: Configurar Google Maps

### Opción A: Usar la misma API Key (Recomendado para desarrollo)

**Necesitas que el dueño del proyecto te comparta:**

- **API Key de Google Maps**
  - Actualmente configurada en: `android/app/src/main/AndroidManifest.xml` (línea 43)
  - Valor: `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc`
  - ⚠️ **IMPORTANTE:** Esta API Key puede tener restricciones. Si no funciona, usa la Opción B.

### Opción B: Crear tu propia API Key

1. **Crear API Key en Google Cloud Console**
   - Ve a https://console.cloud.google.com/
   - Selecciona el mismo proyecto de Firebase (o crea uno nuevo)
   - Ve a "APIs y servicios" > "Credenciales"
   - Crea una nueva "Clave de API"

2. **Habilitar APIs necesarias**
   - Maps SDK for Android
   - Maps SDK for iOS (si desarrollas para iOS)

3. **Configurar en Android**
   - Edita `android/app/src/main/AndroidManifest.xml`
   - Reemplaza la línea 43 con tu API Key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="TU_API_KEY_AQUI"/>
   ```

4. **Configurar en iOS** (si desarrollas para iOS)
   - Edita `ios/Runner/AppDelegate.swift`
   - Reemplaza la API Key con la tuya

---

## 📱 Paso 4: Configurar AdMob (Opcional)

Si quieres probar los anuncios:

**Necesitas que el dueño del proyecto te comparta:**

- **AdMob App ID**
  - Actualmente configurado en: `android/app/src/main/AndroidManifest.xml` (línea 49)
  - Valor: `ca-app-pub-8674103204445992~9711238018`

O crea tu propio proyecto de AdMob y reemplaza el App ID.

---

## 📦 Paso 5: Colocar los Archivos Recibidos

Una vez que recibas los archivos del dueño del proyecto:

### 5.1 Colocar `google-services.json` (Android)

1. **Abre el archivo que recibiste** (debe llamarse `google-services.json`)
2. **Cópialo a la ubicación correcta:**
   ```bash
   # Desde la raíz del proyecto (MAQ)
   # Copia el archivo a:
   android/app/google-services.json
   ```
3. **Verifica que esté en el lugar correcto:**
   ```bash
   # Debe existir el archivo
   ls android/app/google-services.json
   # O en Windows PowerShell:
   Test-Path android/app/google-services.json
   ```

### 5.2 Colocar `GoogleService-Info.plist` (iOS - Solo si desarrollas para iOS)

1. **Abre el archivo que recibiste** (debe llamarse `GoogleService-Info.plist`)
2. **Cópialo a la ubicación correcta:**
   ```bash
   # Desde la raíz del proyecto (MAQ)
   # Copia el archivo a:
   ios/Runner/GoogleService-Info.plist
   ```

### 5.3 Colocar `firebase_options.dart`

1. **Abre el archivo que recibiste** (debe llamarse `firebase_options.dart`)
2. **Cópialo a la ubicación correcta:**
   ```bash
   # Desde la raíz del proyecto (MAQ)
   # Copia el archivo a:
   lib/firebase_options.dart
   ```
3. **⚠️ IMPORTANTE:** Este archivo reemplaza el que ya existe (si existe)

---

## ✅ Paso 6: Verificar y Ejecutar

### 6.1 Limpiar el proyecto

```bash
# Limpiar caché de Flutter
flutter clean

# Reinstalar dependencias
flutter pub get
```

### 6.2 Verificar que no hay errores

```bash
# Analizar el código
flutter analyze
```

Si hay errores, verifica que:
- Los archivos estén en las ubicaciones correctas
- Los nombres de los archivos sean exactos (sin espacios adicionales)
- Tengas Flutter instalado correctamente

### 6.3 Ejecutar la aplicación

```bash
# Ejecutar en dispositivo/emulador conectado
flutter run

# O si tienes múltiples dispositivos, selecciona uno:
flutter devices
flutter run -d <device-id>
```

### 6.4 Verificar que funciona

Cuando la app se ejecute, deberías poder:
- ✅ Ver la pantalla de login/registro
- ✅ Ver el mapa (si tienes permisos de ubicación)
- ✅ Hacer login con email/password
- ✅ Ver las estaciones del metro

---

## 🎯 Paso 7: Empezar a Desarrollar

Una vez que la app funciona:

1. **Explora el código:**
   - `lib/screens/` - Pantallas de la app
   - `lib/widgets/` - Componentes reutilizables
   - `lib/services/` - Servicios (Firebase, Location, etc.)
   - `lib/models/` - Modelos de datos

2. **Lee la documentación:**
   - `ESTADO_ACTUAL.md` - Estado actual del proyecto
   - `RESUMEN_PROYECTO.md` - Resumen de funcionalidades

3. **Haz cambios y prueba:**
   ```bash
   # Flutter tiene hot reload - los cambios se reflejan automáticamente
   # Presiona 'r' en la terminal para hot reload
   # Presiona 'R' para hot restart
   ```

---

## 🔧 Comandos Útiles

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en modo release (más rápido)
flutter run --release

# Ver logs detallados
flutter run --verbose

# Actualizar dependencias
flutter pub upgrade

# Verificar configuración de Flutter
flutter doctor
```

---

## 📝 Resumen de Archivos que Necesitas

### Archivos que el dueño debe compartirte:

1. ✅ `android/app/google-services.json` (Firebase Android)
2. ✅ `ios/Runner/GoogleService-Info.plist` (Firebase iOS - opcional)
3. ✅ `lib/firebase_options.dart` (Configuración de Firebase)
4. ℹ️ API Key de Google Maps (o crear la tuya)
5. ℹ️ AdMob App ID (opcional, o crear el tuyo)

### Archivos que YA están en el repositorio:

- ✅ `firestore.rules` (reglas de Firestore)
- ✅ `pubspec.yaml` (dependencias)
- ✅ Todo el código fuente
- ✅ Configuraciones de permisos

---

## 🔐 Seguridad

**⚠️ NUNCA subas estos archivos a GitHub:**
- `google-services.json`
- `GoogleService-Info.plist`
- `firebase_options.dart`
- API Keys en código (aunque actualmente están hardcodeadas)

Estos archivos están en `.gitignore` por seguridad.

---

## 🆘 Solución de Problemas

### Problema: "google-services.json not found"

**Solución:**
1. Verifica que el archivo esté en `android/app/google-services.json`
2. Verifica que el nombre del archivo sea exactamente `google-services.json` (sin espacios)
3. Ejecuta `flutter clean` y luego `flutter pub get`

### Problema: "FirebaseOptions not found"

**Solución:**
1. Verifica que `lib/firebase_options.dart` exista
2. Verifica que el archivo tenga el contenido correcto (no esté vacío)
3. Ejecuta `flutter clean` y luego `flutter pub get`

### Problema: "Google Maps no se muestra"

**Solución:**
1. Verifica que la API Key esté en `AndroidManifest.xml` (línea 43)
2. Verifica que la API Key tenga habilitado "Maps SDK for Android" en Google Cloud Console
3. Espera 5-10 minutos después de habilitar la API (propagación)

### Problema: "Error de compilación"

**Solución:**
1. Ejecuta `flutter clean`
2. Ejecuta `flutter pub get`
3. Ejecuta `flutter doctor` para verificar que todo esté bien
4. Si el problema persiste, contacta al dueño del proyecto

### Problema: "No puedo hacer login"

**Solución:**
1. Verifica que Authentication esté habilitado en Firebase Console
2. Verifica que Email/Password esté habilitado como método de autenticación
3. Verifica que las reglas de Firestore permitan lectura/escritura

---

## 📚 Documentación Adicional

Si necesitas más información, revisa:
- `FIREBASE_SETUP.md` - Configuración detallada de Firebase
- `CONFIGURACION_PASO_A_PASO.md` - Configuración paso a paso
- `SETUP.md` - Guía de configuración general
- `ESTADO_ACTUAL.md` - Estado actual del proyecto

---

## 📞 Contacto

Si tienes problemas, contacta al dueño del proyecto para que te comparta los archivos de configuración necesarios.

