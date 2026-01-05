// Firebase config + init (debe cargarse después de core.js y de firebase compat CDN scripts)
(function () {
  window.Dashboard = window.Dashboard || {};

  const firebaseConfig = {
    apiKey: "AIzaSyBKqEztWsaiwmRE-GqhmPit0CJOjzDwpPk",
    authDomain: "Metropty.firebaseapp.com",
    projectId: "metropty-aa303",
    storageBucket: "gs://metropty-aa303.firebasestorage.app",
    messagingSenderId: "443011769374",
    appId: "1:443011769374:android:fdd1f064d5429d4c93ba0f",
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


