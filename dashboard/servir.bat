@echo off
echo ========================================
echo   MetroPTY Dashboard - Servidor Local
echo ========================================
echo.
echo Iniciando servidor en http://localhost:3000
echo Presiona Ctrl+C para detener
echo.

REM Verificar si node_modules existe
if not exist "node_modules" (
    echo Instalando dependencias...
    npm install
)

REM Abrir navegador después de un pequeño delay
start /b cmd /c "timeout /t 2 >nul && start http://localhost:3000"

REM Iniciar servidor Vite
echo Usando Vite dev server...
npm run dev
