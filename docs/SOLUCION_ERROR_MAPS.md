# 🗺️ Solución: El Mapa No Se Ve - Error de Autorización

## 🔴 Problema Detectado

El error en los logs muestra:
```
E/Google Android Maps SDK: Authorization failure.
E/Google Android Maps SDK: Ensure that the "Maps SDK for Android" is enabled.
E/Google Android Maps SDK: Ensure that the following Android Key exists:
```

## ✅ Solución Paso a Paso

### Paso 1: Verificar que la API Key esté Habilitada en Google Cloud Console

1. **Ve a Google Cloud Console:**
   - Abre: https://console.cloud.google.com/
   - Inicia sesión con tu cuenta

2. **Selecciona tu Proyecto:**
   - Si tienes un proyecto de Firebase, selecciona ese mismo
   - O el proyecto donde creaste la API Key

3. **Habilita "Maps SDK for Android":**
   - En el menú lateral, ve a **"APIs y servicios"** > **"Biblioteca"**
   - Busca: **"Maps SDK for Android"**
   - Haz clic y luego **"Habilitar"** (si no está habilitado)
   - Espera unos minutos a que se active

### Paso 2: Verificar/Configurar la API Key

1. **Ve a Credenciales:**
   - En el menú lateral: **"APIs y servicios"** > **"Credenciales"**

2. **Encuentra tu API Key:**
   - Busca la clave: `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc`
   - Si no la encuentras, crea una nueva (ver abajo)

3. **Verifica Restricciones:**
   - Haz clic en el nombre de la API Key
   - En **"Restricciones de aplicación"**, verifica:
     - **Restricción de aplicación**: "Android apps"
     - **Agregar un elemento de aplicación**:
       - Nombre del paquete: `com.example.metropty`
       - Huella digital SHA-1: (ver cómo obtenerla abajo)

4. **Verifica Restricciones de API:**
   - En **"Restricciones de API"**, selecciona **"Restringir clave"**
   - Asegúrate de tener seleccionado:
     - ✅ **Maps SDK for Android**
   - Haz clic en **"Guardar"**

### Paso 3: Si Necesitas Crear una Nueva API Key

1. **Crear Nueva API Key:**
   - Ve a **"APIs y servicios"** > **"Credenciales"**
   - Haz clic en **"Crear credenciales"** > **"Clave de API"**
   - Copia la nueva clave generada

2. **Configurar Restricciones (Importante para Seguridad):**
   - **Restricciones de aplicación**: Android apps
     - Agregar paquete: `com.example.metropty`
     - Agregar huella SHA-1 (ver cómo obtenerla abajo)
   - **Restricciones de API**: Restringir clave
     - Seleccionar: **Maps SDK for Android**
   - Haz clic en **"Guardar"**

3. **Actualizar AndroidManifest.xml:**
   - Reemplaza la API Key en `android/app/src/main/AndroidManifest.xml` (línea 43)
   - Con la nueva clave

### Paso 4: Obtener la Huella Digital SHA-1 (Para Restricciones de Seguridad)

**Opción A: Para Debug (Desarrollo)**
```powershell
cd android
.\gradlew signingReport
```
- Busca en la salida: `SHA1:` seguido de una cadena de caracteres
- Cópiala (sin espacios)

**Opción B: Usando Java Keytool**
```powershell
cd android\app
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
- Busca la línea `SHA1:` y copia el valor

### Paso 5: Limpiar y Recompilar

Después de configurar la API Key, ejecuta:

```powershell
cd d:\MAQ
flutter clean
flutter pub get
flutter run
```

## 🔍 Verificación Final

Después de seguir los pasos:

1. ✅ La API Key tiene "Maps SDK for Android" habilitado
2. ✅ La API Key está en `AndroidManifest.xml` (línea 43)
3. ✅ El proyecto se compiló limpio (`flutter clean`)
4. ✅ La app se ejecuta sin errores de autorización

## ⚠️ Errores Comunes

### Error: "Authorization failure"
- **Causa**: La API Key no tiene habilitada "Maps SDK for Android"
- **Solución**: Ve a Google Cloud Console > APIs y servicios > Biblioteca > Habilitar "Maps SDK for Android"

### Error: "API key not valid"
- **Causa**: La API Key está mal configurada o tiene restricciones incorrectas
- **Solución**: Verifica las restricciones en Google Cloud Console

### El mapa aparece gris o en blanco
- **Causa**: La API Key no tiene permisos o está incorrecta
- **Solución**: Verifica que la API Key esté correctamente configurada y que "Maps SDK for Android" esté habilitado

## 📝 Nota Importante

Si cambiaste la API Key recientemente:
- Puede tomar unos minutos en propagarse en Google Cloud
- Asegúrate de hacer `flutter clean` antes de compilar
- Verifica que la clave en `AndroidManifest.xml` coincida con la de Google Cloud Console

---

**¿Necesitas ayuda?** Verifica los logs de Flutter buscando errores que contengan "Google Android Maps SDK" o "Authorization failure".

