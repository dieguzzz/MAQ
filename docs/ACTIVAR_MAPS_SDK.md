# ✅ Activar "Maps SDK for Android" en la API Key

## 🔑 Tu API Key
```
AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc
```

## 📋 Pasos para Activar

### Paso 1: Ir a Google Cloud Console
1. Ve a: https://console.cloud.google.com/apis/credentials
2. Inicia sesión con tu cuenta de Google

### Paso 2: Encontrar tu API Key
1. Busca en la lista la API Key: `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc`
2. **Haz clic en el NOMBRE** de la API Key (no en el ícono de copiar)

### Paso 3: Configurar Restricciones de API
1. En la página de edición de la API Key, busca la sección **"Restricciones de API"**
2. Verás dos opciones:
   - ⭕ **"No restringir clave"** - Permite usar todas las APIs
   - ⭕ **"Restringir clave"** - Solo permite APIs específicas
   
3. **Selecciona "Restringir clave"**

4. En la lista de APIs que aparece, busca y marca:
   - ✅ **"Maps SDK for Android"**
   
5. **Haz clic en "Guardar"** (abajo)

### Paso 4: (Opcional) Verificar que "Maps SDK for Android" esté Habilitado en el Proyecto

Aunque ya lo activaste en la API Key, también verifica a nivel de proyecto:

1. Ve a: https://console.cloud.google.com/apis/library
2. Busca: **"Maps SDK for Android"**
3. Verifica que diga **"Habilitado"** (check verde)
4. Si dice "Deshabilitado", haz clic en **"Habilitar"**

## ⏱️ Esperar Propagación

Después de activar, **espera 5-10 minutos** para que los cambios se propaguen en Google Cloud.

## 🔄 Después de Activar

1. **Limpiar el proyecto:**
   ```powershell
   cd d:\MAQ
   flutter clean
   flutter pub get
   ```

2. **Recompilar:**
   ```powershell
   flutter run
   ```

## ✅ Verificación Final

Después de activar y esperar, cuando ejecutes `flutter run`, **ya NO debe aparecer** el error:
```
E/Google Android Maps SDK: Authorization failure
```

Si el mapa aparece correctamente, ¡está funcionando! 🎉

## 📝 Nota Importante

- ✅ Solo necesitas activar **"Maps SDK for Android"** en esa API Key
- ⚠️ Si tienes restricciones de aplicación (Android apps), asegúrate de que incluyan:
  - Package: `com.example.metropty`
  - SHA-1: `32:5E:17:BD:ED:4B:0D:A7:96:73:4E:D4:D0:AB:1B:A9:D5:54:DB:93`
- 🔒 Si quieres probar rápido, puedes quitar temporalmente las restricciones de aplicación

