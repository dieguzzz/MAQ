# 🚇 Guía de Testing: Reportes de Tiempo de Trenes → ETA Groups

## 📋 Problema Detectado

Los reportes de tiempo de trenes no se mostraban en el panel de "Próximos Trenes" en la app.

## 🔄 Flujo Correcto del Sistema

```
1. Dashboard crea reportes
   ↓ Guarda en colección: `reports`
   ↓ Campos: scope='train', stationId, direction='A'|'B', etaBucket, etc.

2. Cloud Function se dispara
   ↓ Function: `onSimplifiedEtaReportCreated`
   ↓ Lee: reportes con scope='train'
   ↓ Procesa: agrupa por estación + dirección + minuto

3. Cloud Function crea/actualiza ETA Groups
   ↓ Colección: `eta_groups`
   ↓ Documento: {stationId}_{line}_{directionCode}_{epochMinute}
   ↓ Contiene: nextEtaBucket, followingEtaBucket, confidence, etc.

4. App lee ETA Groups
   ↓ Service: `EtaGroupService.watchActiveGroupsByDirectionForStation()`
   ↓ Widget: `station_report_sheet.dart`
   ↓ UI: Panel dual con dirección A y B
```

## ✅ Cambios Realizados

### 1. **Dashboard: train_time_reports_testing.js**
- ✅ Corregida dirección de `{stationId}` a `'A'` o `'B'`
- ✅ Agregada función `verifyEtaGroupsCreation()` para diagnóstico
- ✅ Nombres de direcciones más claros en UI

### 2. **Dashboard: index.html**
- ✅ Agregado botón "🔍 Verificar ETA Groups"
- ✅ Mejoras visuales en botones

### 3. **Cloud Functions (ya desplegadas)** ✅
```
┌──────────────────────────────┬─────────┬──────────────────────────────────────────────────────┐
│ onSimplifiedEtaReportCreated │ v1      │ Firestore onCreate → reports/{reportId}              │
│ onTrainTimeReportCreated     │ v1      │ Firestore onCreate → train_time_reports/{reportId}   │
│ expireOldEtaGroups           │ v1      │ Scheduled every 5 minutes                            │
│ cleanupEtaPresence           │ v1      │ Scheduled every 5 minutes                            │
└──────────────────────────────┴─────────┴──────────────────────────────────────────────────────┘
```

## 🧪 Cómo Probar

### Paso 1: Abrir el Dashboard
```bash
cd d:\MAQ\dashboard
.\servir.ps1
```

Abrir: `http://localhost:5000`

### Paso 2: Navegar al Tab de Testing
1. Click en tab **"🕰️ Testing Tiempos de Tren"**
2. Espera a que carguen las estaciones (auto-load)

### Paso 3: Seleccionar Estación y Dirección
```
Estación: [Selecciona cualquiera, ej: "Fernández de Córdoba"]
Dirección: [Se carga automáticamente según la línea]
  - Línea 1: A = Hacia Villa Zaita, B = Hacia Albrook
  - Línea 2: A = Hacia Nuevo Tocumen, B = Hacia San Miguelito
```

### Paso 4: Configurar Tiempos
```
Próximo Tren: [Ej: 3 minutos]
Siguiente Tren: [Ej: 7 minutos] (opcional)
Número de reportes: 3
Intervalo: 30 segundos
☑ Agregar variación (±2 min)
```

### Paso 5: Generar Reportes
1. Click en **"🚀 Generar ETAs"**
2. Esperar mensaje: ✅ 3 reportes generados exitosamente
3. Ver lista de reportes generados

### Paso 6: Verificar ETA Groups 🔍
1. Click en **"🔍 Verificar ETA Groups"** (botón morado)
2. Revisar el diagnóstico:
   - ✅ **Reportes en Firestore**: Debe mostrar los reportes creados
   - ✅ **ETA Groups creados**: Debe mostrar grupos agregados
   - ⚠️ **Si no hay ETA Groups**: Las Cloud Functions tienen un error

### Paso 7: Verificar en la App
1. Abrir la app en el dispositivo/emulador
2. Click en la estación que usaste
3. Buscar el panel **"Próximos Trenes"**
4. Debe mostrar:
   ```
   🚇 Próximos Trenes
   
   → Hacia Villa Zaita
   Próximo: 3-5 min
   Siguiente: 6-8 min
   
   → Hacia Albrook
   Sin datos disponibles
   ```

## 🐛 Troubleshooting

### Problema 1: No se muestran estaciones en el selector
**Causa:** El tab no se inicializó correctamente
**Solución:** Refrescar página (F5) o cambiar de tab y volver

