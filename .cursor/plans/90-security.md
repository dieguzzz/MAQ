# MetroPTY - Reglas de Seguridad y Buenas Prácticas

Toda nueva funcionalidad DEBE cumplir estas reglas antes de considerarse completa.

---

## 1. Firestore Rules (Principio de mínimo privilegio)

### Escrituras
- **NUNCA** permitir escrituras directas del cliente a colecciones compartidas (`stations`, `trains`, `model_metrics`).
- Si el cliente necesita actualizar datos compartidos, crear un **Cloud Function callable** que valide y escriba.
- Reportes: solo el autor puede crear. Solo Cloud Functions pueden modificar campos calculados (`confirmations`, `confidence`).

### Lecturas
- Datos públicos (stations, trains, reports): `allow read: if true`
- Datos privados (users, fcm_tokens): `allow read: if request.auth.uid == userId`
- Perfiles públicos: usar colección separada `public_profiles` con datos no sensibles.

### Validación en rules
- Validar tipos de campo: `request.resource.data.campo is string`
- Validar rangos numéricos: `campo >= 0 && campo <= 5`
- Validar incrementos: `campo == resource.data.campo + 1`
- Validar que campos requeridos existen: `request.resource.data.keys().hasAll(['campo1', 'campo2'])`

### Template para nueva colección
```
match /nueva_coleccion/{docId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null
    && request.auth.uid == request.resource.data.usuario_id
    && request.auth.token.firebase.sign_in_provider != 'anonymous'
    && request.resource.data.keys().hasAll(['campo_requerido'])
    && request.resource.data.campo is string;
  allow update: if false; // Solo Cloud Functions
  allow delete: if false;
}
```

---

## 2. Cloud Functions (Validación server-side)

### Toda operación sensible debe validarse en servidor
- Valores de campos contra **whitelists** (no blacklists)
- Rate limiting: máx operaciones por usuario por hora
- GeoPoint bounds: latitud y longitud dentro de rangos válidos (Panamá: lat 8.9-9.15, lng -79.6 a -79.35)
- Puntos/gamificación: caps diarios server-side (500 pts/día)
- Streaks: calcular en servidor, no confiar en el cliente

### Template para validación en onCreate trigger
```javascript
exports.onNuevoDocCreated = functions.firestore
  .document('coleccion/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const VALID_VALUES = ['valor1', 'valor2', 'valor3'];

    // Validar campos
    if (!VALID_VALUES.includes(data.campo)) {
      await snap.ref.delete();
      console.error(`Valor inválido: ${data.campo}`);
      return;
    }

    // Rate limiting
    const oneHourAgo = new Date(Date.now() - 3600000);
    const recentDocs = await admin.firestore()
      .collection('coleccion')
      .where('usuario_id', '==', data.usuario_id)
      .where('creado_en', '>', oneHourAgo)
      .get();

    if (recentDocs.size > 10) {
      await snap.ref.delete();
      return;
    }
  });
```

---

## 3. Logging (NUNCA exponer datos en producción)

### Reglas absolutas
- **NUNCA** usar `print()` directamente. Usar `AppLogger` de `lib/core/logger.dart`.
- `AppLogger` solo imprime en `kDebugMode` (debug builds).
- **NUNCA** loggear: userIds, tokens, emails, passwords, API keys, coordenadas exactas.
- Usar niveles apropiados:
  - `AppLogger.debug()` - flujo normal, desarrollo
  - `AppLogger.info()` - eventos relevantes
  - `AppLogger.warning()` - situaciones inesperadas no críticas
  - `AppLogger.error()` - errores que requieren atención

### Mensajes de error al usuario
- **NUNCA** mostrar `error.code`, `error.message` o stack traces al usuario.
- Usar mensajes genéricos: "Error al procesar. Intenta de nuevo."
- Loggear el error real solo via `AppLogger.error()`.

---

## 4. Autenticación y Autorización

