# 📥 Cómo Descargar Archivos de Firebase desde Otra Computadora

## 🎯 Objetivo

Ya tienes el proyecto de Firebase creado en otra computadora. Ahora necesitas descargar los archivos de configuración nuevamente.

---

## 📋 Paso 1: Acceder a Firebase Console

1. **Abre tu navegador** y ve a: https://console.firebase.google.com/
2. **Inicia sesión** con la misma cuenta de Google que usaste antes
3. **Selecciona tu proyecto** "MetroPTY" (o el nombre que le hayas puesto)

---

## 📱 Paso 2: Descargar google-services.json (Android)

### 2.1 Ir a Configuración del Proyecto

1. En la página principal del proyecto, haz clic en el **ícono de engranaje** ⚙️ (arriba a la izquierda)
2. Haz clic en **"Configuración del proyecto"** o **"Project settings"**

### 2.2 Encontrar la App Android

1. En la página de configuración, baja hasta la sección **"Tus aplicaciones"** o **"Your apps"**
2. Verás las apps que has agregado (Android 📱, iOS 🍎, Web 🌐)
3. Busca la app **Android** (tendrá el package name `com.example.metropty`)

### 2.3 Descargar el Archivo

1. Haz clic en el **ícono de engranaje** ⚙️ junto a la app Android
2. O haz clic directamente en la app Android
3. Verás el archivo `google-services.json` listo para descargar
4. Haz clic en **"Descargar google-services.json"** o **"Download google-services.json"**
5. El archivo se descargará en tu carpeta de **Descargas**

### 2.4 Colocar el Archivo

**Ubicación correcta:**
```
D:\MAQ\android\app\google-services.json
```

**Método rápido (PowerShell):**
```powershell
# Desde la carpeta del proyecto (D:\MAQ)
Copy-Item "$env:USERPROFILE\Downloads\google-services.json" -Destination "android\app\google-services.json"
```

**Método manual:**
1. Abre el **Explorador de Archivos**
2. Ve a tu carpeta de **Descargas**
3. Busca `google-services.json`
4. Cópialo y pégalo en: `D:\MAQ\android\app\`

---

## 🍎 Paso 3: Descargar GoogleService-Info.plist (iOS - Opcional)

**Solo si desarrollas para iOS:**

### 3.1 Encontrar la App iOS

1. En la misma página de **"Configuración del proyecto"**
2. En la sección **"Tus aplicaciones"**, busca la app **iOS** 🍎
3. Haz clic en ella

### 3.2 Descargar el Archivo

1. Haz clic en **"Descargar GoogleService-Info.plist"** o **"Download GoogleService-Info.plist"**
2. El archivo se descargará en tu carpeta de **Descargas**

### 3.3 Colocar el Archivo

**Ubicación correcta:**
```
D:\MAQ\ios\Runner\GoogleService-Info.plist
```

**Método rápido (PowerShell):**
```powershell
# Desde la carpeta del proyecto (D:\MAQ)
Copy-Item "$env:USERPROFILE\Downloads\GoogleService-Info.plist" -Destination "ios\Runner\GoogleService-Info.plist"
```

---

## ✅ Paso 4: Verificar que los Archivos Estén en su Lugar

Ejecuta estos comandos en PowerShell (desde `D:\MAQ`):

```powershell
# Verificar google-services.json
Test-Path android/app/google-services.json

# Verificar GoogleService-Info.plist (solo si necesitas iOS)
Test-Path ios/Runner/GoogleService-Info.plist
```

**Debería mostrar:** `True` para cada uno

---

## 🔑 Paso 5: Obtener Google Maps API Key (Si la Necesitas)

Si también necesitas recuperar tu API Key de Google Maps:

### 5.1 Ir a Google Cloud Console

1. Ve a: https://console.cloud.google.com/
2. **Selecciona el mismo proyecto** que usaste en Firebase
   - El nombre del proyecto debería ser el mismo
3. Ve a **"APIs y servicios"** > **"Credenciales"** (menú lateral izquierdo)

### 5.2 Encontrar la API Key

1. En la sección **"Claves de API"** verás tus API Keys
2. Busca la que esté habilitada para **"Maps SDK for Android"** o **"Maps SDK for iOS"**
3. Haz clic en el nombre de la API Key para ver los detalles
4. **Copia la clave** (haz clic en el ícono de copiar 📋)

### 5.3 Configurar en el Proyecto

**Para Android:**
Edita: `android/app/src/main/AndroidManifest.xml`
- Busca: `android:value="TU_API_KEY_AQUI"`
- Reemplázalo con tu API Key real

**Para iOS:**
Edita: `ios/Runner/AppDelegate.swift`
- Busca: `GMSServices.provideAPIKey("TU_API_KEY_AQUI")`
- Reemplázalo con tu API Key real

---

## 🚀 Paso 6: Verificar Todo Funciona

```powershell
# Verificar configuración
.\verificar_firebase.ps1

# O manualmente:
flutter clean
flutter pub get
flutter analyze
```

---

## 📝 Resumen Rápido

1. ✅ Ve a https://console.firebase.google.com/
2. ✅ Selecciona tu proyecto
3. ✅ Configuración del proyecto (ícono ⚙️)
4. ✅ Sección "Tus aplicaciones"
5. ✅ Descarga `google-services.json` (Android)
6. ✅ Descarga `GoogleService-Info.plist` (iOS - opcional)
7. ✅ Coloca los archivos en las ubicaciones correctas
8. ✅ Verifica con `Test-Path`

---

## ❓ ¿No Encuentras el Proyecto?

Si no ves tu proyecto en Firebase Console:

1. **Verifica la cuenta**: Asegúrate de usar la misma cuenta de Google
2. **Busca en otros proyectos**: Haz clic en "Ver todos los proyectos" si tienes varios
3. **Revisa el nombre**: El proyecto podría tener otro nombre

---

## 🆘 ¿Problemas?

**Error: "No puedo encontrar la app Android"**
- Ve directamente a: Configuración del proyecto → Scroll down → "Tus aplicaciones"
- Si no existe, tendrás que agregar la app nuevamente (pero no debería ser necesario)

**Error: "El archivo no se descarga"**
- Verifica que tu navegador permita descargas
- Intenta con otro navegador (Chrome, Firefox, Edge)

**Error: "No encuentro el proyecto"**
- Verifica que estés en la cuenta correcta de Google
- Busca en la lista completa de proyectos

---

**¡Listo! Ya tienes los archivos de configuración en tu nueva computadora.** 🎉

