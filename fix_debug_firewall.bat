@echo off
echo ===================================================
echo   FIX FLUTTER DEBUG CONNECTION (FIREWALL RULE)
echo ===================================================
echo.
echo This script requires Administrator privileges.
echo If you didn't run as Admin, close and right-click -> Run as Administrator.
echo.
pause

echo Adding firewall rule for Flutter Debugger ports (1024-65535)...
netsh advfirewall firewall add rule name="Flutter Debug" dir=in action=allow protocol=TCP localport=1024-65535

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Firewall rule added! 
    echo Please restart VS Code and try debugging again.
) else (
    echo.
    echo [ERROR] Failed to add rule. Make sure you are running as Administrator.
)
echo.
pause
