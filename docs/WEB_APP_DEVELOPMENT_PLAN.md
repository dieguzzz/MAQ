# Plan de Desarrollo — MetroPTY Web

> Versión web de MetroPTY para iterar más rápido sobre UX, features y diseño antes de portar mejoras a la app Flutter (Android/iOS). Reutiliza el backend Firebase existente.

---

## 1. Análisis del repo actual

**App Flutter** (`lib/`): Provider para estado, Firebase (Firestore + Auth + Messaging + Storage + Functions), Google Maps, IAP, Ads. Dominio: estaciones, trenes, reportes simplificados, ETA groups, gamificación, learning/calibración, rutas, suscripciones premium, panel admin.

**Dashboard** (`dashboard/`): HTML + Vite vanilla, solo para administración interna. **No es la web app de usuario** que queremos construir.

**Backend**: `firestore.rules`, `firestore.indexes.json`, `functions/` (Cloud Functions), reglas ya existentes y probadas en producción.

**Modelos clave a reutilizar**: `station_model`, `train_model`, `simplified_report_model`, `eta_group_model`, `user_model`, `gamification_model`, `route_model`.

---

## 2. Objetivos de la versión web

1. Paridad funcional con la app móvil para flujos principales: mapa en tiempo real, reportes, rutas, perfil/gamificación, premium.
2. Iteración rápida de diseño y UX (hot reload web, despliegues por PR).
3. Reutilizar 100% del backend (Firestore/Functions/Auth) sin migraciones.
4. PWA instalable, responsive (desktop + móvil), accesible (WCAG AA).
5. Base para luego portar mejoras al cliente Flutter.

**Fuera de alcance v1 web**: notificaciones push nativas avanzadas, IAP nativo (usar Stripe/web), background location.

---

## 3. Stack tecnológico

| Capa | Elección | Por qué |
|------|----------|---------|
| Framework | **Next.js 15 (App Router) + React 19 + TypeScript** | SSR/ISR, routing, DX, ecosistema |
| Estilos | **Tailwind CSS + shadcn/ui** | Productividad, theming nativo, accesibilidad |
| Theming | CSS variables + `next-themes` | Light/dark + temas por línea de Metro |
| Estado servidor | **TanStack Query** | Cache, sync, optimistic updates con Firestore |
| Estado cliente | **Zustand** | Ligero, sin boilerplate (reemplaza Provider) |
| Backend SDK | **Firebase Web SDK v10** (modular) | Mismo proyecto Firebase actual |
| Mapas | **Google Maps JS API** (`@vis.gl/react-google-maps`) | Paridad con app Flutter, misma API key/proyecto |
| Formularios | **react-hook-form + zod** | Validación tipada |
| Tests | **Vitest + Testing Library + Playwright** | Unit + e2e |
| Lint/format | **ESLint + Prettier + TypeScript strict** | Calidad |
| Hooks pre-commit | **Husky + lint-staged** | Evitar commits rotos |
| CI/CD | **GitHub Actions → Railway** | Mismo proveedor que el dashboard actual; `railway.json`/`nixpacks.toml` ya en el repo |
| Analítica | Firebase Analytics + Sentry | Errores y métricas |
| i18n | **next-intl** | ES base, EN opcional |
| Pagos web | **Stripe** vía Cloud Function | Sustituye IAP en web |

---

## 4. Arquitectura modular

```
web/
├── app/                          # Next.js App Router
│   ├── (public)/                 # rutas sin auth: landing, login
│   ├── (app)/                    # rutas con auth
│   │   ├── map/
│   │   ├── reports/
│   │   ├── routes/
│   │   ├── profile/
│   │   ├── leaderboards/
│   │   └── premium/
│   ├── (admin)/                  # panel admin (gated por claim)
│   ├── api/                      # route handlers (server actions)
│   └── layout.tsx
├── src/
│   ├── features/                 # módulos de dominio (vertical slices)
│   │   ├── auth/
│   │   ├── stations/
│   │   ├── trains/
│   │   ├── reports/
│   │   ├── eta/
│   │   ├── routes/
│   │   ├── gamification/
│   │   ├── premium/
│   │   └── admin/
│   │       └── <feature>/
│   │           ├── components/
│   │           ├── hooks/
│   │           ├── services/     # firestore queries
│   │           ├── schemas/      # zod
│   │           └── types.ts
│   ├── components/ui/            # shadcn primitives
│   ├── components/shared/        # header, nav, map shell
│   ├── lib/
│   │   ├── firebase/             # init client + admin
│   │   ├── analytics/
│   │   └── utils/
│   ├── stores/                   # zustand stores globales
│   ├── styles/                   # tokens, themes
│   └── config/                   # env, constants, rutas
├── public/
├── tests/
└── package.json
```

**Principios**
- Vertical slicing por feature, no por tipo de archivo.
- `services/` aísla todo acceso a Firestore (fácil de testear/mockear).
- Componentes server por defecto; `"use client"` solo donde sea necesario (mapa, formularios, realtime).
- Sin lógica de negocio en componentes — siempre en hooks/services.

---

## 5. Diseño y temas

- **Design tokens** en CSS variables: colores por línea (L1 verde, L2 azul, L3, etc.), spacing, radii, motion.
- **Modos**: light, dark, high-contrast (a11y).
- **Tema dinámico por línea** cuando el usuario está viendo una estación específica.
- **Tipografía**: misma familia que la app (Google Fonts ya en uso) para consistencia.
- **Componentes base**: shadcn/ui personalizado con tokens de MetroPTY.
- **Mobile-first**, breakpoints `sm/md/lg/xl`.
- **Storybook** opcional para catalogar componentes.
- **Accesibilidad**: foco visible, ARIA en mapa, contraste AA, soporte teclado completo.

