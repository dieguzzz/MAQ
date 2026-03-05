# 🏢 Testing de Reportes de Estación

Panel de testing en el dashboard para generar reportes de estado de estación en masa, similar al testing de tiempos de trenes.

## 📋 Funcionalidades

### 1. **Configuración de Reportes**

#### **Estación**
- Selecciona cualquier estación del sistema
- Carga automáticamente al abrir el tab

#### **Estado Operacional**
- 🟢 **Operando Normal** (`yes`)
- 🟡 **Parcialmente Operando** (`partial`)
- 🔴 **No Operando** (`no`)

#### **Nivel de Aglomeración (1-5)**
- ⭐ 1 - Vacía
- ⭐⭐ 2 - Baja
- ⭐⭐⭐ 3 - Media
- ⭐⭐⭐⭐ 4 - Alta
- ⭐⭐⭐⭐⭐ 5 - Muy Alta

#### **Problemas Específicos** (Opcionales)
Cada problema seleccionado suma +5 puntos:
- ❄️ **ac**: Aire Acondicionado
- 🎢 **escalator**: Escaleras
- 🛗 **elevator**: Ascensor
- 🏧 **atm**: ATM
- 💳 **recharge**: Recarga

### 2. **Generación Múltiple**

- **Número de reportes**: 1-20 reportes
- **Intervalo**: Segundos entre cada reporte
- **Variación automática**: 
  - Varía aglomeración ±1
  - Ocasionalmente cambia estado operacional
  - Hace las pruebas más realistas

### 3. **Sistema de Puntos**

```
Puntos Base:     15 puntos
Problemas:       +5 puntos por cada problema
Total:           15 + (problemas × 5)
```

**Ejemplos:**
- Reporte sin problemas: 15 puntos
- Reporte con AC y ATM: 25 puntos (15 + 5 + 5)
- Reporte con todos los problemas: 40 puntos (15 + 25)

## 🚀 Cómo Usar

### **Paso 1: Acceder al Panel**
1. Abre el dashboard
2. Click en el tab **"🏢 Testing Reportes de Estación"**
3. Las estaciones se cargan automáticamente

### **Paso 2: Configurar Reporte**
1. **Selecciona estación** (ej: Albrook)
2. **Selecciona estado operacional** (ej: Operando Normal)
3. **Selecciona aglomeración** (ej: 3 - Media)
4. **Marca problemas** (opcionales)
5. **Configura generación múltiple:**
   - Número de reportes: 5
   - Intervalo: 30 segundos
   - ✅ Agregar variación

### **Paso 3: Vista Previa**
Click en **"👁️ Vista Previa"** para ver:
- Lista de reportes que se crearán
- Tiempos de cada reporte
- Estados y aglomeraciones
- Problemas incluidos
- Puntos por reporte

### **Paso 4: Generar Reportes**
Click en **"🚀 Generar Reportes"**
- Confirma la acción
- Espera a que se generen (200ms entre cada uno)
- Ve el resumen de resultados

### **Paso 5: Verificar en la App**
1. Abre la app Flutter
2. Ve a la estación que reportaste
3. Verás en el panel de la estación:
   - **Estado actual** con los datos reportados
   - **Aglomeración** con estrellas
   - **Problemas activos** listados

## 📊 Vista de Resultados

Después de generar, verás:

### **Resumen:**
- 📊 Total de reportes generados
- 🏆 Puntos totales otorgados
- 👥 Aglomeración promedio
- ⚠️ Reportes con problemas

### **Lista detallada:**
- Hora de cada reporte
- Estación
- Estado operacional
- Nivel de aglomeración
- Problemas reportados
- Puntos otorgados

## 🧹 Limpiar Reportes

Click en **"🗑️ Limpiar Reportes"** para:
- Eliminar todos los reportes generados
- Limpiar la base de datos
- Resetear contadores

## 📱 Cómo se Muestra en la App

Los reportes generados aparecen en el **panel de estación**:

### **Sección "Estado actual":**

**Aglomeración:**
```
⭐⭐⭐⭐
Alta
```

**Problemas activos:**
```
AC • Escaleras • ATM
```

Si hay múltiples reportes, la app muestra:
- El reporte más reciente
- Promedio de aglomeración
- Todos los problemas únicos reportados

## 🎯 Casos de Uso

### **Testing Básico:**
```
Estación: Albrook
Estado: Operando Normal
Aglomeración: 3
Problemas: Ninguno
Cantidad: 1
```
→ Crea 1 reporte simple (15 puntos)

### **Testing de Problemas:**
```
Estación: San Miguelito
Estado: Parcialmente Operando
Aglomeración: 4
Problemas: AC + Escaleras + ATM
Cantidad: 1
```
→ Crea 1 reporte con problemas (30 puntos)

### **Testing de Variación:**
```
Estación: Fernández de Córdoba
Estado: Operando Normal
Aglomeración: 2
Problemas: Ninguno
Cantidad: 10
Intervalo: 20 seg
✅ Variación activada
```
→ Crea 10 reportes con variaciones realistas

### **Testing de Sobrecarga:**
```
Estación: Los Andes
Estado: Operando Normal
Aglomeración: 5
Problemas: TODOS
Cantidad: 5
Intervalo: 10 seg
```
→ Simula estación con todos los problemas

## 🔍 Estructura de Datos

Los reportes se crean con el modelo `SimplifiedReportModel`:

```javascript
{
  scope: 'station',
  stationId: 'albrook',
  userId: 'testuser123',
  
  // Campos de estación
  stationOperational: 'yes', // 'yes' | 'partial' | 'no'
  stationCrowd: 3,           // 1-5
  stationIssues: ['ac', 'atm'], // array de strings
  
  // Campos comunes
  createdAt: Timestamp,
  basePoints: 15,
  bonusPoints: 10,
  totalPoints: 25,
  status: 'active',
  confirmations: 0,
  confidence: 0.8,
  confidenceReasons: ['testing']
}
```

## ⚠️ Consideraciones

1. **Límite de reportes:** Máximo 20 por generación
2. **Rate limiting:** 200ms de delay entre reportes
3. **Autenticación requerida:** El dashboard autentica automáticamente
4. **Limpieza:** Recuerda limpiar reportes de prueba
5. **Firestore:** Los reportes se guardan en la colección `reports`

## 🐛 Troubleshooting

**No aparecen estaciones:**
- Recarga la página (Ctrl+Shift+R)
- Verifica la consola del navegador
- Asegúrate de estar autenticado

**Error al generar:**
- Verifica reglas de Firestore
- Revisa permisos de autenticación
- Mira logs en la consola

**No se ven en la app:**
- Espera unos segundos (streams en tiempo real)
- Refresca la app
- Verifica que estés viendo la misma estación

## 📚 Archivos Relacionados

- `dashboard/js/station_reports_testing.js` - Lógica del testing
- `dashboard/index.html` - UI del panel
- `dashboard/css/dashboard.css` - Estilos
- `dashboard/js/ui.js` - Carga automática del tab
- `lib/models/simplified_report_model.dart` - Modelo Flutter
- `lib/services/simplified_report_service.dart` - Servicio Flutter

---

**Fecha:** 2025-01-07
**Versión:** 1.0
**Estado:** ✅ Funcional

