// Firebase config + init (debe cargarse después de core.js y de firebase compat CDN scripts)
(function () {
  window.Dashboard = window.Dashboard || {};

  // Configuración de Firebase usando variables de entorno (SIN FALLBACKS POR SEGURIDAD)
  const firebaseConfig = {
    apiKey: import.meta.env?.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env?.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env?.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env?.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env?.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env?.VITE_FIREBASE_APP_ID,
  };

  // Validar que todas las variables de entorno estén configuradas
  const requiredKeys = ['apiKey', 'authDomain', 'projectId', 'storageBucket', 'messagingSenderId', 'appId'];
  const missingKeys = requiredKeys.filter(key => !firebaseConfig[key]);

  if (missingKeys.length > 0) {
    throw new Error(`Variables de entorno faltantes: ${missingKeys.join(', ')}. Configura las variables VITE_FIREBASE_*`);
  }

  // Evitar doble init si el archivo se carga 2 veces por error
  try {
    firebase.app();
  } catch (_) {
    firebase.initializeApp(firebaseConfig);
  }

  window.Dashboard.firebase = firebase;
  window.Dashboard.db = firebase.firestore();
  window.Dashboard.auth = firebase.auth();
})();


