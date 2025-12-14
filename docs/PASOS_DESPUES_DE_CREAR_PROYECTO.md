# 🚀 Pasos Después de Crear el Proyecto en Firebase

## ✅ Ya tienes el proyecto creado

Ahora necesitas hacer estos pasos:

---

## 📱 PASO 1: Agregar App Android

### 1.1 En Firebase Console

1. En la página principal de tu proyecto, busca el ícono de **Android** 📱
2. Haz clic en el ícono de Android
3. Verás un formulario con estos campos:

### 1.2 Llenar el Formulario

**Package name (requerido):**
```
com.example.metropty
```
⚠️ **IMPORTANTE**: Debe ser EXACTAMENTE esto, sin espacios, sin mayúsculas

**App nickname (opcional):**
```
MetroPTY Android
```

**Debug signing certificate SHA-1 (opcional):**
- Déjalo vacío por ahora
- No es necesario para desarrollo inicial

### 1.3 Registrar

1. Haz clic en **"Registrar app"** o **"Register app"**
2. Espera unos segundos

---

## 📥 PASO 2: Descargar google-services.json

### 2.1 Después de Registrar

Verás una página con instrucciones. En la parte superior verás:

**"Descargar google-services.json"** o **"Download google-services.json"**

### 2.2 Descargar

1. Haz clic en el botón para descargar
2. El archivo se descargará en tu carpeta de Descargas
3. **NO cierres esta página todavía** (por si necesitas volver)

---

## 📂 PASO 3: Colocar el Archivo

### 3.1 Ubicación Correcta

El archivo debe ir en:
```
C:\Users\Diegu\MAQ\android\app\google-services.json
```

### 3.2 Método 1: Arrastrar y Soltar (Más Fácil)

1. Abre el **Explorador de Archivos**
2. Ve a tu carpeta de **Descargas**
3. Busca el archivo `google-services.json`
4. Abre otra ventana del Explorador
5. Navega a: `C:\Users\Diegu\MAQ\android\app\`
6. **Arrastra** el archivo desde Descargas a `android\app\`

### 3.3 Método 2: Copiar y Pegar

1. En Descargas, haz clic derecho en `google-services.json`
2. Selecciona **"Copiar"**
3. Navega a `C:\Users\Diegu\MAQ\android\app\`
4. Haz clic derecho → **"Pegar"**

### 3.4 Método 3: PowerShell

```powershell
# Reemplaza RUTA_DESCARGAS con tu ruta de Descargas
Copy-Item "$env:USERPROFILE\Downloads\google-services.json" -Destination "android\app\google-services.json"
```

---

## ✅ PASO 4: Verificar

Ejecuta este comando:

```powershell
.\verificar_firebase.ps1
```

Debería mostrar:
```
Android (google-services.json): ENCONTRADO
```

---

## ⚙️ PASO 5: Habilitar Servicios

### 5.1 Authentication

1. En el menú lateral izquierdo, haz clic en **"Authentication"**
2. Si es la primera vez, haz clic en **"Comenzar"** o **"Get started"**
3. Ve a la pestaña **"Sign-in method"** o **"Métodos de inicio de sesión"**
4. Haz clic en **"Email/Password"**
5. **Activa** el primer toggle (Email/Password)
6. Haz clic en **"Guardar"**

✅ **Authentication habilitado**

### 5.2 Firestore Database

1. En el menú lateral, haz clic en **"Firestore Database"**
2. Haz clic en **"Crear base de datos"** o **"Create database"**
3. Selecciona **"Comenzar en modo de prueba"** o **"Start in test mode"**
4. Selecciona la **ubicación**:
   - Para Panamá: `southamerica-east1` o `us-central1`
5. Haz clic en **"Habilitar"**
6. Espera 30-60 segundos

✅ **Firestore creado**

### 5.3 Configurar Reglas de Firestore

1. En Firestore Database, ve a la pestaña **"Reglas"** o **"Rules"**
2. Abre el archivo `firestore.rules` de tu proyecto (está en la raíz)
3. **Copia TODO el contenido** del archivo
4. En Firebase Console, **pega** el contenido en el editor de reglas
5. Haz clic en **"Publicar"** o **"Publish"**

✅ **Reglas configuradas**

---

## 🧪 PASO 6: Probar

### 6.1 Limpiar Proyecto

```powershell
flutter clean
flutter pub get
```

### 6.2 Verificar

```powershell
.\verificar_firebase.ps1
```

### 6.3 Probar Compilación

```powershell
flutter build apk --debug
```

Si compila sin errores de Firebase, ¡está todo correcto! 🎉

---

## 📋 Checklist

- [ ] Proyecto creado en Firebase ✅
- [ ] App Android agregada
- [ ] Package name: `com.example.metropty`
- [ ] `google-services.json` descargado
- [ ] `google-services.json` colocado en `android/app/`
- [ ] Authentication habilitado (Email/Password)
- [ ] Firestore creado (modo prueba)
- [ ] Reglas de Firestore configuradas
- [ ] Verificación exitosa

---

## 🆘 Si Tienes Problemas

### El archivo no se descarga
- Verifica que hayas registrado la app correctamente
- Intenta con otro navegador

### No encuentro dónde colocar el archivo
- La ruta exacta es: `C:\Users\Diegu\MAQ\android\app\google-services.json`
- Asegúrate de que el archivo se llame exactamente `google-services.json`

### Error al compilar
- Ejecuta `flutter clean`
- Verifica que el package name coincida exactamente

---

**¿En qué paso estás ahora?** Avísame y te ayudo con el siguiente. 🚀

