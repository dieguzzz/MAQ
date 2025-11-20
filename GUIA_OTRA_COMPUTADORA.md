# 💻 Guía para Continuar el Proyecto en Otra Computadora

## 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado en la otra computadora:

- ✅ **Flutter SDK** (última versión estable)
- ✅ **Git**
- ✅ **Editor de código** (VS Code, Android Studio, IntelliJ, etc.)
- ✅ **Android Studio** (si desarrollas para Android)
- ✅ **Xcode** (si desarrollas para iOS - solo Mac)

---

## 🚀 Paso 1: Clonar el Repositorio

### Opción A: Clonar desde GitHub (Recomendado)

```bash
# Clonar el repositorio
git clone https://github.com/dieguzzz/MAQ.git

# Entrar al directorio
cd MAQ
```

### Opción B: Clonar con SSH (si tienes SSH configurado)

```bash
git clone git@github.com:dieguzzz/MAQ.git
cd MAQ
```

---

## 📦 Paso 2: Instalar Dependencias

```bash
# Instalar todas las dependencias de Flutter
flutter pub get

# Verificar que todo esté bien
flutter doctor
```

---

## 🔥 Paso 3: Configurar Firebase

### 3.1 Descargar Archivos de Configuración

**IMPORTANTE**: Los archivos `google-services.json` y `GoogleService-Info.plist` NO están en el repositorio por seguridad.

Tienes dos opciones:

#### Opción A: Descargar desde Firebase Console (Recomendado)

1. Ve a https://console.firebase.google.com/
2. Selecciona tu proyecto **MetroPTY** (o el que hayas creado)
3. Ve a **Configuración del proyecto** (ícono de engranaje)
4. En la sección **"Tus aplicaciones"**:
   - **Android**: Haz clic en la app Android → Descarga `google-services.json`
   - **iOS**: Haz clic en la app iOS → Descarga `GoogleService-Info.plist`
5. Coloca los archivos:
   - `google-services.json` → `android/app/google-services.json`
   - `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`

#### Opción B: Copiar desde la Computadora Original

Si tienes acceso a la computadora original:

```bash
# Desde la computadora original, copia los archivos:
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist

# Y pégalos en la misma ubicación en la nueva computadora
```

---

## 🗺️ Paso 4: Configurar Google Maps API Key

### 4.1 Obtener API Key

1. Ve a https://console.cloud.google.com/
2. Selecciona el mismo proyecto que usaste en Firebase
3. Ve a **APIs y servicios** > **Credenciales**
4. Copia tu **API Key** de Google Maps

### 4.2 Configurar en Android

Edita el archivo: `android/app/src/main/AndroidManifest.xml`

Busca esta línea:
```xml
android:value="TU_API_KEY_AQUI"/>
```

Reemplázala con tu API Key real:
```xml
android:value="TU_API_KEY_REAL_AQUI"/>
```

### 4.3 Configurar en iOS

Edita el archivo: `ios/Runner/AppDelegate.swift`

Busca esta línea:
```swift
GMSServices.provideAPIKey("TU_API_KEY_AQUI")
```

Reemplázala con tu API Key real:
```swift
GMSServices.provideAPIKey("TU_API_KEY_REAL_AQUI")
```

---

## ✅ Paso 5: Verificar Configuración

```bash
# Verificar que los archivos de Firebase estén en su lugar
# Windows PowerShell:
Test-Path android/app/google-services.json
Test-Path ios/Runner/GoogleService-Info.plist

# Linux/Mac:
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist

# Analizar el código
flutter analyze

# Verificar configuración de Flutter
flutter doctor
```

---

## 🧪 Paso 6: Probar la Aplicación

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en dispositivo/emulador
flutter run

# O ejecutar en modo release
flutter run --release
```

---

## 🔄 Trabajar con Git desde la Nueva Computadora

### Configurar Git (si es la primera vez)

```bash
# Configurar tu nombre y email
git config --global user.name "Tu Nombre"
git config --global user.email "tu.email@ejemplo.com"
```

### Comandos Git Útiles

```bash
# Ver estado del repositorio
git status

# Ver cambios pendientes
git diff

# Agregar cambios
git add .

# Hacer commit
git commit -m "Descripción de los cambios"

# Subir cambios a GitHub
git push

# Actualizar desde GitHub
git pull

# Ver historial de commits
git log
```

---

## 📝 Checklist Rápido

- [ ] Repositorio clonado desde GitHub
- [ ] Dependencias instaladas (`flutter pub get`)
- [ ] `google-services.json` descargado y colocado
- [ ] `GoogleService-Info.plist` descargado y colocado
- [ ] Google Maps API Key configurada en Android
- [ ] Google Maps API Key configurada en iOS
- [ ] `flutter doctor` sin errores críticos
- [ ] `flutter analyze` sin errores
- [ ] App compila y ejecuta correctamente

---

## 🚨 Solución de Problemas

### Error: "google-services.json not found"
- Verifica que el archivo esté en `android/app/google-services.json`
- Asegúrate de haberlo descargado desde Firebase Console

### Error: "API Key not valid"
- Verifica que la API Key esté correctamente configurada
- Verifica que las APIs estén habilitadas en Google Cloud Console

### Error: "Package name mismatch"
- Verifica que el package name en Firebase coincida con `android/app/build.gradle.kts`
- Verifica que el Bundle ID en Firebase coincida con el de iOS

### Error: "Dependencies not found"
```bash
# Limpiar y reinstalar
flutter clean
flutter pub get
```

---

## 💡 Consejos

1. **Mantén sincronizado**: Haz `git pull` antes de empezar a trabajar
2. **Commits frecuentes**: Haz commits pequeños y frecuentes
3. **Push regular**: Sube tus cambios regularmente a GitHub
4. **Documenta cambios**: Escribe mensajes de commit descriptivos

---

## 📚 Archivos de Referencia

- `README.md` - Documentación general del proyecto
- `SETUP.md` - Guía de configuración inicial
- `FIREBASE_SETUP.md` - Guía detallada de Firebase
- `CONFIGURACION_PASO_A_PASO.md` - Configuración paso a paso

---

## 🔐 Seguridad

**NUNCA subas a Git:**
- ❌ `google-services.json` (ya está en `.gitignore`)
- ❌ `GoogleService-Info.plist` (ya está en `.gitignore`)
- ❌ API Keys reales (usa variables de entorno o archivos locales)

**SÍ puedes subir:**
- ✅ Código fuente
- ✅ Archivos `.example`
- ✅ Documentación
- ✅ Configuración de proyecto

---

**¡Listo! Ya puedes trabajar desde cualquier computadora.** 🎉

