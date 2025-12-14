# ✅ Verificar API Key Nueva con Todo Configurado

## 🔑 API Key que Tienes Configurada

```
AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc
```

## ⚠️ Por qué Google Maps Busca la Antigua

Google Maps está buscando la API Key antigua (`AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE`) porque:

1. **Caché de compilación** - El APK puede tener la clave antigua compilada
2. **Restricciones de aplicación** - La nueva API Key puede tener restricciones que no coinciden
3. **Propagación de cambios** - Los cambios en Google Cloud pueden tardar unos minutos

## ✅ Solución: Verificar Configuración de la Nueva API Key

### Paso 1: Verificar en Google Cloud Console

1. **Ve a:** https://console.cloud.google.com/apis/credentials
2. **Busca:** `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc`
3. **Haz clic** en el nombre para editarla

### Paso 2: Verificar Restricciones de API

Asegúrate de que tenga habilitado:
- ✅ **Maps SDK for Android**

Si no está, agrégala y guarda.

### Paso 3: Verificar Restricciones de Aplicación

Si tiene restricciones de aplicación Android, debe incluir:

**Restricciones de aplicación:**
- **Tipo:** Android apps
- **Paquetes Android:**
  - Nombre del paquete: `com.example.metropty`
  - Huella SHA-1: `32:5E:17:BD:ED:4B:0D:A7:96:73:4E:D4:D0:AB:1B:A9:D5:54:DB:93`

**Si tiene restricciones incorrectas:**
- **Opción 1:** Quitar temporalmente las restricciones para probar
- **Opción 2:** Asegurarse de que coincidan exactamente con los datos de arriba

### Paso 4: Limpiar y Recompilar Completamente

Después de verificar en Google Cloud Console:

```powershell
cd d:\MAQ
flutter clean
cd android
.\gradlew clean
cd ..
flutter pub get
flutter run
```

## 🔍 Si Sigue Buscando la Antigua

Si después de todo Google Maps sigue buscando la API Key antigua, puede ser porque:

1. **La nueva API Key tiene restricciones que bloquean la app**
   - **Solución:** Quita temporalmente las restricciones de aplicación

2. **Los cambios en Google Cloud no se han propagado**
   - **Solución:** Espera 5-10 minutos y prueba de nuevo

3. **Caché persistente en el dispositivo**
   - **Solución:** 
     - Desinstala la app del dispositivo
     - Limpia todo: `flutter clean` y `.\gradlew clean`
     - Reinstala: `flutter run`

## ✅ Checklist Final

Antes de probar, verifica:

- [ ] La API Key `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc` existe en Google Cloud Console
- [ ] Tiene **"Maps SDK for Android"** habilitado en restricciones de API
- [ ] Si tiene restricciones de aplicación, incluye `com.example.metropty` y el SHA-1 correcto
- [ ] Hiciste `flutter clean` y `gradlew clean`
- [ ] Esperaste 5-10 minutos después de hacer cambios en Google Cloud Console

## 🆘 Si Nada Funciona

**Opción temporal:** Quita todas las restricciones de la API Key para probar:

1. Ve a Google Cloud Console > Credenciales
2. Edita la API Key `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc`
3. En **"Restricciones de aplicación"**: Selecciona **"Ninguna"**
4. Guarda
5. Espera 5-10 minutos
6. Prueba de nuevo

⚠️ **IMPORTANTE:** Solo para probar. Después, vuelve a poner las restricciones para seguridad.

