@echo off
echo ========================================
echo   MetroPTY Dashboard - Servidor Local
echo ========================================
echo.
echo Iniciando servidor en http://localhost:3000
echo (No abre navegador automaticamente - usa Browser Control)
echo Presiona Ctrl+C para detener
echo.

REM Verificar si node_modules existe
if not exist "node_modules" (
    echo Instalando dependencias...
    npm install
)

REM Iniciar servidor Vite (sin abrir navegador)
echo Usando Vite dev server...
npm run dev -- --open=false