---

## 6. Seguridad

| Área | Medida |
|------|--------|
| Auth | Firebase Auth (Google + email). Custom claims para admin/premium. |
| Reglas | Reutilizar `firestore.rules` actuales; auditar para web (CORS, App Check). |
| App Check | **reCAPTCHA v3** para web — bloquea clientes no autorizados a Firestore/Functions. |
| Secrets | `.env.local` para dev; **Railway Variables** en producción. **Nunca** claves privadas en cliente. |
| API keys públicas | Restricción por **dominio HTTP referrer** y por API (Maps JS, Places) en Google Cloud Console. |
| CSP | Header estricto vía `next.config.js` (script-src, connect-src Firebase/Maps). |
| Headers | HSTS, X-Frame-Options, Referrer-Policy, Permissions-Policy. |
| Validación | zod en cliente **y** en Cloud Functions (defensa en profundidad). |
| Rate limiting | Cloud Functions con limitador (ej. Firestore counter o Upstash). |
| XSS | React por defecto + sanitizar markdown si lo hay. |
| Logs | Sentry sin PII; scrubbing de campos sensibles. |
| Dependencias | `npm audit` + Dependabot + revisión semanal. |
| Pagos | Stripe (PCI delegado), webhooks firmados. |
| Premium gating | Verificar claim en server, no solo cliente. |

---

## 7. Roadmap por fases

### Fase 0 — Cimientos (semana 1)
- Crear carpeta `web/` con Next.js 15 + TS strict + Tailwind + shadcn.
- Configurar Firebase Web SDK reusando proyecto actual.
- Layout base, theming light/dark, design tokens.
- CI: lint + typecheck + tests en PR. Deploy en **Railway** (servicio nuevo `web/`, build con Nixpacks, `next start` en `$PORT`). Preview environments por rama si el plan lo permite.
- App Check + reglas de seguridad básicas (CSP, headers).

### Fase 1 — Auth + Mapa lectura (semanas 2-3)
- Login Google + email. Guards de ruta. Custom claims.
- Mapa con estaciones y líneas (datos en `lib/data/` migrados a `src/config/metro-data.ts`).
- Lectura en tiempo real de estado de estaciones/trenes desde Firestore.
- Panel lateral con detalle de estación.

### Fase 2 — Reportes (semanas 4-5)
- Formulario de reporte simplificado (mismo modelo `simplified_report`).
- Confianza/agregación en cliente reutilizando lógica de servicios Flutter (portar a TS).
- Validación zod + reglas Firestore.
- Vista de reportes recientes.

### Fase 3 — Rutas y ETA (semanas 6-7)
- Planificador de rutas (portar `route_calculation_service`).
- ETA groups en mapa.
- Filtros y comparativa de rutas.

### Fase 4 — Gamificación + Perfil (semana 8)
- Perfil, badges, niveles, leaderboard.
- Historial de puntos.

### Fase 5 — Premium + Admin (semanas 9-10)
- Suscripciones web vía Stripe + Cloud Function que escribe claim.
- Panel admin (reemplaza/extiende `dashboard/` actual): aprobación de reportes, calibración de estaciones, learning data.

### Fase 6 — PWA, pulido, a11y, perf (semana 11)
- Manifest + service worker (next-pwa) — offline básico para mapa.
- Auditoría Lighthouse ≥ 90 en las 4 categorías.
- Pruebas e2e principales con Playwright.
- i18n ES/EN.

### Fase 7 — Lanzamiento + retroalimentación a Flutter (semana 12)
- Beta cerrada, telemetría.
- Documentar decisiones de UX para portar a la app móvil.

---

## 8. Buenas prácticas transversales

- **TypeScript strict** + `noUncheckedIndexedAccess`.
- **Convencional commits** + PRs pequeños, un feature por PR.
- **Code review** obligatorio. CODEOWNERS por feature.
- **Tests**: unit para servicios/utils, integration para hooks, e2e para flujos críticos (login, reportar, planear ruta).
- **Documentación**: README por feature + ADRs en `docs/adr/` para decisiones grandes.
- **Feature flags** (Firebase Remote Config) para releases progresivos.
- **Observabilidad**: Sentry + Firebase Performance + Web Vitals.
- **Performance budget**: LCP < 2.5s, TBT < 200ms, bundle inicial < 200KB gzip.

---

## 9. Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|-----------|
| Divergencia lógica web vs Flutter | Extraer reglas (confianza, agregación) a especificación versionada en `docs/spec/` |
| Costos de Google Maps | Restringir API key por dominio, cachear tiles donde se pueda, monitorear cuota en GCP Billing alerts |
| Reglas Firestore no compatibles con web | Auditar y añadir tests con emulator suite |
| IAP vs Stripe (precios distintos) | Tabla de equivalencias y claim unificado `premium=true` |
| SEO / SSR con Firebase | Datos públicos vía Admin SDK en server components |

---

## 10. Próximos pasos inmediatos

1. ✅ Aprobar este plan.
2. Decisiones tomadas: **deploy en Railway**, **Google Maps JS** para mapas.
3. Crear `web/` con scaffold Next.js + `railway.json`/`nixpacks.toml` para el nuevo servicio (Fase 0).
4. Migrar `lib/data/` (estaciones, líneas) a TS y publicar como paquete local compartible si en el futuro se quiere monorepo.
5. Definir mockups de mapa + flujo de reporte (Figma).

---

*Plan vivo — actualizar al cerrar cada fase.*
