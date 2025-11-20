# 🚀 Comandos Rápidos para Firebase

## ⚠️ IMPORTANTE
Firebase Console es una **interfaz web**, no se puede crear completamente desde la terminal. Sin embargo, puedes usar Firebase CLI para algunas tareas.

## 📋 Opción Recomendada: Firebase Console Web

**URL**: https://console.firebase.google.com/

Sigue la guía en `FIREBASE_SETUP.md` para pasos detallados.

---

## 🔧 Firebase CLI (Opcional - Para usuarios avanzados)

### Instalación

```bash
# Windows (con npm - requiere Node.js)
npm install -g firebase-tools

# Windows (con Chocolatey)
choco install firebase-cli

# Verificar instalación
firebase --version
```

### Comandos Útiles

```bash
# 1. Iniciar sesión
firebase login

# 2. Listar proyectos
firebase projects:list

# 3. Inicializar Firebase en el proyecto
firebase init

# 4. Desplegar solo reglas de Firestore
firebase deploy --only firestore:rules

# 5. Ver estado del proyecto
firebase projects:list

# 6. Ver información del proyecto actual
firebase use
```

### Inicialización Interactiva

```bash
firebase init
```

Durante la inicialización, selecciona:
- ✅ **Firestore**: Configurar reglas
- ❌ **Functions**: No (por ahora)
- ❌ **Hosting**: No (opcional)
- ❌ **Storage**: No (opcional)

---

## 📱 Comandos para Verificar Archivos

### Windows PowerShell

```powershell
# Verificar que google-services.json existe
Test-Path android/app/google-services.json

# Verificar que GoogleService-Info.plist existe
Test-Path ios/Runner/GoogleService-Info.plist

# Ver contenido del archivo (primeras líneas)
Get-Content android/app/google-services.json -Head 5
```

### Linux/Mac

```bash
# Verificar archivos
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist

# Ver contenido (primeras líneas)
head -5 android/app/google-services.json
```

---

## 🎯 Flujo Recomendado (Sin CLI)

1. **Ve a**: https://console.firebase.google.com/
2. **Crea el proyecto** manualmente (más fácil)
3. **Descarga los archivos** de configuración
4. **Colócalos** en las carpetas correspondientes
5. **Habilita los servicios** desde la consola web

---

## 📝 Nota Final

**No hay un comando único** para crear todo el proyecto de Firebase. La forma más fácil es usar la interfaz web. Los comandos de CLI son útiles para tareas específicas como desplegar reglas o funciones, pero la configuración inicial se hace mejor desde la consola web.

**Sigue la guía en `FIREBASE_SETUP.md` para instrucciones paso a paso con capturas de pantalla conceptuales.**

