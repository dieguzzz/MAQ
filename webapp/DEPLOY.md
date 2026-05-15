# Deploy en Railway

## Configuración del servicio

1. **New Project → Deploy from GitHub repo** → selecciona `dieguzzz/maq`.
2. En Settings → **Root Directory**: `webapp`.
3. Builder: **Nixpacks** (auto-detectado vía `nixpacks.toml`).
4. Start command: `npm start` (ya en `railway.json`).

## Variables de entorno (Settings → Variables)

Copia desde `.env.example` y pega los valores reales:

```
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=...
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=...
NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID=...
NEXT_PUBLIC_APP_URL=https://<tu-dominio>
```

> Importante: aunque las `NEXT_PUBLIC_*` son visibles en el cliente, restringe las API keys por **HTTP Referrer** en Google Cloud Console y por **Authorized Domains** en Firebase Auth.

## Dominio

1. Settings → **Networking** → Generate Domain (o Custom Domain).
2. Añade el dominio en Firebase Auth → Authorized Domains.
3. Añade el dominio en Google Cloud Console → Maps API key → HTTP referrers.
4. Actualiza `NEXT_PUBLIC_APP_URL` con el dominio final.

## Verificación post-deploy

- `/` debería redirigir a `/map` (si autenticado) o `/login`.
- DevTools → Application → Service Worker: `sw.js` registrado, scope `/`.
- DevTools → Application → Manifest: ícono y shortcuts cargados.
- Lighthouse: PWA installable, Performance > 90, Accessibility > 95.
