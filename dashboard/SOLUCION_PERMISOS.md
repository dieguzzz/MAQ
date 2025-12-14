# 🔒 Solución de Permisos para el Dashboard

**Problema:** El dashboard muestra errores "Missing or insufficient permissions"

---

## 🎯 Solución Rápida (Recomendada)

### Opción 1: Habilitar Autenticación Anónima en Firebase

1. Ve a Firebase Console → Authentication
2. Habilita "Anonymous" como método de autenticación
3. El dashboard se autenticará automáticamente

**Ventajas:**
- ✅ No requiere cambios en código
- ✅ Funciona inmediatamente
- ✅ Seguro (solo lectura)

---

### Opción 2: Ajustar Reglas de Firestore (Temporal para Desarrollo)

**⚠️ SOLO PARA DESARROLLO/TESTING**

Actualiza `firestore.rules` para permitir lectura sin autenticación:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Stations - Permitir lectura pública (ya está así)
    match /stations/{stationId} {
      allow read: if true; // ✅ Ya está configurado
      // ...
    }
    
    // Trains - Permitir lectura pública (ya está así)
    match /trains/{trainId} {
      allow read: if true; // ✅ Ya está configurado
      // ...
    }
    
    // Reports - Cambiar temporalmente para dashboard
    match /reports/{reportId} {
      allow read: if true; // ⚠️ TEMPORAL: Cambiar de request.auth != null
      // ...
    }
    
    // Users - Cambiar temporalmente para dashboard
    match /users/{userId} {
      allow read: if true; // ⚠️ TEMPORAL: Cambiar de request.auth != null
      // ...
    }
    
    // Community Stats - Agregar regla
    match /community_stats/{statId} {
      allow read: if true; // ✅ Para dashboard
      allow write: if false; // Solo Cloud Functions
    }
  }
}
```

**Después de ajustar:**
```bash
firebase deploy --only firestore:rules
```

---

## 🔐 Solución de Producción (Segura)

### Opción 3: Autenticación con Email/Password en Dashboard

1. **Habilitar Email/Password en Firebase Console**
2. **Agregar login al dashboard:**

```javascript
// En index.html, agregar antes de cargar datos:
async function loginDashboard() {
    const email = prompt('Email de administrador:');
    const password = prompt('Contraseña:');
    
    try {
        await auth.signInWithEmailAndPassword(email, password);
        console.log('Login exitoso');
        return true;
    } catch (error) {
        alert('Error de autenticación: ' + error.message);
        return false;
    }
}

// Llamar antes de refreshAll()
await loginDashboard();
```

3. **Crear usuario administrador:**
   - Firebase Console → Authentication → Agregar usuario
   - Email: admin@metropty.com
   - Password: [tu contraseña]

---

## ✅ Estado Actual

El dashboard ahora:
- ✅ Intenta autenticación anónima automáticamente
- ✅ Muestra mensajes de error claros
- ✅ Maneja errores de permisos gracefully

**Para que funcione completamente:**
1. Habilita "Anonymous" en Firebase Authentication
2. O ajusta temporalmente las reglas de Firestore (solo desarrollo)

---

**Última actualización:** 2025-12-14
