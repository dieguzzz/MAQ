# 🗺️ Configuración de Google Maps API

## ✅ Estado Actual

Tu proyecto ya tiene:
- ✅ Permisos de ubicación configurados en `AndroidManifest.xml`
- ✅ API Key configurada en `AndroidManifest.xml` (línea 43)
- ✅ Plugin `google_maps_flutter` instalado
- ✅ Código de Google Maps implementado

## 🔑 Cómo Obtener/Actualizar tu API Key de Google Maps

### Paso 1: Ve a Google Cloud Console

1. Abre tu navegador y ve a: https://console.cloud.google.com/
2. Inicia sesión con tu cuenta de Google

### Paso 2: Crea o Selecciona un Proyecto

1. Si ya tienes un proyecto de Firebase, **selecciona ese mismo proyecto**
2. Si no tienes un proyecto, haz clic en el selector de proyectos (arriba) y luego en **"Nuevo proyecto"**
3. Dale un nombre al proyecto (ej: "MetroPTY") y haz clic en **"Crear"**

### Paso 3: Habilita las APIs Necesarias

1. En el menú lateral, ve a **"APIs y servicios"** > **"Biblioteca"**
2. Busca y habilita estas APIs (una por una):
   - **Maps SDK for Android** - Haz clic en "Habilitar"
   - **Maps SDK for iOS** - Si desarrollas para iOS (opcional)
   - **Places API** - Opcional, para búsqueda de lugares

### Paso 4: Crear o Usar una API Key

**Opción A: Si ya tienes una API Key de Firebase (Recomendado)**

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **"Configuración del proyecto"** (ícono de engranaje)
4. Ve a la pestaña **"Cuentas de servicio"** o **"Configuración general"**
5. Busca la sección **"Tus aplicaciones"** y selecciona tu app Android
6. Busca la **"Android key (auto created by Firebase)"** o similar
7. Haz clic en **"Mostrar clave"** y cópiala

**Opción B: Crear una nueva API Key**

1. En Google Cloud Console, ve a **"APIs y servicios"** > **"Credenciales"**
2. Haz clic en **"Crear credenciales"** > **"Clave de API"**
3. Se generará una nueva clave
4. **IMPORTANTE:** Haz clic en **"Restringir clave"** para seguridad:
   - En **"Restricciones de API"**, selecciona **"Restringir clave"**
   - Selecciona: **"Maps SDK for Android"** (y "Maps SDK for iOS" si aplica)
   - Haz clic en **"Guardar"**

### Paso 5: Configurar la API Key en el Proyecto

1. Abre el archivo: `android/app/src/main/AndroidManifest.xml`
2. Busca la línea 43 que dice:
   ```xml
   android:value="AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE"/>
   ```
3. Reemplaza el valor entre las comillas con tu nueva API Key:
   ```xml
   android:value="TU_NUEVA_API_KEY_AQUI"/>
   ```

### Paso 6: Verificar la Configuración

Tu `AndroidManifest.xml` debe verse así (líneas 39-43):

```xml
<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

### Paso 7: Probar la Aplicación

1. Guarda todos los archivos
2. Ejecuta en la terminal:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
3. Si todo está bien, el mapa debería cargarse sin errores

## ⚠️ Solución de Problemas

### Error: "Google Maps API key not found"

- Verifica que la API Key esté correctamente copiada en `AndroidManifest.xml`
- Asegúrate de que no hay espacios adicionales o caracteres inválidos
- Verifica que la API Key tenga habilitada "Maps SDK for Android"

### Error: "API key not valid" o mapa en blanco

1. Ve a Google Cloud Console > Credenciales
2. Verifica que la API Key esté activa
3. Verifica que "Maps SDK for Android" esté habilitado en las restricciones de la API
4. Si pusiste restricciones de aplicación, asegúrate de que el `applicationId` (`com.example.metropty`) coincida

### El mapa no carga o aparece gris

- Verifica tu conexión a internet
- Verifica los permisos de ubicación en el dispositivo
- Revisa los logs de Flutter: `flutter run --verbose`

## 📝 Notas Importantes

- ⚠️ **NO** compartas tu API Key públicamente (no la subas a GitHub si es un repo público)
- 💰 Google Maps tiene un tier gratuito generoso, pero revisa los límites en la consola
- 🔒 Siempre restringe tu API Key a las APIs y aplicaciones necesarias
- 📱 La misma API Key puede usarse para desarrollo y producción (pero es mejor tener una para cada entorno)

## ✅ Checklist Final

- [ ] Proyecto creado en Google Cloud Console
- [ ] Maps SDK for Android habilitado
- [ ] API Key creada y copiada
- [ ] API Key configurada en `AndroidManifest.xml`
- [ ] Aplicación probada y funcionando
- [ ] API Key restringida (opcional pero recomendado)

---

**¿Necesitas ayuda?** Revisa los logs de Flutter o consulta la [documentación oficial de Google Maps Flutter](https://pub.dev/packages/google_maps_flutter).

