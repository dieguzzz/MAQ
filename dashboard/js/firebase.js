// Firebase config + init (debe cargarse después de core.js y de firebase compat CDN scripts)
(function () {
  window.Dashboard = window.Dashboard || {};

  // Configuración de Firebase - compatible con módulos ES6 y scripts normales
  const getEnvVar = (key) => {
    // Intentar obtener de import.meta.env (módulos ES6)
    try {
      if (typeof window !== 'undefined' && window.importMetaEnv && window.importMetaEnv[key]) {
        return window.importMetaEnv[key];
      }
    } catch (e) {
      // Ignorar errores si import.meta no está disponible
    }

    // Intentar obtener de window (variables globales inyectadas por Vite/Railway)
    if (typeof window !== 'undefined' && window[key]) {
      return window[key];
    }

    // Intentar obtener de process.env (Node.js)
    if (typeof process !== 'undefined' && process.env && process.env[key]) {
      return process.env[key];
    }

    return undefined;
  };

  const firebaseConfig = {
    apiKey: getEnvVar('VITE_FIREBASE_API_KEY') || 'AIzaSyBKqEztWsaiwmRE-GqhmPit0CJOjzDwpPk',
    authDomain: getEnvVar('VITE_FIREBASE_AUTH_DOMAIN') || 'metropty-aa303.firebaseapp.com',
    projectId: getEnvVar('VITE_FIREBASE_PROJECT_ID') || 'metropty-aa303',
    storageBucket: getEnvVar('VITE_FIREBASE_STORAGE_BUCKET') || 'metropty-aa303.firebasestorage.app',
    messagingSenderId: getEnvVar('VITE_FIREBASE_MESSAGING_SENDER_ID') || '443011769374',
    appId: getEnvVar('VITE_FIREBASE_APP_ID') || '1:443011769374:web:d55dc805031e69c993ba0f',
  };

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

