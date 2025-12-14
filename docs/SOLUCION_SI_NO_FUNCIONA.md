# 🔧 Solución si el Mapa NO Funciona Después de Todo

## 🎯 Plan de Acción Paso a Paso

### Paso 1: Verificar los Logs de Error

Cuando ejecutes `flutter run`, revisa los logs buscando:

```
E/Google Android Maps SDK: Authorization failure
```

Si sigue apareciendo este error, continúa con los siguientes pasos.

---

## ✅ Solución 1: Usar la API Key Antigua (Más Probable que Funcione)

Si la API Key nueva no funciona, usemos la antigua que Google Maps está buscando:

1. **Actualizar AndroidManifest.xml:**
   - Abre: `android/app/src/main/AndroidManifest.xml`
   - Línea 43, cambia de:
     ```xml
     android:value="AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc"/>
     ```
   - A:
     ```xml
     android:value="AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE"/>
     ```

2. **Verificar en Google Cloud Console:**
   - Ve a: https://console.cloud.google.com/apis/credentials
   - Busca: `AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE`
   - Si existe, verifica que tenga "Maps SDK for Android" habilitado
   - Si NO existe o no tiene Maps SDK habilitado, ve a la Solución 2

3. **Limpiar y recompilar:**
   ```powershell
   cd d:\MAQ
   flutter clean
   flutter pub get
   flutter run
   ```

---

## ✅ Solución 2: Crear una API Key Nueva Sin Restricciones (Para Probar)

1. **Crear Nueva API Key:**
   - Ve a: https://console.cloud.google.com/apis/credentials
   - Haz clic en **"Crear credenciales"** > **"Clave de API"**
   - Se generará una nueva clave
   - **NO pongas restricciones** inicialmente (para probar que funcione)

2. **Habilitar "Maps SDK for Android":**
   - Haz clic en el nombre de la nueva API Key para editarla
   - En **"Restricciones de API"**:
     - Selecciona **"Restringir clave"**
     - Marca **"Maps SDK for Android"**
   - Haz clic en **"Guardar"**

3. **Verificar que "Maps SDK for Android" esté habilitado en el proyecto:**
   - Ve a: https://console.cloud.google.com/apis/library
   - Busca: **"Maps SDK for Android"**
   - Verifica que esté **"Habilitado"** (check verde)
   - Si no, haz clic en **"Habilitar"**

4. **Actualizar AndroidManifest.xml:**
   - Reemplaza la API Key en la línea 43 con la nueva clave
   - Guarda el archivo

5. **Limpiar y recompilar:**
   ```powershell
   cd d:\MAQ
   flutter clean
   flutter pub get
   flutter run
   ```

---

## ✅ Solución 3: Verificar Permisos de Ubicación

A veces el mapa no se muestra si no hay permisos de ubicación:

1. **Verificar permisos en AndroidManifest.xml:**
   - Debe tener estas líneas (líneas 3-5):
     ```xml
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
     <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
     ```

2. **Conceder permisos en el dispositivo:**
   - Ve a Configuración > Apps > MetroPTY > Permisos
   - Asegúrate de que **"Ubicación"** esté habilitado

---

## ✅ Solución 4: Verificar la Configuración de Google Services

1. **Verificar que google-services.json exista:**
   - Debe estar en: `android/app/google-services.json`
   - Si no existe, descárgalo de Firebase Console

2. **Verificar build.gradle:**
   - `android/build.gradle.kts` debe tener el plugin de Google Services
   - `android/app/build.gradle.kts` debe tener el plugin aplicado

---

## ✅ Solución 5: Probar en Otro Dispositivo/Emulador

A veces el problema es específico del dispositivo:

1. Prueba en un **emulador diferente**
2. O en un **dispositivo físico** diferente
3. Esto ayuda a descartar problemas de caché del dispositivo

---

## ✅ Solución 6: Verificar la Versión de Google Play Services

1. **En el dispositivo:**
   - Ve a: Configuración > Apps > Google Play Services
   - Verifica que esté actualizado
   - Si no, actualiza desde Google Play Store

2. **O verifica desde la app:**
   - Los logs deben mostrar: `Google Play services package version: 254435035`
   - Si es una versión muy antigua, puede causar problemas

---

## ✅ Solución 7: Verificar el Package Name

Asegúrate de que el package name en Google Cloud Console coincida:

1. **En AndroidManifest.xml:**
   - No hay un `package` explícito, pero `applicationId` está en `build.gradle.kts`
   - Debe ser: `com.example.metropty`

2. **En Google Cloud Console:**
   - Si la API Key tiene restricciones de aplicación Android
   - Debe incluir: `com.example.metropty`
   - Con SHA-1: `32:5E:17:BD:ED:4B:0D:A7:96:73:4E:D4:D0:AB:1B:A9:D5:54:DB:93`

---

## ✅ Solución 8: Desactivar Temporalmente las Restricciones

Para probar si el problema son las restricciones:

1. Ve a Google Cloud Console > Credenciales
2. Edita tu API Key
3. En **"Restricciones de aplicación"**:
   - Selecciona **"Ninguna"** (sin restricciones)
   - Guarda
4. Espera 5-10 minutos
5. Prueba de nuevo

⚠️ **IMPORTANTE:** Solo para probar. Después, vuelve a poner las restricciones para seguridad.

---

## 🔍 Debug: Verificar qué API Key está usando la App

Para verificar qué API Key está usando realmente la app:

1. **Buscar en los logs:**
   - Cuando ejecutes `flutter run`, busca en los logs:
   - `API Key: AIza...`
   - Esto te dirá qué clave está buscando Google Maps

2. **Verificar que coincida:**
   - La clave en los logs debe coincidir con la del `AndroidManifest.xml`
   - Si no coincide, hay un problema de caché o compilación

---

## ✅ Checklist Final

Antes de probar, verifica:

- [ ] La API Key en `AndroidManifest.xml` existe en Google Cloud Console
- [ ] La API Key tiene "Maps SDK for Android" habilitado
- [ ] "Maps SDK for Android" está habilitado en el proyecto de Google Cloud
- [ ] Hiciste `flutter clean` después de cambiar la API Key
- [ ] Los permisos de ubicación están en `AndroidManifest.xml`
- [ ] El dispositivo tiene permisos de ubicación concedidos
- [ ] Google Play Services está actualizado
- [ ] Esperaste 5-10 minutos después de hacer cambios en Google Cloud Console

---

## 🆘 Si Nada Funciona

1. **Crea un proyecto de prueba mínimo:**
   - Crea una app Flutter nueva solo con Google Maps
   - Prueba si funciona ahí
   - Si funciona, el problema está en la configuración de tu proyecto actual

2. **Revisa la documentación oficial:**
   - https://developers.google.com/maps/documentation/android-sdk/start
   - https://pub.dev/packages/google_maps_flutter

3. **Verifica los logs completos:**
   - Ejecuta: `flutter run --verbose`
   - Busca errores relacionados con "Google Maps" o "API Key"

---

## 📝 Comando Útil para Debug

Para ver todos los logs relacionados con Maps:

```powershell
flutter run 2>&1 | Select-String -Pattern "Maps|API|Key|Google"
```

Esto filtrará solo los logs relacionados con Google Maps y API Keys.

