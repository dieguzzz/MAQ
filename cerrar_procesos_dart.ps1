# Script para cerrar procesos de Dart y Java que bloquean el upgrade de Flutter
# Ejecuta este script ANTES de hacer flutter upgrade

Write-Host "=== CERRANDO PROCESOS DE DART Y JAVA ===" -ForegroundColor Cyan
Write-Host ""

# Cerrar procesos de Dart
$dartProcesses = Get-Process | Where-Object {$_.ProcessName -like "*dart*"}
if ($dartProcesses) {
    Write-Host "Encontrados $($dartProcesses.Count) procesos de Dart" -ForegroundColor Yellow
    foreach ($proc in $dartProcesses) {
        Write-Host "  - Cerrando: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Gray
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "    ⚠️ No se pudo cerrar: $($proc.ProcessName)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No hay procesos de Dart corriendo" -ForegroundColor Green
}

Write-Host ""

# Cerrar procesos de Java (solo los relacionados con Flutter/Android)
# NOTA: Esto cerrará TODOS los procesos Java, incluyendo Android Studio
# Si tienes Android Studio abierto, ciérralo manualmente primero
$javaProcesses = Get-Process | Where-Object {$_.ProcessName -like "*java*"}
if ($javaProcesses) {
    Write-Host "Encontrados $($javaProcesses.Count) procesos de Java" -ForegroundColor Yellow
    Write-Host "⚠️ ADVERTENCIA: Esto cerrará Android Studio si está abierto" -ForegroundColor Red
    $response = Read-Host "¿Deseas cerrar los procesos Java? (S/N)"
    if ($response -eq "S" -or $response -eq "s") {
        foreach ($proc in $javaProcesses) {
            Write-Host "  - Cerrando: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Gray
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host "    ⚠️ No se pudo cerrar: $($proc.ProcessName)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Procesos Java no cerrados" -ForegroundColor Yellow
    }
} else {
    Write-Host "No hay procesos de Java corriendo" -ForegroundColor Green
}

Write-Host ""
Write-Host "Esperando 2 segundos..." -ForegroundColor Gray
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "✅ Procesos cerrados. Ahora puedes ejecutar: flutter upgrade" -ForegroundColor Green
Write-Host ""

