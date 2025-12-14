# 🔑 IDs de Firebase - MetroPTY

## 📋 Información del Proyecto

### 🔵 Project ID (ID del Proyecto)
```
metropty-aa303
```
**Este es el ID principal del proyecto de Firebase.**

### 📊 Project Number (Número del Proyecto)
```
443011769374
```

### 💾 Storage Bucket (Bucket de Almacenamiento)
```
metropty-aa303.firebasestorage.app
```

### 📱 Android App ID
```
1:443011769374:android:fdd1f064d5429d4c93ba0f
```

### 📦 Package Name
```
com.example.metropty
```

---

## 🗄️ ID de la Base de Datos Firestore

### Base de Datos por Defecto
Por defecto, Firebase usa:
```
(default)
```

**Esto significa que tu base de datos se llama `(default)`**.

### URL de la Base de Datos
```
https://metropty-aa303.firebaseio.com
```
o
```
https://metropty-aa303-default-rtdb.firebaseio.com
```

### Firestore Database URL
```
https://console.firebase.google.com/project/metropty-aa303/firestore
```

---

## 📍 Dónde Ver Esta Información

### 1. En Firebase Console
1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto: **metropty-aa303**
3. Ve a **Project Settings** (Configuración del proyecto)
   - El **Project ID** aparece en la parte superior
   - El **Project Number** aparece debajo

### 2. En Firestore
1. Ve a **Firestore Database** en Firebase Console
2. El **Project ID** está en la URL: `.../project/metropty-aa303/firestore`
3. Si has creado múltiples bases de datos, verás sus nombres en la lista

### 3. En el Archivo google-services.json
- **Ubicación**: `android/app/google-services.json`
- **Campo**: `project_info.project_id` = `metropty-aa303`
- **Campo**: `project_info.project_number` = `443011769374`

---

## 🎯 ¿Qué ID Necesitas?

### Para Configurar Firestore:
Si Firebase te pregunta por el **Database ID**, usa:
```
(default)
```
o simplemente deja el campo vacío para usar la base de datos por defecto.

### Para Referencias en Código:
En Flutter, normalmente **NO necesitas** especificar el ID explícitamente, ya que Firebase lo detecta automáticamente desde `google-services.json`.

### Si Necesitas Acceder a Múltiples Bases de Datos:
```dart
// Base de datos por defecto
final db = FirebaseFirestore.instance;

// Base de datos específica (si tienes múltiples)
final db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  database: '(default)', // o el nombre de tu base de datos
);
```

---

## 📝 Resumen Rápido

| Concepto | Valor |
|----------|-------|
| **Project ID** | `metropty-aa303` |
| **Project Number** | `443011769374` |
| **Database ID (Firestore)** | `(default)` |
| **Storage Bucket** | `metropty-aa303.firebasestorage.app` |
| **Package Name** | `com.example.metropty` |

---

## ⚠️ Nota Importante

**Por defecto, Firestore NO requiere que especifiques el ID de la base de datos** al crearla. Simplemente:
1. Ve a Firebase Console > Firestore Database
2. Haz clic en "Crear base de datos"
3. Selecciona "Modo de prueba" (temporal)
4. Selecciona la ubicación
5. Haz clic en "Habilitar"

Firebase creará automáticamente una base de datos llamada `(default)` y tu app la usará automáticamente.

---

**Última actualización**: Basado en `android/app/google-services.json`

