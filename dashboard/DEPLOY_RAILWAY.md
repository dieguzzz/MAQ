# 🚂 Despliegue en Railway

## Pasos para subir el dashboard a Railway

### 1. Preparar el proyecto

Los archivos necesarios ya están configurados:
- `package.json` - Configuración de Node.js
- `railway.json` - Configuración específica de Railway

### 2. Crear repositorio Git

```bash
# En la carpeta dashboard/
git init
git add .
git commit -m "Initial commit - MetroPTY Dashboard"
```

### 3. Subir a GitHub/GitLab

```bash
# Crear repositorio en GitHub/GitLab y ejecutar:
git remote add origin https://github.com/tu-usuario/metropty-dashboard.git
git push -u origin main
```

### 4. Conectar con Railway

1. Ve a [Railway.app](https://railway.app) y crea una cuenta
2. Click en "New Project" → "Deploy from GitHub"
3. Conecta tu repositorio de GitHub
4. Railway detectará automáticamente la configuración

### 5. Configurar Variables de Entorno

En el dashboard de Railway, ve a "Variables" y agrega:

```bash
# Firebase Configuration (desde Firebase Console)
VITE_FIREBASE_API_KEY=tu_api_key_aqui
VITE_FIREBASE_AUTH_DOMAIN=tu_project_id.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=tu_project_id
VITE_FIREBASE_STORAGE_BUCKET=tu_project_id.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=tu_sender_id
VITE_FIREBASE_APP_ID=tu_app_id

# Opcional
VITE_APP_ENV=production
VITE_APP_VERSION=1.0.0
```

### 6. Modificar index.html para usar variables de entorno

Para que funcione con Railway, necesitamos modificar el `index.html` para usar las variables de entorno. Cambia la configuración de Firebase:

```javascript
// En lugar de hardcodear las credenciales, usa:
const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID
};
```

### 7. Deploy

Railway hará el deploy automáticamente. El dashboard estará disponible en:
`https://tu-proyecto.up.railway.app`

## 🔒 Seguridad Importante

### Configurar Reglas de Firestore

Para producción, configura reglas restrictivas en Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Solo permitir lectura para usuarios autenticados con rol admin
    match /{document=**} {
      allow read: if request.auth != null &&
        request.auth.token.admin == true;
      allow write: if false; // No permitir escritura desde dashboard
    }
  }
}
```

### Autenticación en el Dashboard

Considera agregar autenticación básica al dashboard:

1. Agregar login con Firebase Auth
2. Verificar claims de admin en el token
3. Redirigir usuarios no autorizados

## 🐛 Troubleshooting

### Build falla
- Verifica que `package.json` esté en la raíz del proyecto
- Asegúrate de que Railway pueda acceder a `npm install`

### Variables de entorno no funcionan
- Las variables deben empezar con `VITE_` para que Vite las detecte
- Reinicia el servicio después de cambiar variables

### Dashboard no carga
- Verifica las reglas de Firestore
- Revisa la consola del navegador para errores de Firebase

## 💡 Optimizaciones para Railway

### Health Check
Railway hace health checks automáticamente. El endpoint `/` debe responder.

### Logs
Los logs de Railway están disponibles en el dashboard.

### Scaling
Para alta disponibilidad, considera Railway's paid plans.

---

¡El dashboard estará listo en minutos con Railway! 🚀