# 🔒 Solucionar Error de Permisos en Firestore

## ❌ Error Actual

```
I/flutter: Error inicializando estaciones: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
W/Firestore: Write failed at stations/l1_01: Status{code=PERMISSION_DENIED}
```

## 🔍 Diagnóstico

El problema es que **las reglas de Firestore NO están permitiendo la escritura** a pesar de que configuraste reglas temporales.

---

## ✅ Solución Paso a Paso

### 1. Verificar Reglas en Firebase Console

**Paso 1: Abrir Firebase Console**
1. Ve a: https://console.firebase.google.com/project/metropty-aa303/firestore
2. Haz clic en la pestaña **"Reglas"** (Rules)

**Paso 2: Verificar las Reglas Actuales**
- Deberías ver las reglas que configuraste temporalmente
- Las reglas deberían ser:
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

**Paso 3: Si NO están así, ACTUALÍZALAS:**
1. Borra todas las reglas actuales
2. Copia y pega las reglas temporales arriba
3. Haz clic en **"Publicar"** (Publish)
4. Espera 10-30 segundos para que se propaguen

---

### 2. Verificar que las Reglas Estén Publicadas

**Después de publicar:**
1. Verifica que veas un mensaje de éxito: "Reglas publicadas"
2. Espera 30-60 segundos (las reglas pueden tardar en propagarse)
3. Refresca la página para asegurarte de que estén guardadas

---

### 3. Verificar la Fecha en las Reglas

**⚠️ IMPORTANTE:** Asegúrate de que la fecha en las reglas sea **FUTURA**.

Tu regla dice:
```javascript
if request.time < timestamp.date(2025, 12, 20)
```

Esto significa que las reglas son válidas **hasta** el 20 de diciembre de 2025.

**Si la fecha ya pasó:**
- Cambia a una fecha futura, por ejemplo:
```javascript
if request.time < timestamp.date(2026, 12, 31)
```

---

### 4. Reiniciar la App

**Después de actualizar las reglas:**

1. **Cierra completamente la app** en tu dispositivo
2. **Espera 1 minuto** para que las reglas se propaguen
3. **Ejecuta la app de nuevo:**
   ```powershell
   flutter run
   ```

**O si la app ya está corriendo:**
- Presiona `R` (mayúscula) para hacer **hot restart completo**

---

### 5. Verificar los Logs

**Deberías ver:**
```
🚀 Iniciando inicialización de estaciones...
📝 No hay estaciones, creando estaciones...
📦 Total de estaciones a crear: 23
💾 Guardando estaciones en Firestore...
✅ ¡Estaciones inicializadas en Firestore! Total: 23
```

**Si sigues viendo el error de permisos:**
- Espera 2-3 minutos más después de publicar las reglas
- Verifica que las reglas estén publicadas correctamente
- Intenta cerrar completamente la app y ejecutarla de nuevo

---

## 🔧 Reglas Alternativas (Si las Anteriores No Funcionan)

**Si las reglas temporales con fecha no funcionan, usa estas reglas de PRUEBA (SOLO TEMPORALMENTE):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **IMPORTANTE:** Estas reglas permiten **TODO** (lectura y escritura sin restricciones). **Solo úsalas temporalmente** para inicializar las estaciones, luego **restaura las reglas de seguridad**.

**Pasos:**
1. Copia las reglas de arriba
2. Pégalas en Firebase Console > Firestore > Reglas
3. Haz clic en **"Publicar"**
4. Espera 30 segundos
5. Ejecuta la app de nuevo
6. **Inmediatamente después** de que las estaciones se creen, **restaura las reglas de seguridad**

---

## ✅ Verificar que Funcionó

**Después de ejecutar la app:**

1. Ve a Firebase Console > Firestore Database > **Data**
2. Deberías ver la colección **`stations`** con 23 documentos
3. Si ves las estaciones, **inmediatamente restaura las reglas de seguridad** (ver `firestore.rules`)

---

## 🔒 Restaurar Reglas de Seguridad

**Después de inicializar las estaciones:**

1. Ve a Firebase Console > Firestore > Reglas
2. Copia el contenido del archivo `firestore.rules` del proyecto
3. Pégalo en Firebase Console
4. Haz clic en **"Publicar"**

**Las reglas de seguridad deberían ser:**
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
                .hasOnly(['verificaciones']));
      allow delete: if false;
    }
    
    // Routes collection
    match /routes/{routeId} {
      allow read: if true; // Todos pueden leer
      allow write: if false; // Solo system (Cloud Functions) puede escribir
    }
  }
}
```

---

## 🎯 Resumen de Pasos

1. ✅ Verificar reglas en Firebase Console
2. ✅ Actualizar reglas temporales si es necesario
3. ✅ Publicar reglas y esperar 30-60 segundos
4. ✅ Cerrar app completamente
5. ✅ Ejecutar app de nuevo (`flutter run`)
6. ✅ Verificar que las estaciones se crearon en Firebase Console
7. ✅ **Restaurar reglas de seguridad inmediatamente**

---

**¡Una vez que las estaciones se creen, tu app estará completamente funcional!** 🚀

