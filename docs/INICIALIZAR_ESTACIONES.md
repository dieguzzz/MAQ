# 🚀 Inicializar Estaciones en Firestore

## ✅ Estado Actual

- ✅ Firebase Console configurado con Project ID: `metropty-aa303`
- ✅ Reglas de Firestore actualizadas temporalmente para permitir escritura
- ✅ Base de datos Firestore creada
- ⏳ Pendiente: Ejecutar la app para inicializar las estaciones

---

## 📋 Pasos para Inicializar las Estaciones

### 1. ✅ Verificar Reglas de Firestore (YA HECHO)

Las reglas temporales que configuraste están correctas:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 20);
    }
  }
}
```

✅ **Válidas hasta:** 20 de diciembre de 2025
✅ **Permiten:** Lectura y escritura temporalmente

---

### 2. 🚀 Ejecutar la App

**Ejecuta la app en tu dispositivo o emulador:**

```powershell
flutter run
```

**O si ya está corriendo:**
- Presiona `R` (mayúscula) para hacer **hot restart** completo

---

### 3. ⏳ Esperar la Inicialización

**La app automáticamente:**
1. Intentará cargar estaciones desde Firestore
2. Si no hay estaciones, las creará automáticamente usando datos estáticos
3. Creará 23 estaciones (13 de Línea 1 + 10 de Línea 2)

**Logs que deberías ver:**
```
I/flutter: Estaciones inicializadas en Firestore
```

**Si hay errores, verás:**
```
I/flutter: Error inicializando estaciones: [error]
```

---

### 4. ✅ Verificar en Firebase Console

**Después de ejecutar la app:**

1. Ve a Firebase Console: https://console.firebase.google.com/project/metropty-aa303/firestore
2. Haz clic en **Firestore Database** > **Data**
3. Deberías ver la colección **`stations`** con 23 documentos
4. Haz clic en **`stations`** para ver las estaciones creadas

**Cada estación debería tener:**
- `id`: ID único de la estación
- `nombre`: Nombre de la estación
- `linea`: `linea1` o `linea2`
- `ubicacion`: Objeto con `latitude` y `longitude`
- `estado`: Estado actual (normal, moderado, etc.)

---

### 5. 🔒 Restaurar Reglas de Seguridad

**⚠️ IMPORTANTE: Después de inicializar las estaciones, vuelve a poner las reglas originales de seguridad.**

**Reglas que deberías usar (después de inicializar):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Stations collection
    match /stations/{stationId} {
      allow read: if true; // Todos pueden leer
      allow write: if false; // Solo system (Cloud Functions) puede escribir
    }
    
    // Trains collection
    match /trains/{trainId} {
      allow read: if true; // Todos pueden leer
      allow write: if false; // Solo system (Cloud Functions) puede escribir
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if request.auth != null; // Usuarios autenticados pueden leer
      allow create: if request.auth != null 
        && request.resource.data.usuario_id == request.auth.uid;
      allow update: if request.auth != null 
        && (resource.data.usuario_id == request.auth.uid 
            || request.resource.data.diff(resource.data).affectedKeys()
                .hasOnly(['verificaciones'])); // Permitir actualizar verificaciones
      allow delete: if false; // No permitir eliminar
    }
    
    // Routes collection
    match /routes/{routeId} {
      allow read: if true; // Todos pueden leer
      allow write: if false; // Solo system (Cloud Functions) puede escribir
    }
  }
}
```

**Pasos para restaurar:**
1. Ve a Firebase Console > Firestore Database > Reglas
2. Copia las reglas de seguridad arriba
3. Pega en Firebase Console
4. Haz clic en **"Publicar"**

**O mejor aún:**
- Las reglas originales están en el archivo `firestore.rules` del proyecto
- Solo copia ese contenido y pégalo en Firebase Console

---

## 🔍 Troubleshooting

### ❌ Error: "Permission denied"

**Problema:** Las reglas no están publicadas correctamente.

**Solución:**
1. Verifica en Firebase Console que las reglas estén publicadas
2. Espera 1-2 minutos después de publicar las reglas
3. Haz hot restart de la app (presiona `R` mayúscula)

### ❌ Error: "Database not found"

**Problema:** Firestore no está creado o habilitado.

**Solución:**
1. Ve a Firebase Console > Firestore Database
2. Si no existe, haz clic en "Crear base de datos"
3. Selecciona "Modo de prueba" temporalmente
4. Selecciona la ubicación más cercana
5. Haz clic en "Habilitar"

### ❌ No se crean las estaciones

**Problema:** La app no puede escribir en Firestore.

**Verificación:**
1. Verifica que las reglas temporales estén publicadas en Firebase Console
2. Revisa los logs de la app para ver el error específico
3. Verifica que Firebase esté inicializado correctamente

---

## 📝 Checklist de Verificación

- [ ] Reglas temporales publicadas en Firebase Console
- [ ] Base de datos Firestore creada y habilitada
- [ ] App ejecutada (`flutter run`)
- [ ] Log "Estaciones inicializadas en Firestore" aparece en consola
- [ ] Colección `stations` visible en Firebase Console con 23 documentos
- [ ] Reglas de seguridad restauradas (después de inicializar)

---

## 🎯 Próximos Pasos Después de Inicializar

1. **Restaurar reglas de seguridad** (ver paso 5 arriba)
2. **Verificar que las estaciones aparezcan en el mapa** de la app
3. **Habilitar Authentication** para login/registro de usuarios
4. **Probar sistema de reportes**

---

**¡Una vez inicializadas las estaciones, tu app estará completamente funcional!** 🚀

