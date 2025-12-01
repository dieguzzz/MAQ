# 🔄 Script para Actualizar Estaciones en Firestore

## 📋 Descripción

Este script actualiza todas las estaciones en Firestore con las coordenadas exactas y elimina documentos duplicados.

## 🚀 Cómo Ejecutar

### Opción 1: Ejecutar desde la App (Automático)

La app automáticamente ejecutará la actualización cuando se inicie. Solo necesitas:

1. **Asegúrate de que las reglas de Firestore permitan escritura temporalmente:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true; // Temporalmente para actualizar
       }
     }
   }
   ```

2. **Ejecuta la app:**
   ```powershell
   flutter run
   ```

3. **La app automáticamente:**
   - Actualizará todas las estaciones con coordenadas exactas
   - Eliminará `l2_san_miguelito_l1` si existe
   - Creará estaciones que falten
   - Verificará que solo haya 2 San Miguelito (uno por línea)

### Opción 2: Ejecutar Manualmente desde Código

Si quieres ejecutarlo manualmente, puedes agregar un botón en el panel de administración o ejecutarlo desde la consola de Flutter:

```dart
final stationUpdateService = StationUpdateService();
final results = await stationUpdateService.updateAllStations();
print('Resultados: $results');
```

## ✅ Lo que hace el script:

1. **Lee todas las estaciones existentes** en Firestore
2. **Elimina documentos duplicados:**
   - `l2_san_miguelito_l1`
3. **Actualiza todas las estaciones** con coordenadas exactas:
   - 15 estaciones de Línea 1
   - 18 estaciones de Línea 2 (16 principales + 2 de rama aeropuerto)
4. **Crea estaciones que falten**
5. **Verifica el resultado final** y muestra estadísticas

## 📊 Resultado Esperado:

- **Total de estaciones:** 33
  - Línea 1: 15 estaciones
  - Línea 2: 18 estaciones (16 principales + ITSE + Aeropuerto)
- **San Miguelito:** Solo 2 (uno en L1, uno en L2)
- **Coordenadas:** Todas actualizadas con valores exactos

## 🔍 Verificar en Firebase Console

Después de ejecutar:

1. Ve a: https://console.firebase.google.com/project/metropty-aa303/firestore/data
2. Abre la colección `stations`
3. Verifica que:
   - Hay 33 estaciones en total
   - Solo hay `l1_san_miguelito` y `l2_san_miguelito`
   - No existe `l2_san_miguelito_l1`
   - Las coordenadas están actualizadas

## ⚠️ Importante

Después de actualizar, **restaura las reglas de seguridad** en Firebase Console para proteger la base de datos.

