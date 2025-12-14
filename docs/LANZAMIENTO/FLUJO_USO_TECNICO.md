# 🚇 Flujo de Uso de MetroPTY - Versión Técnica Unificada

**Versión:** 1.0 | **Fecha:** 2025-12-14  
**Branch:** `lanzamiento-semana1`

---

## 📱 Experiencia del Usuario Paso a Paso

### 1. Primer Uso (Onboarding)

#### Pantalla 1 → "Bienvenido a MetroPTY"
```
"La comunidad del metro panameño"
```

#### Pantalla 2 → "Tu privacidad es importante"
- "Usamos tu ubicación para mostrar trenes en vivo"
- "Puedes desactivarlo cuando quieras"
- "Tus datos son anónimos y seguros"

#### Pantalla 3 → "¿Cómo funciona?"
- "Reportas cómo está el metro"
- "Otros usuarios confirman tu reporte"
- "Todos vemos la información en tiempo real"

#### Pantalla 4 → "¡Empieza a ganar puntos!"
- Sistema de niveles y logros
- Ranking comunitario
- Beneficios premium

---

### 2. Pantalla Principal - Mapa en Tiempo Real

#### Lo que el usuario VE:

```
┌───────────────────────────────────┐
│           MAPA PRINCIPAL          │
├───────────────────────────────────┤
│  LÍNEA 1 (AZUL):                 │
│  ● San Isidro      [2min] 🟢     │
│  ● El Ingenio      [3min] 🟡     │
│  ● Fernández       [RETRASO] 🔴  │
│  └──🚇•• (65%) → 3 confirmaciones │
│                                   │
│  LÍNEA 2 (VERDE):                │
│  ● San Miguelito   [4min] 🟢     │
│  ● Pedregal        [LLENO] 🔴    │
│  └──🚇■ (detenido) → baja confianza│
├───────────────────────────────────┤
│ [REPORTE RÁPIDO]        [MI PERFIL]│
└───────────────────────────────────┘
```

#### Indicadores Clave:

- 🚇•• = Tren moviéndose normalmente
- 🚇■ = Tren detenido
- 🟢/🟡/🔴 = Estado de la estación
- [2min] = Tiempo estimado (alta confianza)
- → 3 confirmaciones = Reporte verificado por 3 usuarios

---

### 3. Flujo de Reporte (3 Toques Máximo)

**Escenario:** Usuario está en "5 de Mayo" y está llenísimo

```
1. TOCA estación en el mapa
   → Modal rápido aparece

2. SELECCIONA estado:
   ○ 🟢 Normal
   ○ 🟡 Moderado
   ● 🔴 Llenísimo
   ○ ⚠️ Retraso
   ○ 🚫 Cerrado

3. CONFIRMA
   → Animación de éxito
   → "+10 puntos"
   → "Reporte enviado"
   → "Esperando confirmaciones..."
```

#### Detrás de escenas:

```javascript
// 1. App envía reporte a Firestore
reports/abc123 = {
  userId: "user_789",
  type: "station",
  targetId: "station_5demayo",
  category: "crowd",
  location: GeoPoint(...),
  status: "active"
}

// 2. Cloud Function processNewReport se activa
// Busca reportes similares en los últimos 5 minutos
// Si encuentra 2+ coincidencias → marca como "community_verified"

// 3. Si es verificado:
// - Actualiza station.status = "crowded"
// - Actualiza station.confidence = "high"
// - Otorga +10 puntos al usuario
```

---

### 4. Flujo de Viaje con Tracking Automático

**Escenario:** Usuario toma el metro en San Isidro hacia Albrook

```
7:00 AM - Usuario abre app
→ GPS detecta ubicación cerca de estación San Isidro
→ "¿Iniciar seguimiento de viaje? (+5 pts)"
→ Usuario acepta

7:02 AM - Usuario sube al tren
→ App detecta velocidad >20 km/h
→ Envía señal a user_signals/:
  {
    userId: "user_789",
    location: GeoPoint(near_SanIsidro),
    speedKmh: 45,
    line: "L1",
    direction: "A",
    timestamp: 7:02:00
  }

7:03 AM - Cloud Function updateTrainStateFromSignals
→ Agrupa señales de otros 3 usuarios en mismo segmento
→ Calcula: velocidad promedio = 42 km/h
→ Actualiza train_state/L1_A_001:
  {
    segment: { from: "san_isidro", to: "el_ingenio" },
    position: 0.25, // 25% del trayecto
    speedKmh: 42,
    status: "moving",
    confidence: "high"
  }

7:05 AM - Todos los usuarios ven en el mapa:
"Tren L1_A_001 a 25% entre San Isidro y El Ingenio, 42 km/h, alta confianza"
```

---

### 5. Sistema de Verificación Comunitaria

Cuando reportas algo, otros usuarios pueden confirmar:

```
Notificación push:
"Carlos reportó 'LLENÍSIMO' en 5 de Mayo. ¿Confirmas?"

Usuario ve:
┌─────────────────────────┐
│   ¿Cómo está realmente? │
├─────────────────────────┤
│ ○ 🟢 Vacío              │
│ ○ 🟡 Moderado           │
│ ● 🔴 Llenísimo          │
│ ○ ❌ No estoy allí      │
├─────────────────────────┤
│ [CONFIRMAR]  [OMITIR]   │
└─────────────────────────┘

Si 3+ usuarios confirman lo mismo:
→ Reporte se marca como "community_verified"
→ station.status se actualiza automáticamente
→ Todos ganan +5 puntos
→ Confianza sube a "high"
```

