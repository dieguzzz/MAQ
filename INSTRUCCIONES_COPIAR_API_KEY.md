# 🔑 Instrucciones para Copiar y Configurar API Keys

## 📱 Para Android

### Paso 1: Copiar la API Key
1. En la página de Credenciales que estás viendo
2. En la fila de **"Android key (auto created by Firebase)"**
3. Haz clic en **"Mostrar clave"** o **"Show key"**
4. Se abrirá un modal o te mostrará la clave
5. Haz clic en el **ícono de copiar** 📋 para copiar la clave
6. O selecciona todo el texto y usa Ctrl+C

### Paso 2: Configurar en el Proyecto

**Archivo a editar:** `android/app/src/main/AndroidManifest.xml`

**Busca esta línea (línea 43):**
```xml
android:value="TU_API_KEY_AQUI"/>
```

**Reemplázala con tu clave (mantén las comillas):**
```xml
android:value="TU_CLAVE_AQUI_COPIADA"/>
```

---

## 🍎 Para iOS (Solo si desarrollas para iOS)

### Paso 1: Copiar la API Key
1. En la misma página de Credenciales
2. En la fila de **"iOS key (auto created by Firebase)"**
3. Haz clic en **"Mostrar clave"**
4. Copia la clave (ícono de copiar 📋)

### Paso 2: Configurar en el Proyecto

**Archivo a editar:** `ios/Runner/AppDelegate.swift`

**Busca esta línea (línea 12):**
```swift
GMSServices.provideAPIKey("TU_API_KEY_AQUI")
```

**Reemplázala con tu clave:**
```swift
GMSServices.provideAPIKey("TU_CLAVE_AQUI_COPIADA")
```

---

## ⚠️ Importante

- ✅ **NO** uses la "Browser key" (es solo para web)
- ✅ Usa la **Android key** para Android
- ✅ Usa la **iOS key** para iOS
- ✅ Estas keys ya tienen las APIs necesarias habilitadas (incluyendo Maps SDK)

---

## 🔍 Verificar Restricciones (Opcional)

Si quieres asegurarte de que la API de Maps está habilitada:

1. Haz clic en el **nombre** de la API key (Android key o iOS key)
2. Verás las "Restricciones de API"
3. Busca: **"Maps SDK for Android"** o **"Maps SDK for iOS"**
4. Debería estar en la lista de APIs habilitadas

---

## ✅ Después de Configurar

Ejecuta estos comandos para verificar:

```powershell
# Verificar que compila
flutter analyze

# Probar compilación
flutter build apk --debug
```

---

**¡Eso es todo! Ya puedes usar Google Maps en tu app.** 🗺️

