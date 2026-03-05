# 📊 Debug Logs - Página Web

Esta página web te permite ver los logs de depuración de la app en tiempo real desde tu navegador.

## 🚀 Configuración

### 1. Configuración de Firebase

La página `web/debug_logs.html` ya está configurada con las credenciales de Firebase desde `lib/firebase_options.dart`. No necesitas hacer nada adicional.

Si necesitas cambiar la configuración, edita el objeto `firebaseConfig` en el archivo HTML.

### 2. Habilitar modo test en la app

1. Abre la app en tu dispositivo/emulador
2. Ve a Configuración
3. Activa el "Modo Test"
4. Los logs comenzarán a guardarse en Firestore automáticamente

### 3. Abrir la página web

Tienes varias opciones:

#### Opción A: Abrir directamente el archivo HTML
1. Abre `web/debug_logs.html` en tu navegador
2. La página se conectará a Firestore y mostrará los logs

#### Opción B: Servir con un servidor local
```bash
# Con Python
cd web
python -m http.server 8000

# O con Node.js
npx http-server web -p 8000
```

Luego abre: `http://localhost:8000/debug_logs.html`

#### Opción C: Desplegar en Firebase Hosting
```bash
# Inicializar Firebase Hosting (si no lo has hecho)
firebase init hosting

# Desplegar
firebase deploy --only hosting
```

Luego abre: `https://TU_PROJECT_ID.web.app/debug_logs.html`

## 📋 Reglas de Firestore

Las reglas de Firestore ya están configuradas en `firestore.rules`:

```javascript
match /debug_logs/{logId} {
  allow read: if true; // Permitir lectura pública (solo para debug)
  allow write: if request.auth != null; // Solo usuarios autenticados pueden escribir
}
```

**Nota**: En producción, considera restringir la lectura a usuarios autenticados cambiando `allow read: if true;` a `allow read: if request.auth != null;`

## 🎯 Características

- ✅ **Tiempo real**: Los logs aparecen automáticamente cuando se generan
- ✅ **Filtrado**: Filtra por categoría (ReportsStream, ConfirmReports, etc.)
- ✅ **Estadísticas**: Ve contadores de logs por nivel (info, success, warning, error)
- ✅ **Auto-scroll**: Activa/desactiva el scroll automático
- ✅ **Colores**: Cada nivel de log tiene un color diferente
- ✅ **Timestamps**: Cada log muestra la hora exacta

## 🔍 Categorías de Logs

- **ReportsStream**: Logs del stream de reportes activos
- **ConfirmReports**: Logs de la pantalla de confirmar reportes

## 🛠️ Solución de Problemas

### No aparecen logs
1. Verifica que el modo test esté activado en la app
2. Verifica que las reglas de Firestore permitan lectura
3. Abre la consola del navegador (F12) para ver errores
4. Verifica que la configuración de Firebase sea correcta

### Error de conexión
- Verifica que el `projectId` en la configuración sea correcto
- Asegúrate de que Firestore esté habilitado en tu proyecto Firebase
- Verifica que no haya restricciones de red/firewall

## 📝 Notas

- Los logs se guardan en la colección `debug_logs` de Firestore
- Se mantienen los últimos 500 logs
- Los logs antiguos se eliminan automáticamente después de un tiempo
- Solo funciona cuando la app está en modo test

