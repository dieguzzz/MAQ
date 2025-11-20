# 🎯 ¿Qué Template/Opción Seleccionar en Firebase?

## 📋 Cuando CREAS el Proyecto

### Opción 1: Proyecto Vacío (Recomendado)
- ✅ **Selecciona**: "Crear proyecto" o "Add project" (sin template)
- ✅ **NO selecciones**: Templates predefinidos como "E-commerce", "Blog", etc.
- ✅ **Razón**: Queremos empezar desde cero

### Google Analytics (Opcional)
- ✅ **Puedes activarlo** si quieres analíticas
- ✅ **O desactivarlo** si no lo necesitas
- ⚠️ **No afecta** la funcionalidad de la app

---

## 📱 Cuando AGREGAS App Android

### NO hay templates aquí
- Solo necesitas:
  1. **Package name**: `com.example.metropty`
  2. **App nickname** (opcional): `MetroPTY Android`
  3. **Haz clic en "Registrar app"**

### Después de registrar:
- Te mostrará instrucciones
- **NO necesitas** seguir las instrucciones de código
- Solo necesitas **descargar el archivo** `google-services.json`

---

## 🍎 Cuando AGREGAS App iOS

### Similar a Android
- **Bundle ID**: `com.example.metropty`
- **App nickname** (opcional): `MetroPTY iOS`
- **Haz clic en "Registrar app"**
- Solo descarga `GoogleService-Info.plist`

---

## ⚙️ Cuando HABILITAS Servicios

### Authentication
- **NO selecciones template**
- Solo ve a **Sign-in method**
- Habilita **Email/Password**
- **NO necesitas** configurar otros métodos ahora

### Firestore
- **Selecciona**: "Comenzar en modo de prueba" o "Start in test mode"
- **NO selecciones**: "Producción" (por ahora)
- **Ubicación**: Selecciona la más cercana (ej: `us-central1` o `southamerica-east1`)

---

## 🎯 Resumen: Qué NO Seleccionar

❌ **NO selecciones templates** como:
- E-commerce template
- Blog template
- Chat template
- Etc.

✅ **Solo necesitas**:
- Proyecto vacío
- Agregar apps (Android/iOS)
- Habilitar servicios básicos

---

## 📝 Flujo Correcto

```
1. Crear proyecto → Proyecto vacío (sin template)
2. Agregar app Android → Solo package name
3. Descargar google-services.json
4. Habilitar Authentication → Email/Password
5. Crear Firestore → Modo prueba
6. Configurar reglas → Copiar desde firestore.rules
```

---

## ❓ Si Ves Opciones de Templates

**Pregunta**: ¿En qué paso estás viendo templates?

### Si es al crear proyecto:
→ **Selecciona "Proyecto vacío" o "Blank project"**

### Si es al agregar app:
→ **NO deberías ver templates**, solo campos de configuración

### Si es en algún servicio:
→ **NO selecciones templates**, solo habilita el servicio básico

---

**¿En qué paso específico estás?** Puedo ayudarte con más detalle si me dices qué opciones ves. 🤔

