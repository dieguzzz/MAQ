# ✅ Checklist de Configuración - MetroPTY

Usa esta lista para verificar que todo esté configurado correctamente.

## 📦 Paso 1: Dependencias
- [x] Dependencias de Flutter instaladas (`flutter pub get`)
- [x] Estructura de Android creada
- [x] Estructura de iOS creada

## 🔥 Paso 2: Firebase

### Android
- [ ] Proyecto creado en Firebase Console
- [ ] App Android agregada en Firebase
- [ ] `google-services.json` descargado
- [ ] `google-services.json` colocado en `android/app/`
- [ ] Package name verificado: `com.example.metropty`

### iOS
- [ ] App iOS agregada en Firebase
- [ ] `GoogleService-Info.plist` descargado
- [ ] `GoogleService-Info.plist` colocado en `ios/Runner/`
- [ ] Bundle ID verificado

### Servicios Firebase
- [ ] Authentication habilitado (Email/Password)
- [ ] Cloud Firestore habilitado
- [ ] Cloud Messaging habilitado
- [ ] Reglas de Firestore configuradas (copiar desde `firestore.rules`)

## 🗺️ Paso 3: Google Maps

### API Key
- [ ] Proyecto creado en Google Cloud Console
- [ ] Maps SDK for Android habilitado
- [ ] Maps SDK for iOS habilitado
- [ ] API Key creada
- [ ] API Key agregada en `AndroidManifest.xml` (reemplazar `TU_API_KEY_AQUI`)
- [ ] API Key agregada en `AppDelegate.swift` (reemplazar `TU_API_KEY_AQUI`)

## 📱 Paso 4: Permisos

### Android
- [x] Permisos de Internet agregados
- [x] Permisos de ubicación agregados
- [x] Google Maps API Key configurada en AndroidManifest.xml

### iOS
- [x] Permisos de ubicación agregados en Info.plist
- [x] Google Maps importado en AppDelegate.swift
- [x] Google Maps API Key configurada en AppDelegate.swift

## 🧪 Paso 5: Pruebas

### Verificación de Código
- [ ] Ejecutar `flutter analyze` (sin errores críticos)
- [ ] Ejecutar `flutter pub get` (sin errores)

### Pruebas en Dispositivo
- [ ] App compila sin errores
- [ ] App se ejecuta en Android
- [ ] App se ejecuta en iOS (si tienes Mac)
- [ ] Permisos de ubicación funcionan
- [ ] Mapa se muestra correctamente
- [ ] Firebase se conecta correctamente

## 📝 Notas Importantes

1. **API Keys**: Nunca subas tus API Keys reales a Git. Usa variables de entorno o archivos locales.

2. **Package Name / Bundle ID**: Asegúrate de que coincidan en:
   - Firebase Console
   - AndroidManifest.xml / build.gradle
   - Info.plist / Xcode

3. **Primera Ejecución**: La primera vez que ejecutes la app, puede tardar más en compilar.

4. **Errores Comunes**:
   - "google-services.json not found" → Verifica la ubicación del archivo
   - "API Key not valid" → Verifica que la API Key esté correcta y las APIs habilitadas
   - "Permission denied" → Verifica los permisos en los manifiestos

## 🚀 Comandos Útiles

```bash
# Verificar configuración
flutter doctor

# Analizar código
flutter analyze

# Ejecutar en dispositivo
flutter run

# Build para Android
flutter build apk

# Build para iOS (requiere Mac)
flutter build ios
```

## 📚 Documentación

- Ver `CONFIGURACION_PASO_A_PASO.md` para instrucciones detalladas
- Ver `SETUP.md` para información general
- Ver `README.md` para documentación del proyecto

---

**¡Una vez completada esta checklist, tu app debería estar lista para ejecutarse!** 🎉

