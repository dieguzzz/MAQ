// Firebase config + init (debe cargarse después de core.js y de firebase compat CDN scripts)
(function () {
  window.Dashboard = window.Dashboard || {};

  // Configuración de Firebase usando variables de entorno
  const firebaseConfig = {
    apiKey: import.meta.env?.VITE_FIREBASE_API_KEY || "AIzaSyBKqEztWsaiwmRE-GqhmPit0CJOjzDwpPk",
    authDomain: import.meta.env?.VITE_FIREBASE_AUTH_DOMAIN || "Metropty.firebaseapp.com",
    projectId: import.meta.env?.VITE_FIREBASE_PROJECT_ID || "metropty-aa303",
    storageBucket: import.meta.env?.VITE_FIREBASE_STORAGE_BUCKET || "metropty-aa303.appspot.com",
    messagingSenderId: import.meta.env?.VITE_FIREBASE_MESSAGING_SENDER_ID || "443011769374",
    appId: import.meta.env?.VITE_FIREBASE_APP_ID || "1:443011769374:android:fdd1f064d5429d4c93ba0f",
  };

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


