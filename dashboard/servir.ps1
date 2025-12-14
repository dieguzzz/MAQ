# MetroPTY Dashboard - Servidor Local (PowerShell)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MetroPTY Dashboard - Servidor Local" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Iniciando servidor en http://localhost:8000" -ForegroundColor Green
Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Yellow
Write-Host ""

# Intentar con Python (py)
if (Get-Command py -ErrorAction SilentlyContinue) {
    Write-Host "Usando Python (py)..." -ForegroundColor Green
    py -m http.server 8000
    exit
}

# Intentar con Python3
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    Write-Host "Usando Python3..." -ForegroundColor Green
    python3 -m http.server 8000
    exit
}

# Intentar con Python
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Usando Python..." -ForegroundColor Green
    python -m http.server 8000
    exit
}

# Intentar con Node.js (npx)
if (Get-Command npx -ErrorAction SilentlyContinue) {
    Write-Host "Usando Node.js (npx)..." -ForegroundColor Green
    npx http-server -p 8000
    exit
}

# Intentar con PHP
if (Get-Command php -ErrorAction SilentlyContinue) {
    Write-Host "Usando PHP..." -ForegroundColor Green
    php -S localhost:8000
    exit
}

Write-Host ""
Write-Host "ERROR: No se encontró ningún servidor disponible." -ForegroundColor Red
Write-Host ""
Write-Host "Opciones:" -ForegroundColor Yellow
Write-Host "1. Abre index.html directamente en tu navegador" -ForegroundColor White
Write-Host "2. Instala Python: https://www.python.org/downloads/" -ForegroundColor White
Write-Host "3. Instala Node.js: https://nodejs.org/" -ForegroundColor White
Write-Host "4. Usa la extensión 'Live Server' en VS Code" -ForegroundColor White
Write-Host ""
Read-Host "Presiona Enter para salir"
