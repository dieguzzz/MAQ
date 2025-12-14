# 🚀 Siguiente Paso: Habilitar Servicios en Firebase

## ✅ Lo que ya tienes configurado:

- ✅ API Key de Android configurada
- ✅ API Key de iOS configurada  
- ✅ `google-services.json` en su lugar
- ✅ `GoogleService-Info.plist` en su lugar

---

## 🔥 Ahora necesitas habilitar servicios en Firebase Console

### 1. 🔐 Habilitar Authentication (Email/Password)

**Pasos:**
1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto **MetroPTY**
3. En el menú lateral izquierdo, haz clic en **"Authentication"** o **"Autenticación"**
4. Si es la primera vez, haz clic en **"Comenzar"** o **"Get started"**
5. Ve a la pestaña **"Sign-in method"** o **"Métodos de inicio de sesión"**
6. Haz clic en **"Email/Password"**
7. **Activa** el primer toggle (Email/Password)
8. Haz clic en **"Guardar"** o **"Save"**

✅ **Authentication habilitado**

---

### 2. 🗄️ Crear Base de Datos Firestore

**Pasos:**
1. En Firebase Console, en el menú lateral, haz clic en **"Firestore Database"** o **"Base de datos Firestore"**
2. Haz clic en **"Crear base de datos"** o **"Create database"**
3. Selecciona **"Comenzar en modo de prueba"** o **"Start in test mode"**
   - ⚠️ Esto permite lectura/escritura sin autenticación (ideal para desarrollo)
4. Selecciona la **ubicación**:
   - **Recomendado para Panamá:** `southamerica-east1` (Brasil - más cercano)
   - O `us-central1` (EE.UU. - también funciona bien)
5. Haz clic en **"Habilitar"** o **"Enable"**
6. Espera 30-60 segundos a que se cree la base de datos

✅ **Firestore creado**

---

### 3. 📋 Configurar Reglas de Firestore

**Pasos:**
1. En Firestore Database, ve a la pestaña **"Reglas"** o **"Rules"**
2. **Abre el archivo** `firestore.rules` de tu proyecto (está en la raíz: `D:\MAQ\firestore.rules`)
3. **Copia TODO el contenido** del archivo
4. En Firebase Console, en el editor de reglas, **pega** el contenido
5. Haz clic en **"Publicar"** o **"Publish"**

✅ **Reglas configuradas**

---

## 🧪 Después de configurar: Probar que todo funciona

### Paso 1: Limpiar y Reconstruir

```powershell
# Desde la carpeta del proyecto (D:\MAQ)
flutter clean
flutter pub get
```

### Paso 2: Verificar Código

```powershell
flutter analyze
```

Debería mostrar solo warnings menores, sin errores críticos.

### Paso 3: Probar Compilación

```powershell
# Probar compilación de Android
flutter build apk --debug
```

Si compila sin errores relacionados con Firebase, ¡todo está correcto! 🎉

---

## 🎯 Resumen de lo que falta:

- [ ] ⏳ Habilitar Authentication (Email/Password) en Firebase Console
- [ ] ⏳ Crear Firestore Database en Firebase Console
- [ ] ⏳ Configurar reglas de Firestore (copiar desde `firestore.rules`)
- [ ] ⏳ Probar compilación

---

## 💡 Tip

Una vez que hayas habilitado Authentication y Firestore, la aplicación estará **completamente funcional** y lista para ejecutarse con:

```powershell
flutter run
```

---

**¿Ya habilitaste Authentication y Firestore?** Cuando termines, avísame y probamos que todo funcione correctamente. 🚀

