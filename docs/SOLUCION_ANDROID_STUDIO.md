# Solución para el problema de Android Studio

## Problema
Android Studio se queda trabado en "Installing build\app\outputs\flutter-apk\app-debug.apk..." pero `flutter run` desde terminal funciona.

## Soluciones

### 1. Reiniciar ADB (ya hecho)
```powershell
adb kill-server
adb start-server
```

### 2. Verificar configuración de Flutter en Android Studio

1. Abre Android Studio
2. Ve a **File > Settings** (o **Android Studio > Preferences** en Mac)
3. Busca **Languages & Frameworks > Flutter**
4. Verifica que la ruta del Flutter SDK sea: `D:\flutter`
5. Aplica los cambios

### 3. Invalidar caché de Android Studio

1. **File > Invalidate Caches / Restart...**
2. Selecciona **Invalidate and Restart**
3. Espera a que Android Studio reinicie

### 4. Verificar que no haya múltiples procesos de ADB

En PowerShell:
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*adb*"}
```

Si hay múltiples procesos, ciérralos:
```powershell
Stop-Process -Name adb -Force
adb start-server
```

### 5. Limpiar proyecto en Android Studio

1. **Build > Clean Project**
2. **Build > Rebuild Project**

### 6. Verificar configuración de ejecución

1. Ve a **Run > Edit Configurations...**
2. Verifica que:
   - **Dart entrypoint**: `lib/main.dart`
   - **Additional run args**: (debe estar vacío o con argumentos válidos)
   - **Working directory**: `D:\MAQ`

### 7. Usar terminal integrado de Android Studio

En lugar del botón de Run, usa el terminal integrado:
1. **View > Tool Windows > Terminal**
2. Ejecuta: `flutter run`

### 8. Desactivar Instant Run (si existe)

1. **File > Settings > Build, Execution, Deployment > Instant Run**
2. Desmarca **Enable Instant Run**

## Solución temporal recomendada

**Usa la terminal en lugar del botón de Android Studio:**

```powershell
cd D:\MAQ
flutter run
```

Esto funciona perfectamente y es más rápido que depender de Android Studio.

## Si nada funciona

1. Cierra Android Studio completamente
2. Reinicia adb: `adb kill-server && adb start-server`
3. Abre Android Studio de nuevo
4. Intenta ejecutar desde la terminal integrada de Android Studio

