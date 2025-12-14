# 📋 Resumen de Reestructuración - Sistema de Reportes

## ✅ Cambios Implementados

### 1. **Modelo Simplificado**
- ✅ `SimplifiedReportModel`: Estructura plana (sin objetos anidados)
- ✅ Campos directos: `stationOperational`, `stationCrowd`, `trainCrowd`, `etaBucket`
- ✅ Ubicación opcional: `userLocation` y `accuracy` son nullable

### 2. **Flujos Simplificados**

#### **Reporte de Estación:**
- ✅ **Paso 1 (obligatorio)**: 2 preguntas (operativa + llena)
- ✅ **Detalles opcionales**: Se muestran en la misma pantalla si el usuario toca "Agregar detalles"
- ✅ Todo en una pantalla, sin pasos separados

#### **Reporte de Tren:**
- ✅ **Todo en una pantalla**
- ✅ Ocupación (obligatorio)
- ✅ Estado (opcional)
- ✅ ETA bucket (opcional pero recomendado)

### 3. **Bottom Sheet Mejorado**
- ✅ Dos botones grandes separados:
  - **A. REPORTAR ESTACIÓN** (azul)
  - **B. REPORTAR TREN** (verde)
- ✅ Información de estado actual
- ✅ Próximos trenes
- ✅ Últimos reportes

### 4. **Permisos de Ubicación**
- ✅ Se piden en el onboarding (junto con notificaciones)
- ✅ Ubicación es opcional - no bloquea reportes
- ✅ Solo notificación si ya rechazó permanentemente (`deniedForever`)
- ✅ No se piden permisos en `home_screen`

### 5. **Pantalla de Resumen**
- ✅ `ReportSummaryScreen` creada
- ✅ Muestra reportes del día, puntos, nivel
- ✅ Preparada para integrarse cuando se vuelve a la app

### 6. **Cloud Functions Actualizadas**
- ✅ `onReportCreated`: Usa campos planos
- ✅ `scheduleETAValidation`: Usa `report.etaBucket` directamente
- ✅ `processValidationResponse`: Usa campos planos
- ✅ `updateStationStatus`: Usa `report.stationOperational` y `report.stationCrowd`

---

## 🔄 Estructura de Firestore (Simplificada)

```javascript
reports/{reportId}: {
  scope: 'station' | 'train',
  stationId: string,
  userId: string,
  trainLine: 'L1' | 'L2' | null,
  direction: 'A' | 'B' | null,
  
  // Station core
  stationOperational: 'yes' | 'partial' | 'no' | null,
  stationCrowd: 1..5 | null,
  stationIssues: ['recharge', 'atm', ...] | [],
  
  // Train core
  trainCrowd: 1..5 | null,
  trainStatus: 'normal' | 'slow' | 'stopped' | null,
  
  // ETA
  etaBucket: '1-2' | '3-5' | '6-8' | '9+' | 'unknown' | null,
  etaExpectedAt: timestamp | null,
  
  // Validación
  needsValidation: boolean,
  validationStatus: 'pending' | 'validated' | 'expired',
  validationPoints: number,
  
  // Metadata
  createdAt: timestamp,
  status: 'active' | 'resolved' | 'rejected',
  confirmations: number,
  confidence: 0..1,
  basePoints: number,
  bonusPoints: number,
  totalPoints: number,
  
  // Ubicación (opcional)
  userLocation: GeoPoint | null,
  accuracy: number | null,
}

reports/{reportId}/eta_validations/{userId}: {
  userId: string,
  result: 'arrived' | 'not_arrived' | 'cant_confirm',
  answeredAt: timestamp,
  deltaSeconds: number | null,
  pointsAwarded: number,
}
```

---

## 📱 Flujos de Usuario

### **Al tocar estación:**
1. Se abre `StationBottomSheet`
2. Muestra estado actual + próximos trenes
3. Dos botones grandes: "REPORTAR ESTACIÓN" y "REPORTAR TREN"

### **Reportar Estación:**
1. Pantalla con 2 preguntas obligatorias
2. Botón "Agregar detalles (opcional)"
3. Si toca, muestra checklist de problemas
4. Botón "CONFIRMAR" envía reporte
5. Pantalla de éxito

### **Reportar Tren:**
1. Una pantalla con todo:
   - Ocupación (obligatorio)
   - Estado (opcional)
   - ETA bucket (opcional)
2. Botón "ENVIAR REPORTE"
3. Si tiene ETA, muestra mensaje: "Te preguntaremos si llegó"
4. Vuelve al mapa

### **Validación ETA:**
1. Notificación: "¿Ya llegó el tren?"
2. Abre `ETAValidationScreen`
3. Countdown visible
4. 3 opciones: "Sí llegó", "Aún no", "Me fui"
5. Si "Sí llegó", pide hora exacta
6. Pantalla de éxito con puntos

---

## 🎯 Puntos del Sistema

- **Reporte estación básico**: +15 puntos
- **Cada problema reportado**: +5 puntos
- **Reporte tren básico**: +20 puntos
- **Si estima ETA**: +10 puntos
- **Validación ETA (llegó)**: +30 puntos base
- **Validación ETA (preciso ±1 min)**: +40 puntos total
- **Validación ETA (preciso ±2 min)**: +35 puntos total

---

## ⚠️ Pendiente de Integración

1. **Conectar `StationBottomSheet` al mapa** - Reemplazar bottom sheet actual
2. **Integrar `ReportSummaryScreen`** - Mostrar cuando se vuelve a la app después de confirmar
3. **Actualizar Cloud Functions** - Desplegar funciones actualizadas
4. **Probar flujos completos** - Verificar que todo funciona end-to-end

---

**Última actualización:** 2025-12-14