### Usuarios anónimos
- **NO** pueden crear reportes ni confirmaciones.
- Verificar en Firestore rules: `request.auth.token.firebase.sign_in_provider != 'anonymous'`
- Verificar también en el cliente antes de mostrar UI de reporte.

### FCM Tokens
- Almacenar en colección separada `fcm_tokens/{userId}`, NO en documento del usuario.
- Solo el owner puede leer/escribir su token.
- Cloud Functions leen tokens via Admin SDK (bypassa rules).

### Eliminación de cuenta
- Usar trigger `auth.user().onDelete()` en Cloud Functions.
- Limpiar: documento de usuario, FCM token, public_profile, location_history, storage files.
- El cliente solo llama `user.delete()`, el servidor limpia todo lo demás.

---

## 5. API Keys y Secretos

### Reglas absolutas
- **NUNCA** hardcodear API keys en código Dart o en AndroidManifest.xml directamente.
- Google Maps key va en `android/local.properties` (git-ignored), referenciada via `build.gradle.kts` manifestPlaceholders.
- Firebase config (`google-services.json`, `GoogleService-Info.plist`) van en `.gitignore`.
- Cualquier nuevo secreto → `local.properties` o variable de entorno, NUNCA en el repo.

### Restricciones de API keys
- Toda API key debe tener restricciones en la consola del proveedor:
  - Plataforma (Android/iOS)
  - SHA-1 fingerprint
  - APIs específicas habilitadas

---

## 6. Storage (Cloud Storage)

### Reglas para uploads
- Tamaño máximo: 5MB
- Content types permitidos: `image/jpeg`, `image/png`, `image/webp`
- Rutas definidas por colección: `/profile_images/{userId}/`, `/report_images/{reportId}/`
- Deny-all por defecto para rutas no definidas.

### Template para storage rules
```
match /nueva_ruta/{userId}/{fileName} {
  allow read: if request.auth != null;
  allow write: if request.auth != null
    && request.auth.uid == userId
    && request.resource != null
    && request.resource.size < 5 * 1024 * 1024
    && request.resource.contentType.matches('image/(jpeg|png|webp)');
}
```

---

## 7. Ubicación y Geofencing

- Validar que la ubicación NO sea mock: `position.isMocked == false`
- Radio de validación para reportes: **500m** máximo.
- Solo escribir a `location_history` si el usuario se movió **>100m** desde última escritura.
- Cleanup automático de location_history: retención de **7 días** via Cloud Function scheduled.
- Test mode bypass SOLO en `kDebugMode`: `if (kDebugMode && appMode == AppMode.test)`

---

## 8. Network Security (Android)

- `cleartextTrafficPermitted="false"` en `network_security_config.xml`
- Excepciones solo para localhost/emulador en debug.
- Referenciar config en AndroidManifest: `android:networkSecurityConfig="@xml/network_security_config"`

---

## 9. Rate Limiting (Defensa en profundidad)

Implementar en AMBOS lados:

| Operación | Cliente | Servidor |
|-----------|---------|----------|
| Crear reporte | 10/hora por estación | 10/hora global |
| Confirmar reporte | Debounce 2s | 20/hora |
| Puntos | N/A | 500/día cap |
| Location writes | >100m movimiento | N/A |
| Notificaciones geofence | 6h cooldown por estación | N/A |

---

## 10. Checklist para nuevo módulo

Antes de hacer merge, verificar:

- [ ] Firestore rules actualizadas para nueva colección/subcollection
- [ ] Storage rules actualizadas si hay uploads
- [ ] Cloud Function con validación server-side si hay escrituras sensibles
- [ ] Rate limiting implementado (cliente + servidor)
- [ ] Cero `print()` - solo `AppLogger`
- [ ] Mensajes de error genéricos al usuario (sin exponer internals)
- [ ] API keys en `local.properties`, no en código
- [ ] Usuarios anónimos bloqueados de operaciones sensibles
- [ ] Ubicación validada (no mock, dentro de rango)
- [ ] `flutter analyze` sin errores ni warnings
- [ ] GeoPoints validados dentro de bounds de Panamá
