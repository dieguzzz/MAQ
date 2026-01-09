// Firebase config + init (debe cargarse después de core.js y de firebase compat CDN scripts)
(function () {
  window.Dashboard = window.Dashboard || {};

  // Priority:
  // 1. Environment variables (injected by Vite at build time for Railway)
  // 2. window.FIREBASE_CONFIG (from firebase.config.js for local development)
  const localConfig = window.FIREBASE_CONFIG || {};

  // Helper to get env var from import.meta.env (Vite injects these at build time)
  const getEnvVar = (key) => {
    // Check if Vite injected the env vars (available after build)
    if (typeof import_meta_env !== 'undefined' && import_meta_env[key]) {
      return import_meta_env[key];
    }
    return undefined;
  };

  // Try to get config from Vite's define (set in vite.config.js)
  const firebaseConfig = {
    apiKey: (typeof VITE_FIREBASE_API_KEY !== 'undefined' ? VITE_FIREBASE_API_KEY : null) || localConfig.apiKey,
    authDomain: (typeof VITE_FIREBASE_AUTH_DOMAIN !== 'undefined' ? VITE_FIREBASE_AUTH_DOMAIN : null) || localConfig.authDomain,
    projectId: (typeof VITE_FIREBASE_PROJECT_ID !== 'undefined' ? VITE_FIREBASE_PROJECT_ID : null) || localConfig.projectId,
    storageBucket: (typeof VITE_FIREBASE_STORAGE_BUCKET !== 'undefined' ? VITE_FIREBASE_STORAGE_BUCKET : null) || localConfig.storageBucket,
    messagingSenderId: (typeof VITE_FIREBASE_MESSAGING_SENDER_ID !== 'undefined' ? VITE_FIREBASE_MESSAGING_SENDER_ID : null) || localConfig.messagingSenderId,
    appId: (typeof VITE_FIREBASE_APP_ID !== 'undefined' ? VITE_FIREBASE_APP_ID : null) || localConfig.appId,
  };

  // Validate configuration
  const isConfigured = firebaseConfig.apiKey &&
    !firebaseConfig.apiKey.includes('YOUR_') &&
    firebaseConfig.apiKey.length > 10;

  if (!isConfigured) {
    console.error('❌ Firebase not configured!');
    console.error('For local development: Copy firebase.config.example.js to firebase.config.js and add your API key.');
    console.error('For Railway: Set VITE_FIREBASE_API_KEY and other env vars in Railway dashboard.');
  }

  // Log de configuración (solo en desarrollo)
  const isDevelopment = window.location.hostname === 'localhost' ||
    window.location.hostname === '127.0.0.1' ||
    window.location.protocol === 'file:';

  if (isDevelopment) {
    console.log('Modo desarrollo - usando configuración Firebase de MetroPTY');
  }

  // Inicializar Firebase
  console.log('Inicializando Firebase con config:', {
    ...firebaseConfig,
    apiKey: firebaseConfig.apiKey ? '***' + firebaseConfig.apiKey.slice(-4) : 'undefined'
  });

  try {
    // Verificar si ya hay una app inicializada
    firebase.app();
    console.log('Firebase ya estaba inicializado');
  } catch (_) {
    // Inicializar nueva app
    firebase.initializeApp(firebaseConfig);
    console.log('Firebase inicializado exitosamente');
  }

  // Exponer Firebase globalmente
  window.Dashboard.firebase = firebase;
  window.Dashboard.db = firebase.firestore();
  window.Dashboard.auth = firebase.auth();

  console.log('Firebase expuesto en window.Dashboard:', !!window.Dashboard.auth);
})();