### Problema 2: Reportes generados pero NO hay ETA Groups
**Causa:** Cloud Function falló al procesar
**Solución:**
1. Verificar logs de Firebase:
   ```bash
   cd d:\MAQ
   firebase functions:log --only onSimplifiedEtaReportCreated
   ```
2. Verificar campos del reporte:
   - ✅ `scope === 'train'`
   - ✅ `direction === 'A'` o `'B'` (no un ID de estación)
   - ✅ `etaBucket !== 'unknown'`
   - ✅ `stationId` existe
   - ✅ `userId` existe

### Problema 3: ETA Groups existen pero no se muestran en la app
**Causa:** El panel está leyendo grupos expirados
**Solución:**
1. Verificar campo `expiresAt` del grupo (debe ser > now)
2. Verificar campo `status` === 'active'
3. Generar reportes más recientes (< 10 minutos)

### Problema 4: Error "direction code inválido"
**Causa:** El dashboard estaba usando IDs de estaciones como dirección
**Solución:** ✅ Ya corregido - ahora usa 'A' o 'B'

## 📊 Formato Correcto del Reporte

```javascript
{
  // ✅ REQUERIDOS
  scope: 'train',
  stationId: 'fernandez_de_cordoba',
  userId: 'abc123',
  direction: 'A',  // ← IMPORTANTE: 'A' o 'B', NO un stationId
  etaBucket: '3-5', // '1-2', '3-5', '6-8', '9+'
  trainLine: 'linea1',
  createdAt: Timestamp,
  
  // ✅ OPCIONALES (mejoran confidence)
  isPanelTime: true,  // Si viene del panel oficial
  etaExpectedAt: Timestamp, // Cuándo se espera el tren
  basePoints: 10,
  totalPoints: 15,
  status: 'active'
}
```

## 🎯 Formato Esperado del ETA Group

```javascript
{
  id: 'fernandez_de_cordoba_linea1_A_28123456',
  stationId: 'fernandez_de_cordoba',
  line: 'linea1',
  directionCode: 'A',
  directionLabel: 'Villa Zaita',
  
  nextEtaBucket: '3-5',
  nextEtaMinutesP50: 4,  // Mediana de todos los reportes
  nextEtaExpectedAt: Timestamp,
  
  followingEtaBucket: '6-8',
  followingEtaMinutesP50: 7,
  followingEtaExpectedAt: Timestamp,
  
  reportCount: 3,
  presenceCount: 2,
  arrivedCount: 1,
  confidence: 0.72,  // 0..1
  
  status: 'active',
  bucketStart: Timestamp,
  updatedAt: Timestamp,
  expiresAt: Timestamp  // bucketStart + 10 minutos
}
```

## 📈 Interpretación de Confidence

```javascript
Confidence = reportScore (25%) 
           + presenceScore (20%) 
           + arrivedScore (15%)
           + consensusScore (35%)
           + panelScore (10%)
           + authorScore (20%)
           + recencyScore (10%)

≥ 0.7 = 🟢 High confidence
0.4-0.7 = 🟡 Medium confidence
< 0.4 = 🔴 Low confidence
```

## 🔧 Comandos Útiles

### Ver logs de Cloud Functions
```bash
cd d:\MAQ
firebase functions:log --only onSimplifiedEtaReportCreated
```

### Limpiar reportes antiguos (Firestore Console)
```
Colección: reports
Filtro: scope == 'train' AND createdAt < yesterday
Acción: Delete documents
```

### Limpiar eta_groups antiguos
```
Colección: eta_groups
Filtro: status == 'expired'
Acción: Delete documents (las functions ya marcan como expired automáticamente)
```

## ✅ Checklist de Verificación

- [ ] Dashboard carga estaciones automáticamente
- [ ] Selector de dirección muestra opciones correctas (A/B)
- [ ] Reportes se generan sin errores
- [ ] Reportes aparecen en colección `reports` con scope='train'
- [ ] ETA Groups aparecen en colección `eta_groups`
- [ ] ETA Groups tienen status='active' y expiresAt > now
- [ ] App muestra panel "Próximos Trenes" con datos
- [ ] Confidence es razonable (> 0.4)
- [ ] Los tiempos mostrados coinciden con lo reportado

## 📞 Contacto

Si después de seguir esta guía los reportes aún no se muestran:
1. Ejecutar "🔍 Verificar ETA Groups" en el dashboard
2. Revisar logs de Firebase Functions
3. Verificar formato de los reportes en Firestore
4. Comprobar que las Cloud Functions están desplegadas

**Última actualización:** 2025-01-07

