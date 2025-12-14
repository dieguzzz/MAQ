# 🔥 Guía Completa de Configuración de Firebase

## Opción 1: Firebase Console (Interfaz Web) - RECOMENDADO

### Paso 1: Crear Proyecto en Firebase Console

1. **Abre tu navegador** y ve a: https://console.firebase.google.com/
2. **Inicia sesión** con tu cuenta de Google
3. **Haz clic en "Agregar proyecto"** o "Add project"
4. **Ingresa el nombre del proyecto**: `MetroPTY` (o el que prefieras)
5. **Google Analytics** (opcional):
   - Puedes desactivarlo si no lo necesitas
   - O activarlo si quieres analíticas
6. **Haz clic en "Crear proyecto"**
7. **Espera** a que se cree el proyecto (30-60 segundos)

### Paso 2: Configurar App Android

1. En la página principal del proyecto, **haz clic en el ícono de Android** 📱
2. **Package name**: `com.example.metropty`
   - ⚠️ **IMPORTANTE**: Este debe coincidir con el `applicationId` en `android/app/build.gradle.kts`
3. **App nickname** (opcional): `MetroPTY Android`
4. **Haz clic en "Registrar app"**
5. **Descarga el archivo `google-services.json`**
6. **Coloca el archivo en**: `android/app/google-services.json`
   - ⚠️ Reemplaza el archivo `.example` si existe

### Paso 3: Configurar App iOS

1. En la página principal del proyecto, **haz clic en el ícono de iOS** 🍎
2. **Bundle ID**: `com.example.metropty`
   - ⚠️ **IMPORTANTE**: Este debe coincidir con el Bundle ID en Xcode
3. **App nickname** (opcional): `MetroPTY iOS`
4. **Haz clic en "Registrar app"**
5. **Descarga el archivo `GoogleService-Info.plist`**
6. **Coloca el archivo en**: `ios/Runner/GoogleService-Info.plist`
   - ⚠️ Reemplaza el archivo `.example` si existe

### Paso 4: Habilitar Authentication

1. En el menú lateral, ve a **"Authentication"** o **"Autenticación"**
2. Haz clic en **"Comenzar"** o **"Get started"**
3. Ve a la pestaña **"Sign-in method"** o **"Métodos de inicio de sesión"**
4. Haz clic en **"Email/Password"**
5. **Activa** el primer toggle (Email/Password)
6. **Haz clic en "Guardar"**

### Paso 5: Crear Base de Datos Firestore

1. En el menú lateral, ve a **"Firestore Database"** o **"Base de datos Firestore"**
2. Haz clic en **"Crear base de datos"** o **"Create database"**
3. Selecciona **"Comenzar en modo de prueba"** o **"Start in test mode"**
   - ⚠️ Luego actualizarás las reglas de seguridad
4. **Selecciona la ubicación** más cercana (ej: `us-central1`, `southamerica-east1`)
5. Haz clic en **"Habilitar"** o **"Enable"**
6. Espera a que se cree la base de datos (30-60 segundos)

### Paso 6: Configurar Reglas de Firestore

1. En Firestore Database, ve a la pestaña **"Reglas"** o **"Rules"**
2. **Abre el archivo** `firestore.rules` de tu proyecto
3. **Copia todo el contenido** del archivo
4. **Pega el contenido** en el editor de reglas de Firebase Console
5. Haz clic en **"Publicar"** o **"Publish"**

### Paso 7: Verificar Cloud Messaging

1. En el menú lateral, ve a **"Cloud Messaging"**
2. Ya está habilitado por defecto
3. No necesitas hacer nada adicional aquí

---

## Opción 2: Firebase CLI (Línea de Comandos)

### Instalación de Firebase CLI

```bash
# Instalar Firebase CLI globalmente
npm install -g firebase-tools

# O con Chocolatey (Windows)
choco install firebase-cli

# Verificar instalación
firebase --version
```

### Configuración con Firebase CLI

```bash
# 1. Iniciar sesión en Firebase
firebase login

# 2. Inicializar Firebase en tu proyecto
firebase init

# Durante la inicialización, selecciona:
# - Firestore: Yes
# - Authentication: Yes (opcional, puedes configurarlo después)
# - Storage: No (opcional)
# - Functions: No (por ahora)
# - Hosting: No (opcional)

# 3. Seleccionar el proyecto existente o crear uno nuevo
# - Si ya creaste el proyecto en la consola, selecciónalo
# - Si no, puedes crear uno nuevo desde aquí

# 4. Configurar Firestore
# - Usa las reglas del archivo firestore.rules existente
# - No sobrescribir el archivo si ya existe

# 5. Desplegar reglas de Firestore
firebase deploy --only firestore:rules
```

### Agregar Apps con Firebase CLI

```bash
# Agregar app Android
firebase apps:create ANDROID com.example.metropty

# Agregar app iOS  
firebase apps:create IOS com.example.metropty

# Descargar archivos de configuración
# Nota: Esto requiere que uses la consola web para descargar los archivos
```

---

## ⚠️ IMPORTANTE: Verificar Package Name / Bundle ID

Antes de descargar los archivos de configuración, verifica que coincidan:

### Android
- **Firebase Console**: Package name debe ser `com.example.metropty`
- **Tu proyecto**: Verifica en `android/app/build.gradle.kts` línea 24:
  ```kotlin
  applicationId = "com.example.metropty"
  ```

### iOS
- **Firebase Console**: Bundle ID debe ser `com.example.metropty`
- **Tu proyecto**: Verifica en Xcode o en `ios/Runner.xcodeproj/project.pbxproj`

---

## 📝 Checklist Rápido

- [ ] Proyecto creado en Firebase Console
- [ ] App Android agregada y `google-services.json` descargado
- [ ] `google-services.json` colocado en `android/app/`
- [ ] App iOS agregada y `GoogleService-Info.plist` descargado
- [ ] `GoogleService-Info.plist` colocado en `ios/Runner/`
- [ ] Authentication habilitado (Email/Password)
- [ ] Firestore Database creada
- [ ] Reglas de Firestore configuradas desde `firestore.rules`

---

## 🧪 Verificar Configuración

Después de configurar todo, puedes verificar que los archivos estén en su lugar:

```bash
# Verificar archivo Android
ls android/app/google-services.json

# Verificar archivo iOS (si estás en Mac/Linux)
ls ios/Runner/GoogleService-Info.plist

# En Windows PowerShell
Test-Path android/app/google-services.json
Test-Path ios/Runner/GoogleService-Info.plist
```

---

## 🚨 Solución de Problemas

### Error: "google-services.json not found"
- Verifica que el archivo esté en `android/app/google-services.json`
- Verifica que el package name coincida exactamente

### Error: "Default FirebaseApp is not initialized"
- Asegúrate de que `Firebase.initializeApp()` esté en `main.dart`
- Verifica que los archivos de configuración estén en su lugar

### Error: "API Key not valid"
- Verifica que hayas habilitado los servicios necesarios en Firebase
- Verifica que el proyecto esté activo en Firebase Console

---

## 📚 Recursos Adicionales

- [Documentación oficial de Firebase](https://firebase.google.com/docs)
- [Guía de FlutterFire](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

---

**Recomendación**: Usa la **Opción 1 (Firebase Console)** para la primera configuración, es más visual y fácil de seguir.

