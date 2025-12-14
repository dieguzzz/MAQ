# 🔧 Solución: Error "pub" no reconocido en Android Studio

## ❌ El Problema

Estás intentando ejecutar `pub get` en la terminal, pero el comando `pub` no está reconocido porque Flutter no está configurado correctamente en el PATH del sistema o en Android Studio.

---

## ✅ Solución 1: Usar la Opción Gráfica de Android Studio (MÁS FÁCIL)

**En lugar de usar la terminal, usa la interfaz gráfica:**

### Opción A: Desde el Banner Superior

1. Android Studio detectará que es un proyecto Flutter
2. Verás un **banner amarillo/azul** en la parte superior que dice:
   - **"Pub get"** o **"Get dependencies"**
3. Haz clic en ese botón
4. Android Studio ejecutará `flutter pub get` automáticamente

### Opción B: Click Derecho en pubspec.yaml

1. En el explorador de archivos (izquierda), busca el archivo **`pubspec.yaml`**
2. Haz **click derecho** sobre `pubspec.yaml`
3. Selecciona **"Flutter" → "Pub get"**
4. Espera a que termine de instalar las dependencias

### Opción C: Desde el Menú

1. Ve a **"Tools" → "Flutter" → "Flutter Pub Get"**
2. O ve a **"File" → "Settings" → "Flutter"** y verifica la configuración

---

## ✅ Solución 2: Configurar Flutter SDK en Android Studio

Si Android Studio no detecta Flutter automáticamente:

1. Ve a **"File" → "Settings"** (Ctrl+Alt+S)
   - O **"Android Studio" → "Preferences"** en Mac
2. En el panel izquierdo, busca:
   - **"Languages & Frameworks" → "Flutter"**
3. En **"Flutter SDK path"**, haz clic en el ícono de carpeta 📁
4. Busca dónde está instalado Flutter:
   - Ubicación común en Windows: `C:\src\flutter`
   - O donde lo hayas instalado
5. Selecciona la carpeta **`flutter`** (no `bin`, la carpeta principal)
6. Haz clic en **"Apply"** y luego en **"OK"**
7. Android Studio se reiniciará automáticamente o pedirá reiniciar

**Después de esto, Android Studio debería reconocer Flutter automáticamente.**

---

## ✅ Solución 3: Usar el Comando Correcto en Terminal

Si quieres usar la terminal dentro de Android Studio:

**NO uses:** `pub get` ❌

**Usa:** `flutter pub get` ✅

1. Abre la terminal en Android Studio (parte inferior)
2. Escribe:
   ```bash
   flutter pub get
   ```
3. Presiona Enter

**Nota:** Esto solo funciona si Flutter está en el PATH del sistema. Si no funciona, usa la Solución 1 o 2.

---

## 🔍 Verificar que Flutter está Configurado

Para verificar que Flutter está bien configurado en Android Studio:

1. Ve a **"File" → "Settings" → "Languages & Frameworks" → "Flutter"**
2. Deberías ver:
   - **Flutter SDK path**: Con una ruta válida
   - **Dart SDK path**: Configurado automáticamente
3. En la parte inferior, haz clic en **"Apply"** y luego **"OK"**

---

## 📋 Checklist Rápido

- [ ] ✅ Flutter SDK configurado en Android Studio Settings
- [ ] ✅ Banner "Pub get" visible en Android Studio
- [ ] ✅ Dependencias instaladas correctamente
- [ ] ✅ Proyecto listo para ejecutar

---

## 🎯 Después de Instalar Dependencias

Una vez que las dependencias estén instaladas:

1. **Selecciona un dispositivo:**
   - Haz clic en el dropdown de dispositivos (barra superior)
   - Selecciona un emulador o dispositivo físico

2. **Ejecuta la app:**
   - Haz clic en el botón **"Run"** (▶️)
   - O presiona **Shift+F10**

---

## ❓ ¿Dónde está Instalado Flutter?

Si no sabes dónde está Flutter instalado, busca en:

- `C:\src\flutter` (ubicación común)
- `C:\flutter`
- O donde lo hayas instalado originalmente

**Para encontrarlo:**
1. Abre PowerShell (fuera de Android Studio)
2. Escribe: `where flutter`
3. Te mostrará la ruta si está en PATH

---

**Usa la Solución 1 (banner gráfico) si tienes prisa. Es la más fácil y rápida.** 🚀

