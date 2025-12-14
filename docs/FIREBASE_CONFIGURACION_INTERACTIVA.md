# 🔥 Configuración de Firebase - Guía Interactiva

## ✅ Estado Actual

- ✅ Código preparado para Firebase
- ✅ Plugin de Google Services configurado
- ✅ Firebase.initializeApp() en main.dart
- ❌ Archivos de configuración faltantes

---

## 📋 PASO 1: Crear Proyecto en Firebase Console

### 1.1 Abrir Firebase Console

👉 **Abre tu navegador y ve a**: https://console.firebase.google.com/

### 1.2 Crear Nuevo Proyecto

1. Haz clic en **"Agregar proyecto"** o **"Add project"**
2. **Nombre del proyecto**: `MetroPTY` (o el que prefieras)
3. Haz clic en **"Continuar"**
4. **Google Analytics** (opcional):
   - Puedes desactivarlo si no lo necesitas
   - O activarlo si quieres analíticas
5. Haz clic en **"Crear proyecto"**
6. Espera 30-60 segundos a que se cree

✅ **Cuando veas "Tu proyecto está listo"**, haz clic en **"Continuar"**

---

## 📱 PASO 2: Configurar App Android

### 2.1 Agregar App Android

1. En la página principal del proyecto, haz clic en el **ícono de Android** 📱
2. **Package name**: `com.example.metropty`
   - ⚠️ **IMPORTANTE**: Este debe coincidir exactamente
3. **App nickname** (opcional): `MetroPTY Android`
4. Haz clic en **"Registrar app"**

### 2.2 Descargar google-services.json

1. Haz clic en **"Descargar google-services.json"**
2. **NO cierres esta página todavía**
3. Guarda el archivo en una ubicación que recuerdes

### 2.3 Colocar el Archivo

**Opción A: Desde el Explorador de Archivos**
1. Abre el Explorador de Archivos
2. Navega a: `C:\Users\Diegu\MAQ\android\app\`
3. Copia el archivo `google-services.json` aquí

**Opción B: Desde PowerShell**
```powershell
# Reemplaza RUTA_DEL_ARCHIVO con donde guardaste el archivo
Copy-Item "RUTA_DEL_ARCHIVO\google-services.json" -Destination "android\app\google-services.json"
```

### 2.4 Verificar

Ejecuta este comando para verificar:
```powershell
Test-Path android/app/google-services.json
```

Debería mostrar: `True`

---

## 🍎 PASO 3: Configurar App iOS (Opcional - Solo si desarrollas para iOS)

### 3.1 Agregar App iOS

1. En Firebase Console, haz clic en el **ícono de iOS** 🍎
2. **Bundle ID**: `com.example.metropty`
3. **App nickname** (opcional): `MetroPTY iOS`
4. Haz clic en **"Registrar app"**

### 3.2 Descargar GoogleService-Info.plist

1. Haz clic en **"Descargar GoogleService-Info.plist"**
2. Guarda el archivo

### 3.3 Colocar el Archivo

1. Navega a: `C:\Users\Diegu\MAQ\ios\Runner\`
2. Copia el archivo `GoogleService-Info.plist` aquí

---

## ⚙️ PASO 4: Habilitar Servicios en Firebase

### 4.1 Authentication

1. En el menú lateral, ve a **"Authentication"** o **"Autenticación"**
2. Haz clic en **"Comenzar"** o **"Get started"**
3. Ve a la pestaña **"Sign-in method"** o **"Métodos de inicio de sesión"**
4. Haz clic en **"Email/Password"**
5. **Activa** el primer toggle (Email/Password)
6. Haz clic en **"Guardar"**

✅ **Authentication habilitado**

### 4.2 Cloud Firestore

1. En el menú lateral, ve a **"Firestore Database"** o **"Base de datos Firestore"**
2. Haz clic en **"Crear base de datos"** o **"Create database"**
3. Selecciona **"Comenzar en modo de prueba"** o **"Start in test mode"**
   - ⚠️ Luego actualizarás las reglas de seguridad
4. **Selecciona la ubicación** más cercana:
   - Para Panamá: `southamerica-east1` o `us-central1`
5. Haz clic en **"Habilitar"** o **"Enable"**
6. Espera 30-60 segundos

✅ **Firestore habilitado**

### 4.3 Configurar Reglas de Firestore

1. En Firestore Database, ve a la pestaña **"Reglas"** o **"Rules"**
2. **Abre el archivo** `firestore.rules` de tu proyecto (en la raíz)
3. **Copia TODO el contenido** del archivo
4. **Pega el contenido** en el editor de reglas de Firebase Console
5. Haz clic en **"Publicar"** o **"Publish"**

✅ **Reglas configuradas**

### 4.4 Cloud Messaging

- ✅ Ya está habilitado por defecto
- No necesitas hacer nada adicional aquí

---

## ✅ PASO 5: Verificar Configuración

### 5.1 Verificar Archivos

Ejecuta estos comandos:

```powershell
# Verificar Android
Test-Path android/app/google-services.json

# Verificar iOS (si lo configuraste)
Test-Path ios/Runner/GoogleService-Info.plist
```

Ambos deberían mostrar: `True`

### 5.2 Verificar Package Name

Abre `android/app/build.gradle.kts` y verifica que la línea 24 diga:
```kotlin
applicationId = "com.example.metropty"
```

Debe coincidir con el Package name que pusiste en Firebase.

---

## 🧪 PASO 6: Probar la Configuración

### 6.1 Limpiar y Reconstruir

```powershell
flutter clean
flutter pub get
```

### 6.2 Verificar con Flutter

```powershell
flutter doctor
```

### 6.3 Intentar Compilar

```powershell
flutter build apk --debug
```

Si compila sin errores relacionados con Firebase, ¡está configurado correctamente!

---

## 🚨 Solución de Problemas

### Error: "google-services.json not found"

**Solución:**
1. Verifica que el archivo esté en `android/app/google-services.json`
2. Verifica que el nombre del archivo sea exactamente `google-services.json` (sin espacios)
3. Verifica que el package name en Firebase coincida con `build.gradle.kts`

### Error: "Default FirebaseApp is not initialized"

**Solución:**
1. Verifica que `Firebase.initializeApp()` esté en `main.dart`
2. Verifica que el archivo `google-services.json` esté correctamente colocado
3. Ejecuta `flutter clean` y `flutter pub get`

### Error: "Package name mismatch"

**Solución:**
1. Verifica que el package name en Firebase Console sea: `com.example.metropty`
2. Verifica que en `android/app/build.gradle.kts` línea 24 sea: `applicationId = "com.example.metropty"`
3. Si son diferentes, actualiza uno para que coincidan

---

## 📝 Checklist Final

- [ ] Proyecto creado en Firebase Console
- [ ] App Android agregada
- [ ] `google-services.json` descargado y colocado
- [ ] App iOS agregada (si desarrollas para iOS)
- [ ] `GoogleService-Info.plist` descargado y colocado (si iOS)
- [ ] Authentication habilitado (Email/Password)
- [ ] Firestore Database creada
- [ ] Reglas de Firestore configuradas
- [ ] Package name verificado
- [ ] `flutter clean` y `flutter pub get` ejecutados
- [ ] Compilación exitosa

---

## 🎯 Siguiente Paso

Una vez completado todo, el siguiente paso es configurar **Google Maps API Key**.

Ver: `CONFIGURACION_PASO_A_PASO.md` para más detalles.

---

**¿Necesitas ayuda con algún paso específico?** 🤔

