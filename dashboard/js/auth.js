(function () {
  window.Dashboard = window.Dashboard || {};
  const { auth } = window.Dashboard;
  const state = window.Dashboard.state;

  async function loginDashboard() {
    const email = prompt('Email de administrador:');
    if (!email) return false;

    const password = prompt('Contraseña:');
    if (!password) return false;

    try {
      const userCredential = await auth.signInWithEmailAndPassword(email, password);
      state.currentUser = userCredential.user;
      state.isAuthenticated = true;
      window.updateAuthUI?.();
      window.refreshAll?.();
      return true;
    } catch (error) {
      let errorMessage = 'Error de autenticación: ';

      if (error.code === 'auth/invalid-login-credentials') {
        errorMessage += 'Email o contraseña incorrectos.\n\n';
        errorMessage += 'Verifica que:\n';
        errorMessage += '1. El usuario existe en Firebase Authentication\n';
        errorMessage += '2. Email/Password esté habilitado en Firebase Console\n';
        errorMessage += '3. La contraseña sea correcta';
      } else if (error.code === 'auth/user-not-found') {
        errorMessage += 'Usuario no encontrado. Crea el usuario en Firebase Console → Authentication';
      } else if (error.code === 'auth/wrong-password') {
        errorMessage += 'Contraseña incorrecta';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage += 'Email inválido';
      } else if (error.code === 'auth/operation-not-allowed') {
        errorMessage += 'Email/Password no está habilitado. Habilítalo en Firebase Console → Authentication';
      } else {
        errorMessage += error.message;
      }

      alert(errorMessage);
      console.error('Error de login:', error.code, error.message);
      return false;
    }
  }

  async function logoutDashboard() {
    try {
      await auth.signOut();
      state.currentUser = null;
      state.isAuthenticated = false;
      window.updateAuthUI?.();
      // volver a anónimo
      await authenticateDashboard();
    } catch (error) {
      console.error('Error de logout:', error);
    }
  }

  async function authenticateDashboard() {
    try {
      const existingUser = auth.currentUser;
      if (existingUser) {
        state.currentUser = existingUser;
        state.isAuthenticated = true;
        window.updateAuthUI?.();
        return true;
      }

      console.log('Modo testing: iniciando autenticación anónima...');
      const userCredential = await auth.signInAnonymously();
      state.currentUser = userCredential.user;
      state.isAuthenticated = true;
      window.updateAuthUI?.();
      return true;
    } catch (error) {
      console.error('Error autenticando dashboard (anónimo):', error);
      state.isAuthenticated = false;
      state.currentUser = null;
      window.updateAuthUI?.();
      throw error;
    }
  }

  function initAuthListener() {
    auth.onAuthStateChanged(async (user) => {
      state.currentUser = user;
      state.isAuthenticated = !!user;
      window.updateAuthUI?.();

      if (user) {
        if (state.refreshInterval) {
          clearInterval(state.refreshInterval);
          state.refreshInterval = null;
        }

        // Cargar datos iniciales
        window.refreshAll?.();

        // Real-time listeners y refresh automático deshabilitados.
        // Solo se actualiza con el botón "Actualizar".
        console.log('ℹ️ Modo manual: usa el botón Actualizar para refrescar datos.');
      } else {
        // Limpiar listeners cuando no hay usuario
        if (window.cleanupStationsListeners) {
          window.cleanupStationsListeners();
        }

        if (state.refreshInterval) {
          clearInterval(state.refreshInterval);
          state.refreshInterval = null;
        }

        if (!state.authInitialized) {
          state.authInitialized = true;
          try {
            await authenticateDashboard();
          } catch (_) { }
        }
      }
    });
  }

  // Exponer para onclick / bootstrap
  window.loginDashboard = loginDashboard;
  window.logoutDashboard = logoutDashboard;
  window.authenticateDashboard = authenticateDashboard;
  window.Dashboard.authModule = { initAuthListener };
})();


