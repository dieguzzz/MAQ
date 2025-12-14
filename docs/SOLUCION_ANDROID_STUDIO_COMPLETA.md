# 🔧 Solución Completa para Problemas de Android Studio

## ⚠️ ANTES DE DESINSTALAR - Prueba estas soluciones primero

### 🎯 Solución 1: Invalidar Cachés (MÁS COMÚN - Resuelve el 80% de problemas)

1. **Cierra Android Studio completamente**
2. **Abre Android Studio**
3. **File > Invalidate Caches / Restart...**
4. Selecciona **"Invalidate and Restart"**
5. Espera a que reinicie completamente
6. Prueba ejecutar la app de nuevo

**Tiempo:** ~2-3 minutos

---

### 🎯 Solución 2: Limpiar Proyecto y Reconstruir

1. En Android Studio: **Build > Clean Project**
2. Espera a que termine
3. **Build > Rebuild Project**
4. Espera a que termine
5. Prueba ejecutar de nuevo

**Tiempo:** ~3-5 minutos

---

### 🎯 Solución 3: Reiniciar ADB y Procesos

En PowerShell (fuera de Android Studio):

```powershell
# Cerrar todos los procesos de ADB
Stop-Process -Name adb -Force -ErrorAction SilentlyContinue

# Reiniciar ADB
$env:Path += ";C:\Users\fertr\AppData\Local\Android\sdk\platform-tools"
adb kill-server
adb start-server

# Verificar dispositivos
adb devices
```

Luego reinicia Android Studio.

**Tiempo:** ~1 minuto

---

### 🎯 Solución 4: Verificar y Reconfigurar Flutter SDK

1. **File > Settings** (Ctrl+Alt+S)
2. **Languages & Frameworks > Flutter**
3. Verifica que **Flutter SDK path** sea: `D:\flutter` (NO `D:\flutter\bin`)
4. Si está mal, corrígelo y haz clic en **Apply**
5. Ve a **Languages & Frameworks > Dart**
6. Verifica que **Dart SDK path** esté configurado automáticamente
7. Haz clic en **Apply** y **OK**
8. Reinicia Android Studio

**Tiempo:** ~2 minutos

---

### 🎯 Solución 5: Limpiar Cachés de Gradle

En PowerShell:

```powershell
cd D:\MAQ\android
.\gradlew.bat clean
.\gradlew.bat --stop
```

Luego elimina manualmente:
- `D:\MAQ\android\.gradle` (si existe)
- `D:\MAQ\android\app\.gradle` (si existe)

**Tiempo:** ~2-3 minutos

---

### 🎯 Solución 6: Usar Terminal Integrado (Solución Temporal)

En lugar del botón Run de Android Studio:

1. **View > Tool Windows > Terminal**
2. En la terminal integrada, ejecuta:
   ```powershell
   flutter run
   ```

Esto funciona perfectamente y evita problemas del IDE.

**Tiempo:** Inmediato

---

## 🔄 Si NADA de lo anterior funciona

### Opción A: Reinstalar Plugins de Flutter/Dart

1. **File > Settings > Plugins**
2. Busca **"Flutter"** y haz clic en **Uninstall**
3. Busca **"Dart"** y haz clic en **Uninstall**
4. Reinicia Android Studio
5. Vuelve a **Plugins** y reinstala **"Flutter"** (incluye Dart automáticamente)
6. Reinicia Android Studio

**Tiempo:** ~5 minutos

---

### Opción B: Resetear Configuración de Android Studio (Sin perder plugins)

1. **Cierra Android Studio completamente**
2. Ve a: `C:\Users\fertr\AppData\Roaming\Google\AndroidStudio*`
3. **Renombra** la carpeta (ej: `AndroidStudio2023.1` → `AndroidStudio2023.1.backup`)
4. Abre Android Studio (se configurará desde cero)
5. Reconfigura Flutter SDK (Solución 4)
6. Abre tu proyecto

**Tiempo:** ~10 minutos

---

### Opción C: DESINSTALAR Y REINSTALAR (ÚLTIMO RECURSO)

**⚠️ Solo si NADA más funciona**

#### Paso 1: Desinstalar

1. **Cierra Android Studio**
2. **Panel de Control > Programas > Desinstalar Android Studio**
3. O desde **Configuración > Aplicaciones > Android Studio > Desinstalar**

#### Paso 2: Eliminar Carpetas Residuales

Elimina estas carpetas (si existen):

```powershell
# Cachés de Android Studio
C:\Users\fertr\AppData\Roaming\Google\AndroidStudio*
C:\Users\fertr\AppData\Local\Google\AndroidStudio*

# Configuración de proyectos (opcional, solo si quieres empezar desde cero)
C:\Users\fertr\.AndroidStudio*
```

**⚠️ NO elimines:**
- `D:\flutter` (Flutter SDK)
- `D:\MAQ` (tu proyecto)
- `C:\Users\fertr\AppData\Local\Android\sdk` (Android SDK)

#### Paso 3: Reinstalar

1. Descarga Android Studio desde: https://developer.android.com/studio
2. Instala normalmente
3. Al abrir, configura Flutter SDK (Solución 4)
4. Abre tu proyecto

**Tiempo:** ~30-45 minutos

---

## ✅ Recomendación Final

**Orden de intentos:**

1. ✅ Solución 1 (Invalidar Cachés) - **Empieza aquí**
2. ✅ Solución 3 (Reiniciar ADB)
3. ✅ Solución 4 (Reconfigurar Flutter SDK)
4. ✅ Solución 6 (Usar Terminal) - **Mientras tanto, sigue trabajando**
5. ✅ Solución 2 (Limpiar Proyecto)
6. ✅ Solución 5 (Limpiar Gradle)
7. ⚠️ Opción A (Reinstalar Plugins)
8. ⚠️ Opción B (Resetear Configuración)
9. 🔴 Opción C (Desinstalar Todo) - **Solo si nada más funciona**

---

## 💡 Consejo Pro

**La mayoría de problemas se resuelven con:**
- Invalidar cachés (Solución 1)
- Usar terminal en lugar del botón Run (Solución 6)

**No necesitas desinstalar a menos que:**
- Android Studio no inicia
- Hay corrupción de archivos
- Nada de lo anterior funciona después de intentar TODO

---

## 📞 Si necesitas ayuda

Después de intentar las soluciones, comparte:
1. ¿Qué solución intentaste?
2. ¿Qué error específico ves?
3. ¿La terminal funciona pero el botón Run no?

