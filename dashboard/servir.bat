@echo off
echo ========================================
echo   MetroPTY Dashboard - Servidor Local
echo ========================================
echo.
echo Iniciando servidor en http://localhost:8000
echo Presiona Ctrl+C para detener
echo.

REM Intentar con Python (py)
where py >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Usando Python (py)...
    py -m http.server 8000
    goto :end
)

REM Intentar con Python3
where python3 >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Usando Python3...
    python3 -m http.server 8000
    goto :end
)

REM Intentar con Python
where python >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Usando Python...
    python -m http.server 8000
    goto :end
)

REM Intentar con Node.js (npx)
where npx >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Usando Node.js (npx)...
    npx http-server -p 8000
    goto :end
)

REM Intentar con PHP
where php >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Usando PHP...
    php -S localhost:8000
    goto :end
)

echo.
echo ERROR: No se encontró ningún servidor disponible.
echo.
echo Opciones:
echo 1. Abre index.html directamente en tu navegador
echo 2. Instala Python: https://www.python.org/downloads/
echo 3. Instala Node.js: https://nodejs.org/
echo 4. Usa la extensión "Live Server" en VS Code
echo.
pause

:end
