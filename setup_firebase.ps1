# Script de Configuración de Firebase para MetroPTY
# Ejecutar en PowerShell: .\setup_firebase.ps1

Write-Host "🔥 Configuración de Firebase para MetroPTY" -ForegroundColor Cyan
Write-Host ""

# Verificar si Firebase CLI está instalado
$firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseInstalled) {
    Write-Host "❌ Firebase CLI no está instalado." -ForegroundColor Red
    Write-Host "Instala con: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Firebase CLI detectado: $(firebase --version)" -ForegroundColor Green
Write-Host ""

# Verificar si el usuario está logueado
Write-Host "Verificando sesión de Firebase..." -ForegroundColor Yellow
$loginStatus = firebase projects:list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  No estás logueado en Firebase." -ForegroundColor Yellow
    Write-Host "Ejecutando: firebase login" -ForegroundColor Cyan
    firebase login
}

Write-Host ""
Write-Host "📋 Pasos para configurar Firebase:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Crear proyecto en Firebase Console:" -ForegroundColor Yellow
Write-Host "   https://console.firebase.google.com/" -ForegroundColor White
Write-Host ""
Write-Host "2. O usar Firebase CLI para inicializar:" -ForegroundColor Yellow
Write-Host "   firebase init" -ForegroundColor White
Write-Host ""
Write-Host "3. Durante firebase init, selecciona:" -ForegroundColor Yellow
Write-Host "   ✅ Firestore (para reglas)" -ForegroundColor Green
Write-Host "   ❌ Functions (no por ahora)" -ForegroundColor Red
Write-Host "   ❌ Hosting (opcional)" -ForegroundColor Red
Write-Host ""
Write-Host "4. Desplegar reglas de Firestore:" -ForegroundColor Yellow
Write-Host "   firebase deploy --only firestore:rules" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANTE: Los archivos google-services.json y GoogleService-Info.plist" -ForegroundColor Yellow
Write-Host "   deben descargarse manualmente desde Firebase Console." -ForegroundColor Yellow
Write-Host ""

# Preguntar si quiere inicializar ahora
$response = Read-Host "¿Quieres inicializar Firebase ahora? (s/n)"
if ($response -eq "s" -or $response -eq "S") {
    Write-Host ""
    Write-Host "Ejecutando: firebase init" -ForegroundColor Cyan
    firebase init
}

Write-Host ""
Write-Host "📝 Próximos pasos manuales:" -ForegroundColor Cyan
Write-Host "1. Ve a Firebase Console y crea el proyecto" -ForegroundColor White
Write-Host "2. Agrega app Android y descarga google-services.json" -ForegroundColor White
Write-Host "3. Agrega app iOS y descarga GoogleService-Info.plist" -ForegroundColor White
Write-Host "4. Coloca los archivos en las carpetas correspondientes" -ForegroundColor White
Write-Host "5. Habilita Authentication y Firestore desde la consola" -ForegroundColor White
Write-Host ""
Write-Host "📚 Ver guía completa en: FIREBASE_SETUP.md" -ForegroundColor Cyan

