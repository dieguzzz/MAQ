# 🔧 Pasos para Solucionar el Error de Google Maps

## 🔴 Problema Actual

El error sigue apareciendo porque Google Maps está buscando la API Key **ANTIGUA**:
```
API Key: AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE
```

Pero en tu `AndroidManifest.xml` tienes la **NUEVA**:
```
API Key: AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc
```

## ✅ Solución: Verificar la Nueva API Key en Google Cloud Console

### Paso 1: Ve a Google Cloud Console

1. Abre: https://console.cloud.google.com/
2. Asegúrate de seleccionar el **mismo proyecto** donde habilitaste "Maps SDK for Android"

### Paso 2: Verifica que la Nueva API Key Exista

1. Ve a **"APIs y servicios"** > **"Credenciales"**
2. Busca la API Key: `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc`
3. Si **NO la encuentras**:
   - Tienes dos opciones:
     - **Opción A**: Usar la API Key antigua (`AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE`)
     - **Opción B**: Crear una nueva API Key con "Maps SDK for Android" habilitado

### Paso 3: Si Encuentras la Nueva API Key

1. **Haz clic en el nombre** de la API Key para editarla
2. Verifica en **"Restricciones de API"**:
   - Debe tener **"Maps SDK for Android"** en la lista de APIs habilitadas
   - Si no está, agrégala y guarda

3. Verifica en **"Restricciones de aplicación"**:
   - Si está configurada como **"Android apps"**, verifica que incluya:
     - Nombre del paquete: `com.example.metropty`
     - Huella SHA-1: `32:5E:17:BD:ED:4B:0D:A7:96:73:4E:D4:D0:AB:1B:A9:D5:54:DB:93`
   - Si hay restricciones y no coinciden, **quítalas temporalmente** para probar

### Paso 4: Si NO Encuentras la Nueva API Key

**Opción A: Usar la API Key Antigua (MÁS RÁPIDO)**

1. Ve a **"APIs y servicios"** > **"Credenciales"**
2. Busca: `AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE`
3. Haz clic para editarla
4. Verifica que tenga **"Maps SDK for Android"** habilitado
5. Actualiza el `AndroidManifest.xml` con la clave antigua

**Opción B: Crear una Nueva API Key**

1. Ve a **"APIs y servicios"** > **"Credenciales"**
2. Haz clic en **"Crear credenciales"** > **"Clave de API"**
3. **NO pongas restricciones** inicialmente (para probar)
4. Copia la nueva clave y úsala en `AndroidManifest.xml`

### Paso 5: Después de Configurar

1. **Espera 5-10 minutos** para que los cambios se propaguen
2. **Limpia el proyecto**:
   ```powershell
   cd d:\MAQ
   flutter clean
   flutter pub get
   ```
3. **Recompila**:
   ```powershell
   flutter run
   ```

## 🔍 Verificación Rápida

Para verificar rápidamente qué API Keys tienes configuradas:

1. Ve a: https://console.cloud.google.com/apis/credentials
2. Busca ambas claves:
   - `AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE` (antigua)
   - `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc` (nueva)

3. **Verifica que la que uses tenga:**
   - ✅ Estado: "Habilitada" o "Activa"
   - ✅ "Maps SDK for Android" en las restricciones de API
   - ✅ Sin restricciones de aplicación (temporalmente) o con las correctas

## ⚠️ Importante

- Si cambias la API Key en `AndroidManifest.xml`, **siempre** haz `flutter clean` antes de compilar
- Los cambios en Google Cloud Console pueden tardar unos minutos en propagarse
- Si tienes restricciones de aplicación, asegúrate de que coincidan con tu app

## 🎯 Recomendación

**La solución más rápida es:**
1. Usar la API Key antigua (`AIzaSyAXfTh_KYlMrzgtjbAuZ91yeQD-kIxCGyE`)
2. Verificar que tenga "Maps SDK for Android" habilitado
3. Actualizar `AndroidManifest.xml` con esa clave
4. Hacer `flutter clean` y recompilar

