# ✅ Pasos Finales - Después de Activar Maps SDK

## 🎯 Lo que Ya Está Hecho

- ✅ API Key configurada en `AndroidManifest.xml`: `AIzaSyCsef9R3HyDoipRIKM9Yj7LSM5XMRDIFMc`
- ✅ "Maps SDK for Android" activado en la API Key
- ✅ OAuth Client ID configurado con SHA-1 correcto

## ⏱️ IMPORTANTE: Esperar Propagación

Los cambios en Google Cloud Console pueden tardar **5-10 minutos** en propagarse. Es mejor esperar un poco antes de probar.

## 🔄 Pasos Finales

### 1. Limpiar el Proyecto Completamente

```powershell
cd d:\MAQ
flutter clean
```

### 2. Limpiar Gradle (Opcional pero Recomendado)

```powershell
cd android
.\gradlew clean
cd ..
```

### 3. Obtener Dependencias

```powershell
flutter pub get
```

### 4. Ejecutar la App

```powershell
flutter run
```

## ✅ Qué Esperar

### Si Todo Funciona Correctamente:

- ✅ El mapa de Google Maps debería aparecer en la pantalla
- ✅ NO debe aparecer el error: `E/Google Android Maps SDK: Authorization failure`
- ✅ Deberías ver calles, lugares y poder hacer zoom

### Si Aún Aparece el Error:

1. **Espera 5-10 minutos más** - Los cambios pueden tardar en propagarse
2. **Verifica en los logs** - Busca el mensaje que dice qué API Key está buscando
3. **Desinstala la app** del dispositivo y vuelve a instalarla:
   ```powershell
   flutter run
   ```

## 🔍 Verificación en los Logs

Cuando ejecutes `flutter run`, en los logs deberías ver:

✅ **Bueno:**
- `I/Google Android Maps SDK: Google Play services maps renderer version`
- El mapa se carga correctamente
- NO aparece "Authorization failure"

❌ **Mal:**
- `E/Google Android Maps SDK: Authorization failure`
- `E/Google Android Maps SDK: Ensure that the "Maps SDK for Android" is enabled`
- El mapa aparece en blanco o gris

## 🆘 Si Aún No Funciona

Si después de esperar y recompilar sigue sin funcionar:

1. **Verifica las restricciones de aplicación:**
   - Ve a Google Cloud Console > Credenciales
   - Edita la API Key
   - En "Restricciones de aplicación", asegúrate de que:
     - Incluya: `com.example.metropty`
     - Incluya el SHA-1: `32:5E:17:BD:ED:4B:0D:A7:96:73:4E:D4:D0:AB:1B:A9:D5:54:DB:93`
   - O quita temporalmente las restricciones para probar

2. **Verifica que "Maps SDK for Android" esté habilitado a nivel de proyecto:**
   - Ve a: https://console.cloud.google.com/apis/library
   - Busca: "Maps SDK for Android"
   - Debe decir "Habilitado" (check verde)

3. **Desinstala la app del dispositivo completamente:**
   - Ve a Configuración > Apps > MetroPTY
   - Desinstalar
   - Luego vuelve a instalar con `flutter run`

## 📝 Resumen

1. ⏱️ **Espera 5-10 minutos** para que se propaguen los cambios
2. 🧹 **Limpia:** `flutter clean` y `gradlew clean`
3. 🔄 **Recompila:** `flutter pub get` y `flutter run`
4. ✅ **Verifica:** El mapa debería aparecer sin errores

¡Ya está todo configurado! Solo falta esperar la propagación y recompilar. 🚀

