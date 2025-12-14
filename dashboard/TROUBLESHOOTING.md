# 🔧 Solución de Problemas del Dashboard

## ❌ Error: `auth/invalid-login-credentials`

**Causa:** Las credenciales proporcionadas no son correctas o el usuario no existe.

### Solución:

1. **Verificar que el usuario existe:**
   - Ve a Firebase Console → Authentication → Users
   - Busca el email que estás usando
   - Si no existe, créalo:
     - Click en "Add user"
     - Ingresa email y contraseña
     - Click en "Add user"

2. **Verificar que Email/Password está habilitado:**
   - Firebase Console → Authentication → Sign-in method
   - Busca "Email/Password"
   - Si está deshabilitado, haz clic y habilítalo
   - Guarda los cambios

3. **Verificar la contraseña:**
   - Asegúrate de escribir la contraseña correctamente
   - Si olvidaste la contraseña, puedes resetearla desde Firebase Console

4. **Crear usuario administrador (si no existe):**
   ```
   Firebase Console → Authentication → Add user
   Email: admin@metropty.com (o el que prefieras)
   Password: [tu contraseña segura]
   ```

---

## ❌ Error: `⚠️ Error de permisos. Verifica las reglas de Firestore para community_stats.`

**Causa:** No estás autenticado o las reglas de Firestore no permiten la lectura.

### Solución:

1. **Autenticarse correctamente:**
   - El dashboard intenta autenticación anónima automáticamente
   - Si ves el error, haz clic en "Login" o "Login Admin" en el header
   - Ingresa tus credenciales de administrador

2. **Verificar autenticación anónima:**
   - Firebase Console → Authentication → Sign-in method
   - Busca "Anonymous"
   - Si está deshabilitado, habilítalo
   - Esto permite que el dashboard funcione sin login manual

3. **Verificar reglas de Firestore:**
   - Las reglas actuales requieren `request.auth != null`
   - Esto significa que necesitas estar autenticado (anónimo o con email/password)
   - Si el error persiste, verifica que la autenticación funcionó:
     - Mira el header del dashboard
     - Debe decir "✓ Autenticado" (anónimo o con email)

---

## 🔍 Verificar Estado de Autenticación

El dashboard muestra el estado de autenticación en el header:

- **✓ Autenticado como: [email]** → Autenticado con email/password ✅
- **✓ Autenticado (anónimo)** → Autenticado anónimamente ✅
- **⚠ No autenticado** → No hay autenticación ❌

Si ves "⚠ No autenticado", haz clic en "Login" para autenticarte.

---

## 📋 Checklist de Configuración

Antes de usar el dashboard, verifica:

- [ ] **Email/Password habilitado** en Firebase Authentication
- [ ] **Anonymous habilitado** en Firebase Authentication (opcional pero recomendado)
- [ ] **Usuario administrador creado** en Firebase Authentication
- [ ] **Reglas de Firestore desplegadas** correctamente
- [ ] **Dashboard muestra estado de autenticación** en el header

---

## 🚀 Pasos Rápidos para Configurar

1. **Firebase Console → Authentication:**
   ```
   - Habilita "Email/Password"
   - Habilita "Anonymous" (opcional)
   - Crea usuario: admin@metropty.com
   ```

2. **Firebase Console → Firestore → Rules:**
   ```
   - Verifica que las reglas estén desplegadas
   - Debe incluir: allow read: if request.auth != null
   ```

3. **Dashboard:**
   ```
   - Abre el dashboard
   - Verifica que dice "✓ Autenticado" en el header
   - Si no, haz clic en "Login" e ingresa credenciales
   ```

---

**Última actualización:** 2025-12-14
