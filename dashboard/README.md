# 🚇 MetroPTY - Dashboard de Administración

Dashboard web para monitorear la aplicación MetroPTY en tiempo real.

## 📋 Características

- **Estadísticas en Tiempo Real:**
  - Total de usuarios
  - Reportes del día
  - Estaciones activas
  - Trenes virtuales
  - Confianza promedio

- **Vistas Detalladas:**
  - Lista de todas las estaciones con estado y confianza
  - Trenes virtuales y su estado
  - Reportes recientes
  - Usuarios top (por puntos)
  - Estadísticas comunitarias de la Semana del Fundador

- **Auto-actualización:** Se actualiza automáticamente cada 30 segundos

## 🚀 Configuración

1. **Obtener credenciales de Firebase:**
   - Ve a Firebase Console → Configuración del proyecto
   - Copia las credenciales de configuración

2. **Configurar el dashboard:**
   - Abre `index.html`
   - Reemplaza `firebaseConfig` con tus credenciales:
   ```javascript
   const firebaseConfig = {
       apiKey: "TU_API_KEY",
       authDomain: "TU_PROJECT_ID.firebaseapp.com",
       projectId: "TU_PROJECT_ID",
       // ...
   };
   ```

3. **Abrir el dashboard:**
   - Opción 1: Abre `index.html` directamente en el navegador
   - Opción 2: Usa un servidor local:
     ```bash
     # Python
     python -m http.server 8000
     
     # Node.js
     npx http-server
     ```
   - Opción 3: Despliega en Firebase Hosting:
     ```bash
     firebase init hosting
     firebase deploy --only hosting
     ```

## 🔒 Seguridad

**IMPORTANTE:** Este dashboard expone datos de Firestore. Para producción:

1. **Configura reglas de Firestore** para limitar acceso:
   ```javascript
   match /{document=**} {
     allow read: if request.auth != null 
       && request.auth.token.admin == true;
   }
   ```

2. **O usa autenticación** en el dashboard:
   ```javascript
   firebase.auth().signInWithEmailAndPassword(email, password);
   ```

3. **O despliega en un dominio privado** con autenticación básica

## 📊 Uso

1. Abre el dashboard en tu navegador
2. Navega entre las pestañas para ver diferentes vistas
3. Los datos se actualizan automáticamente cada 30 segundos
4. Usa el botón "🔄 Actualizar Datos" para refrescar manualmente

## 🎯 Métricas Clave a Monitorear

- **Usuarios activos:** ¿Está creciendo?
- **Reportes por día:** ¿Se están generando suficientes datos?
- **Estaciones activas:** ¿Todas las estaciones tienen datos?
- **Confianza promedio:** ¿Los datos son confiables?
- **Progreso comunitario:** ¿Se está alcanzando el objetivo de 1,000 reportes?

---

**Última actualización:** 2025-12-14
