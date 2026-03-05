import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
  // Load env vars from .env files
  const env = loadEnv(mode, process.cwd(), '');

  return {
    server: {
      host: '0.0.0.0',
      port: 3000
    },
    preview: {
      host: '0.0.0.0',
      port: 3000
    },
    build: {
      outDir: 'dist',
      assetsDir: 'assets'
    },
    // Inject env vars as global constants (available in non-module JS files)
    define: {
      VITE_FIREBASE_API_KEY: JSON.stringify(env.VITE_FIREBASE_API_KEY || ''),
      VITE_FIREBASE_AUTH_DOMAIN: JSON.stringify(env.VITE_FIREBASE_AUTH_DOMAIN || ''),
      VITE_FIREBASE_PROJECT_ID: JSON.stringify(env.VITE_FIREBASE_PROJECT_ID || ''),
      VITE_FIREBASE_STORAGE_BUCKET: JSON.stringify(env.VITE_FIREBASE_STORAGE_BUCKET || ''),
      VITE_FIREBASE_MESSAGING_SENDER_ID: JSON.stringify(env.VITE_FIREBASE_MESSAGING_SENDER_ID || ''),
      VITE_FIREBASE_APP_ID: JSON.stringify(env.VITE_FIREBASE_APP_ID || ''),
    }
  };
});