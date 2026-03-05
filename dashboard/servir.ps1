# MetroPTY Dashboard - Servidor Local (PowerShell)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MetroPTY Dashboard - Servidor Local" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Iniciando servidor en http://localhost:3000" -ForegroundColor Green
Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Yellow
Write-Host ""

# Verificar si node_modules existe
if (-not (Test-Path "node_modules")) {
    Write-Host "Instalando dependencias..." -ForegroundColor Yellow
    npm install
}

# Abrir navegador después de un pequeño delay
Start-Job -ScriptBlock { Start-Sleep -Seconds 2; Start-Process "http://localhost:3000" } | Out-Null

# Iniciar servidor Vite
Write-Host "Usando Vite dev server..." -ForegroundColor Green
npm run dev
