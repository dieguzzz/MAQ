# 🚀 Desplegar Reglas de Firestore

**IMPORTANTE:** Las reglas de Firestore deben estar desplegadas para que el dashboard funcione correctamente.

---

## ⚠️ Problema Común

Si ves el error:
```
⚠️ Error de permisos. Verifica las reglas de Firestore para community_stats.
```

**Causa:** Las reglas de Firestore no están desplegadas o están desactualizadas.

---

## ✅ Solución: Desplegar Reglas

### Opción 1: Desde la Terminal (Recomendado)

```bash
# Navegar al directorio del proyecto
cd d:\MAQ

# Desplegar solo las reglas de Firestore
firebase deploy --only firestore:rules
```

### Opción 2: Desde Firebase Console

1. Ve a Firebase Console → Firestore Database
2. Pestaña "Rules"
3. Copia el contenido de `firestore.rules` del proyecto
4. Pégalo en el editor de reglas
5. Click en "Publish"

---

## 🔍 Verificar que las Reglas Están Desplegadas

1. Firebase Console → Firestore Database → Rules
2. Verifica que las reglas incluyan:
   ```javascript
   match /community_stats/{statId} {
     allow read: if request.auth != null;
     allow write: if false;
   }
   ```

---

## 📋 Reglas Actuales

Las reglas actuales requieren autenticación para leer:
- `users` - requiere autenticación
- `reports` - requiere autenticación
- `community_stats` - requiere autenticación
- `stations` - lectura pública ✅
- `trains` - lectura pública ✅

**Para el dashboard:**
- Necesitas estar autenticado (anónimo o con email/password)
- Anonymous debe estar habilitado en Firebase Authentication

---

## 🛠️ Comandos Útiles

```bash
# Ver reglas actuales
cat firestore.rules

# Desplegar reglas
firebase deploy --only firestore:rules

# Ver estado del proyecto Firebase
firebase projects:list

# Verificar configuración
firebase use
```

---

## ⚡ Solución Rápida

Si el dashboard muestra errores de permisos:

1. **Habilita Anonymous:**
   - Firebase Console → Authentication → Sign-in method
   - Habilita "Anonymous"

2. **Despliega reglas:**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Recarga el dashboard**

---

**Última actualización:** 2025-12-14
