# Script de diagnóstico para el problema del VM Service
# Ejecuta este script en PowerShell

Write-Host "=== DIAGNÓSTICO VM SERVICE ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar conexión del dispositivo
Write-Host "1. Verificando conexión del dispositivo..." -ForegroundColor Yellow
$env:Path += ";C:\Users\fertr\AppData\Local\Android\sdk\platform-tools"
$devices = adb devices
Write-Host $devices
Write-Host ""

# 2. Limpiar logcat anterior
Write-Host "2. Limpiando logcat..." -ForegroundColor Yellow
adb logcat -c
Write-Host "✅ Logcat limpiado"
Write-Host ""

# 3. Iniciar logcat en segundo plano
Write-Host "3. Iniciando logcat (presiona Ctrl+C para detener)..." -ForegroundColor Yellow
Write-Host "   Ejecuta esto en OTRA terminal:" -ForegroundColor Green
Write-Host "   adb logcat -s flutter ActivityManager AndroidRuntime" -ForegroundColor White
Write-Host ""

# 4. Instrucciones
Write-Host "4. INSTRUCCIONES:" -ForegroundColor Cyan
Write-Host "   a) Abre OTRA terminal de PowerShell" -ForegroundColor White
Write-Host "   b) Ejecuta: adb logcat -s flutter ActivityManager AndroidRuntime" -ForegroundColor White
Write-Host "   c) En ESTA terminal, ejecuta: flutter run" -ForegroundColor White
Write-Host "   d) Cuando veas 'Waiting for VM Service port...', revisa:" -ForegroundColor White
Write-Host "      - La terminal de logcat para ver errores" -ForegroundColor White
Write-Host "      - El teléfono para ver si la app se abre o se cierra" -ForegroundColor White
Write-Host ""

# 5. Probar en modo release
Write-Host "5. Para probar sin debugger:" -ForegroundColor Cyan
Write-Host "   flutter run --release" -ForegroundColor White
Write-Host ""

Write-Host "Presiona Enter para continuar o Ctrl+C para salir..." -ForegroundColor Yellow
Read-Host

