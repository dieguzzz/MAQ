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

   **Opción 1: Más Simple (Recomendado)**
   - Haz doble clic en `index.html`
   - Se abrirá directamente en tu navegador
   - ⚠️ Nota: Algunas funciones pueden requerir servidor local

   **Opción 2: Scripts Automáticos (Windows)**
   - **PowerShell:** Ejecuta `servir.ps1` (click derecho → "Ejecutar con PowerShell")
   - **CMD:** Ejecuta `servir.bat` (doble clic)
   - Los scripts detectan automáticamente qué servidor usar
   - Luego abre: `http://localhost:8000/dashboard/index.html`

   **Opción 3: Manual (PowerShell/CMD)**
   ```powershell
   # Python (Windows PowerShell)
   py -m http.server 8000
   # O si tienes Python 3 instalado:
   python3 -m http.server 8000
   
   # Node.js (si está instalado)
   npx http-server
   
   # PHP (si está instalado)
   php -S localhost:8000
   ```
   Luego abre: `http://localhost:8000/dashboard/index.html`

   **Opción 4: VS Code Live Server**
   - Instala extensión "Live Server"
   - Click derecho en `index.html` → "Open with Live Server"

   **Opción 5: Firebase Hosting (Producción)**
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