---

### 6. Planificación de Ruta Inteligente

Usuario quiere ir de San Miguelito a Vía Argentina:

```
1. Toca "PLANIFICAR RUTA"
2. Selecciona origen: San Miguelito
3. Selecciona destino: Vía Argentina
4. App calcula considerando:

   Datos en tiempo real:
   - Tren L2_A_001: 70% lleno, moviéndose normal
   - Estación Pedregal: moderada congestión
   - Tiempo transferencia: 4 minutos

   Resultado:
   ┌─────────────────────────────┐
   │ Ruta Óptima (18 min)        │
   ├─────────────────────────────┤
   │ 1. San Miguelito → Albrook  │
   │    🚇 8 min (🟡 Moderado)   │
   │                             │
   │ 2. Transferencia: 4 min     │
   │                             │
   │ 3. Albrook → Vía Argentina  │
   │    🚇 6 min (🟢 Normal)     │
   ├─────────────────────────────┤
   │ Alternativa: 22 min (menos  │
   │ congestión en Pedregal)     │
   └─────────────────────────────┘
```

---

### 7. Gamificación en Tiempo Real

Mientras usas la app:

```
+10 pts → Reporte verificado
+5 pts  → Confirmaste reporte ajeno
+2 pts  → Racha diaria (día 7: +10 pts)
+15 pts → Alertaste sobre problema grave
+20 pts → Logro desbloqueado

Notificaciones motivacionales:
"¡Subiste al nivel 15 - Reportero Élite!"
"Eres el #3 en contribuciones esta semana"
"Tu reporte ayudó a 50 personas hoy"
```

---

### 8. Sistema de Confianza (Confidence Levels)

Cómo se muestran los diferentes niveles de confianza:

```
Alta Confianza (🟢):
"Próximo tren: 3 min"
→ Basado en 5+ señales de usuarios
→ O reporte verificado reciente

Media Confianza (🟡):
"Próximo tren: ~5-7 min"
→ Basado en 2-4 señales
→ O datos históricos

Baja Confianza (🔴):
"Próximo tren: desconocido"
→ Pocos o ningún dato reciente
→ "Sé el primero en reportar"
```

---

### 9. Flujo Premium vs Free

#### Usuario Free ve:

```
✅ Mapa completo en tiempo real
✅ Reportar y verificar
✅ Tiempos estimados
✅ Planificación básica de rutas
✅ Sistema de puntos y niveles
✅ Notificaciones de retrasos graves

🔼 [UPGRADE A PREMIUM]
```

#### Usuario Premium ($2.99/mes) ve además:

```
🎯 Alertas 15 min antes (vs 5 min free)
📊 Dashboard personal de estadísticas
🌙 Tema oscuro exclusivo
💾 Mapas offline completos
🚀 Reportes marcados como prioritarios
👑 Badge "Héroe Premium" en perfil
```

---

### 10. Manejo de Casos Especiales

#### Caso 1: Pocos usuarios en una línea

```
App detecta: solo 1 señal en Línea 2
Muestra: "Datos limitados - Confianza baja"
Ofrece: "¿Estás en esta línea? Reporta para mejorar la precisión"
```

#### Caso 2: Reportes conflictivos

```
3 usuarios: "Estación normal"
1 usuario: "Estación llena"

Sistema: 
- Mayoría gana (estado: normal)
- Pero baja confianza a "medium"
- Muestra: "Mayoría reporta normal (1 discrepancia)"
```

#### Caso 3: Sin datos (noche/madrugada)

```
Muestra: "Basado en horarios históricos"
Indicador: "⏳ Datos históricos, baja confianza"
Botón: "Sé el primero en reportar hoy"
```

---

## 🎯 RESUMEN: Lo que el Usuario EXPERIMENTA

- Abre la app → Ve trenes moviéndose en tiempo real
- Reporta en 3 toques → Gana puntos inmediatos
- Viaja en metro → App detecta automáticamente, mejora datos para todos
- Confirma reportes ajenos → Ayuda a la comunidad, gana puntos
- Sube de nivel → Desbloquea badges y reconocimiento
- Planifica rutas → Considera congestión en tiempo real
- Ve su impacto → "Ayudaste a X personas hoy"
- Decide si upgrade → Features premium como valor agregado, no necesidad

---

## 🔄 Ciclo Virtuoso que se Crea

```
MÁS USUARIOS REPORTANDO
        ↓
MEJORES DATOS EN TIEMPO REAL
        ↓
APP MÁS ÚTIL PARA TODOS
        ↓
MÁS USUARIOS SE UNEN
        ↓
MÁS INGRESOS POR ADS/PREMIUM
        ↓
MÁS INVERSIÓN EN MEJORAS
        ↑
        └─────────────────┘
```

**La magia:** Cada usuario es simultáneamente consumidor Y productor de datos. La app mejora literalmente con cada uso.

---

**Última actualización:** 2025-12-14
