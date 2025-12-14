# 📱 Pasos en Android Studio

## 🚀 Al Abrir el Proyecto

### Paso 1: Sincronizar Dependencias

1. **Android Studio** detectará automáticamente que es un proyecto Flutter
2. Abrirá un mensaje en la parte superior que dice **"Pub get"** o **"Get dependencies"**
3. Haz clic en **"Pub get"** para instalar todas las dependencias

O manualmente:
- Click derecho en el archivo `pubspec.yaml`
- Selecciona **"Flutter" → "Pub get"**

### Paso 2: Verificar Configuración

1. Ve a **"File" → "Project Structure"** (Ctrl+Alt+Shift+S)
2. Verifica que Flutter SDK esté configurado correctamente
3. Verifica que el **"Project SDK"** esté configurado

### Paso 3: Seleccionar Dispositivo

1. En la barra superior, verás un dropdown con dispositivos
2. Selecciona:
   - **Un emulador Android** (si tienes uno configurado)
   - **Un dispositivo físico** conectado por USB (con depuración USB habilitada)
   - O haz clic en **"Device Manager"** para crear/configurar un emulador

### Paso 4: Ejecutar la Aplicación

1. Haz clic en el botón **"Run"** (▶️) en la barra superior
2. O presiona **Shift+F10** (Windows/Linux) o **Ctrl+R** (Mac)
3. O desde el menú: **"Run" → "Run 'main.dart'"**

---

## ✅ Verificaciones Importantes

### 1. Verificar que no hay errores

- En la parte inferior, verás la pestaña **"Run"** o **"Debug"**
- Revisa si hay errores en rojo
- Los warnings (amarillo) generalmente no son críticos

### 2. Verificar archivos de Firebase

Si ves un error como **"google-services.json not found"**:

1. Verifica que el archivo esté en: `android/app/google-services.json`
2. Haz clic derecho en `android/app/` → **"Synchronize 'MAQ'"**
3. O ve a **"File" → "Invalidate Caches / Restart"**

### 3. Verificar API Keys

Si ves un error relacionado con Google Maps:

1. Verifica que en `AndroidManifest.xml` la API Key esté configurada
2. Verifica en Google Cloud Console que las APIs estén habilitadas:
   - Maps SDK for Android
   - Maps SDK for iOS

---

## 🧪 Primera Ejecución

La primera vez que ejecutas la app:

1. **Puede tardar varios minutos** en compilar (normal)
2. Verás mensajes en la consola como:
   - "Building APK..."
   - "Installing APK..."
   - "Launching lib/main.dart..."

3. **Una vez que la app se abra**, deberías ver:
   - La pantalla de inicio de la app
   - El mapa de Google Maps (si está configurado)

---

## ❓ Problemas Comunes

### Error: "Flutter SDK not found"

**Solución:**
1. Ve a **"File" → "Settings"** (Ctrl+Alt+S)
2. Busca **"Languages & Frameworks" → "Flutter"**
3. En **"Flutter SDK path"**, selecciona dónde está Flutter instalado
4. Haz clic en **"Apply"** y **"OK"**

### Error: "No devices found"

**Solución:**
1. Haz clic en **"Device Manager"** (ícono de teléfono)
2. Crea un nuevo dispositivo virtual (AVD)
3. O conecta un dispositivo físico con depuración USB habilitada

### Error: "Gradle build failed"

**Solución:**
1. Ve a **"File" → "Invalidate Caches / Restart"**
2. Selecciona **"Invalidate and Restart"**
3. Espera a que Android Studio reinicie
4. Vuelve a ejecutar la app

---

## 📋 Checklist Rápido

- [ ] Proyecto abierto en Android Studio
- [ ] Dependencias instaladas (Pub get)
- [ ] Dispositivo/emulador seleccionado
- [ ] App ejecutada sin errores
- [ ] La app se abre correctamente
- [ ] El mapa se muestra (si está configurado)

---

## 🎯 Próximos Pasos Después de Ejecutar

Una vez que la app esté funcionando, prueba:

1. **Registro/Login:** Crea una cuenta y haz login
2. **Ver el mapa:** El mapa debería mostrarse con las estaciones
3. **Crear un reporte:** Prueba crear un reporte
4. **Ver reportes:** Verifica que puedas ver reportes de otros usuarios

---

**¡Buena suerte ejecutando la app en Android Studio!** 🚀

Si encuentras algún error, revisa la consola en Android Studio y me puedes preguntar.

