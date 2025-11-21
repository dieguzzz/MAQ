# 📱 Cómo Instalar y Configurar Flutter en Android Studio

## 🔍 Paso 1: Verificar si Flutter está Instalado

Primero, vamos a verificar si Flutter ya está instalado en tu sistema.

### En PowerShell (fuera de Android Studio):

1. Abre PowerShell (Win + X → "Windows PowerShell" o "Terminal")
2. Escribe este comando:
   ```powershell
   flutter doctor
   ```
3. Presiona Enter

**Resultados posibles:**

- ✅ **Si muestra información**: Flutter está instalado, solo necesitas configurarlo en Android Studio
- ❌ **Si dice "flutter: no se reconoce..."**: Flutter NO está instalado, necesitas instalarlo

---

## 🚀 Paso 2: Instalar Flutter (Si NO está instalado)

### Opción A: Instalar Flutter Manualmente (RECOMENDADO)

1. **Descargar Flutter SDK:**
   - Ve a: https://docs.flutter.dev/get-started/install/windows
   - O directamente: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip
   - Descarga el archivo ZIP

2. **Extraer Flutter:**
   - Crea una carpeta donde quieras instalar Flutter:
     - Recomendado: `C:\src\flutter`
     - O cualquier otra ubicación (ej: `C:\flutter`, `D:\flutter`)
   - Extrae el contenido del ZIP en esa carpeta
   - **IMPORTANTE**: NO extraigas en `C:\Program Files\` (puede causar problemas de permisos)

3. **Agregar Flutter al PATH de Windows:**
   - Presiona `Win + X` → "Sistema"
   - Haz clic en "Configuración avanzada del sistema"
   - Haz clic en "Variables de entorno"
   - En "Variables del sistema", busca "Path"
   - Haz clic en "Editar"
   - Haz clic en "Nuevo"
   - Agrega la ruta al directorio `bin` de Flutter:
     - Ejemplo: `C:\src\flutter\bin`
   - Haz clic en "Aceptar" en todas las ventanas
   - **Cierra y vuelve a abrir PowerShell/Terminal**

4. **Verificar instalación:**
   ```powershell
   flutter doctor
   ```

### Opción B: Instalar Flutter usando Git (Avanzado)

```powershell
# Crear carpeta para Flutter
cd C:\src
mkdir flutter
cd flutter

# Clonar Flutter (necesitas Git instalado)
git clone https://github.com/flutter/flutter.git -b stable

# Agregar al PATH (paso 3 de Opción A)
```

---

## ⚙️ Paso 3: Configurar Flutter en Android Studio

Una vez que Flutter esté instalado:

1. **Abre Android Studio**
2. Ve a **"File" → "Settings"** (Ctrl+Alt+S)
   - O **"Android Studio" → "Preferences"** en Mac
3. En el panel izquierdo, busca:
   - **"Languages & Frameworks" → "Flutter"**
4. En **"Flutter SDK path"**, haz clic en el ícono de carpeta 📁
5. **Busca la carpeta donde instalaste Flutter:**
   - Ejemplo: `C:\src\flutter`
   - **NO selecciones** `C:\src\flutter\bin`, selecciona `C:\src\flutter` (la carpeta principal)
6. Haz clic en **"Apply"** y luego en **"OK"**
7. Android Studio puede pedirte reiniciar, haz clic en **"Restart"**

---

## ✅ Paso 4: Verificar que Todo Funciona

1. **En Android Studio**, deberías ver:
   - Un banner en la parte superior que dice **"Pub get"** o **"Get dependencies"**
   - O haz click derecho en `pubspec.yaml` → **"Flutter" → "Pub get"**

2. **En PowerShell** (fuera de Android Studio):
   ```powershell
   flutter doctor
   ```
   Debería mostrar el estado de Flutter y sus dependencias

---

## 🛠️ Instalación de Plugins de Flutter en Android Studio

Si Android Studio no reconoce Flutter automáticamente:

1. **Ve a "File" → "Settings" → "Plugins"**
2. Busca **"Flutter"** en el buscador
3. Haz clic en **"Install"** (incluye Dart automáticamente)
4. Haz clic en **"Apply"** y luego **"OK"**
5. Android Studio pedirá reiniciar, haz clic en **"Restart"**

---

## 📋 Requisitos Previos de Flutter

Flutter necesita:

- ✅ **Git** (para descargar paquetes)
  - Descargar: https://git-scm.com/download/win
- ✅ **Android Studio** (ya lo tienes ✅)
- ✅ **Android SDK** (instalado con Android Studio normalmente)
- ✅ **JDK** (Java Development Kit - normalmente incluido con Android Studio)

**Para verificar todo:**
```powershell
flutter doctor -v
```

Esto te mostrará qué está instalado y qué falta.

---

## ❓ Problemas Comunes

### Error: "flutter: no se reconoce como comando"

**Solución:**
- Flutter no está en el PATH
- Agrégalo al PATH (ver Paso 2, opción A, paso 3)
- **Cierra y vuelve a abrir PowerShell**

### Error: "Flutter SDK not found" en Android Studio

**Solución:**
- Verifica que la ruta en Android Studio Settings sea correcta
- La ruta debe ser a la carpeta `flutter` (ej: `C:\src\flutter`), NO a `bin`
- Reinicia Android Studio después de configurar

### Error: "Git not found"

**Solución:**
- Instala Git desde: https://git-scm.com/download/win
- Reinicia PowerShell/Android Studio después de instalar

---

## 🎯 Después de Instalar Flutter

Una vez que Flutter esté instalado y configurado:

1. **En Android Studio:**
   - Haz click en el banner **"Pub get"** en la parte superior
   - O click derecho en `pubspec.yaml` → **"Flutter" → "Pub get"**

2. **Verifica que las dependencias se instalen correctamente**

3. **Ejecuta tu app:**
   - Selecciona un dispositivo/emulador
   - Haz clic en **"Run"** (▶️)

---

## 📚 Recursos Útiles

- **Documentación oficial de Flutter**: https://docs.flutter.dev/get-started/install/windows
- **Flutter SDK Releases**: https://docs.flutter.dev/release/archive
- **Solución de problemas**: https://docs.flutter.dev/troubleshoot

---

**¡Sigue estos pasos y tendrás Flutter instalado y configurado en Android Studio!** 🚀

