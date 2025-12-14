# 🚀 Instalar Flutter - Pasos Rápidos para Windows

## ✅ Flutter NO está instalado en tu sistema

Necesitas instalarlo primero antes de poder configurarlo en Android Studio.

---

## 📥 Paso 1: Descargar Flutter

1. **Ve a la página oficial:**
   - Abre tu navegador
   - Ve a: https://docs.flutter.dev/get-started/install/windows
   - O descarga directamente: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip

2. **Descarga el archivo ZIP:**
   - Haz clic en "Download Flutter SDK"
   - Guarda el archivo en tu carpeta de Descargas

---

## 📂 Paso 2: Crear Carpeta para Flutter

1. **Abre el Explorador de Archivos** (Win + E)
2. **Navega a C:** (disco principal)
3. **Crea una carpeta llamada `src`:**
   - Click derecho en `C:\` → "Nuevo" → "Carpeta"
   - Nómbrala: `src`
   - Si ya existe, úsala

---

## 📦 Paso 3: Extraer Flutter

1. **Ve a tu carpeta de Descargas**
2. **Busca el archivo:** `flutter_windows_xxx-stable.zip`
3. **Extrae el contenido:**
   - Click derecho en el ZIP → "Extraer todo..."
   - En "Seleccionar un destino", escribe: `C:\src`
   - O navega a `C:\src` usando el botón "Examinar..."
   - Haz clic en "Extraer"

4. **Verifica la estructura:**
   - Deberías tener: `C:\src\flutter\bin\flutter.bat`
   - Si tienes `C:\src\flutter\flutter\bin\flutter.bat`, mueve el contenido una carpeta arriba

---

## 🔧 Paso 4: Agregar Flutter al PATH (IMPORTANTE)

### Opción A: Desde la Interfaz de Windows (MÁS FÁCIL)

1. **Presiona `Win + X`** y selecciona **"Sistema"**
2. **Haz clic en "Configuración avanzada del sistema"** (lado derecho)
3. **Haz clic en "Variables de entorno"** (abajo)
4. **En "Variables del sistema"**, busca y selecciona **"Path"**
5. **Haz clic en "Editar"**
6. **Haz clic en "Nuevo"**
7. **Agrega esta ruta:** `C:\src\flutter\bin`
8. **Haz clic en "Aceptar"** en todas las ventanas
9. **Cierra y vuelve a abrir PowerShell/Terminal**

### Opción B: Desde PowerShell (Administrador)

1. **Abre PowerShell como Administrador:**
   - Presiona `Win + X`
   - Selecciona **"Windows PowerShell (Administrador)"** o **"Terminal (Administrador)"**

2. **Ejecuta este comando:**
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", [EnvironmentVariableTarget]::Machine)
   ```

3. **Cierra y vuelve a abrir PowerShell/Terminal**

---

## ✅ Paso 5: Verificar Instalación

1. **Abre una NUEVA ventana de PowerShell** (importante: nueva ventana)
2. **Ejecuta:**
   ```powershell
   flutter doctor
   ```

3. **Deberías ver algo como:**
   ```
   Doctor summary (to see all details, run flutter doctor -v):
   ...
   ```

**Si ves un error "flutter: no se reconoce..."**, verifica:
- Que el PATH esté configurado correctamente
- Que hayas cerrado y vuelto a abrir PowerShell
- Que la ruta `C:\src\flutter\bin\flutter.bat` exista

---

## 🎯 Paso 6: Configurar Flutter en Android Studio

Una vez que Flutter esté instalado:

1. **Abre Android Studio**
2. **Ve a "File" → "Settings"** (Ctrl+Alt+S)
3. **Busca: "Languages & Frameworks" → "Flutter"**
4. **En "Flutter SDK path"**, haz clic en el ícono de carpeta 📁
5. **Selecciona:** `C:\src\flutter`
   - **NO** selecciones `C:\src\flutter\bin`, solo `C:\src\flutter`
6. **Haz clic en "Apply"** y luego en **"OK"**
7. **Reinicia Android Studio** si te lo pide

---

## 📋 Checklist Rápido

- [ ] Flutter descargado (`flutter_windows_xxx.zip`)
- [ ] Carpeta `C:\src` creada
- [ ] Flutter extraído en `C:\src\flutter`
- [ ] Flutter agregado al PATH (`C:\src\flutter\bin`)
- [ ] PowerShell reiniciado
- [ ] `flutter doctor` funciona
- [ ] Flutter SDK configurado en Android Studio

---

## ❓ Problemas Comunes

### Error: "flutter: no se reconoce como comando"

**Soluciones:**
1. Verifica que el PATH esté configurado: `C:\src\flutter\bin`
2. **Cierra completamente PowerShell** y vuelve a abrirla
3. Verifica que el archivo exista: `C:\src\flutter\bin\flutter.bat`

### Error: "Git not found"

**Solución:**
- Instala Git: https://git-scm.com/download/win
- Reinicia PowerShell después de instalar

### Error: "Android Studio not found" en `flutter doctor`

**Solución:**
- Esto es normal si Android Studio no está en el PATH
- Solo necesitas configurarlo en Android Studio Settings

---

## 🚀 Después de Instalar

Una vez que Flutter esté instalado y configurado:

1. **En Android Studio:**
   - Deberías ver un banner "Pub get" en la parte superior
   - O haz click derecho en `pubspec.yaml` → "Flutter" → "Pub get"

2. **Instala las dependencias:**
   - Haz clic en "Pub get" o ejecuta `flutter pub get`

3. **Ejecuta tu app:**
   - Selecciona un dispositivo/emulador
   - Haz clic en "Run" (▶️)

---

**¡Sigue estos pasos y tendrás Flutter instalado!** 🎉

Si tienes algún problema, avísame en qué paso te quedaste.

