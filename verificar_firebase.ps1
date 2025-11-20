# Script de Verificacion de Firebase
Write-Host ""
Write-Host "Verificacion de Configuracion Firebase - MetroPTY" -ForegroundColor Cyan
Write-Host ""

# Verificar archivos
$androidFile = Test-Path "android/app/google-services.json"
$iosFile = Test-Path "ios/Runner/GoogleService-Info.plist"

Write-Host "Archivos de Configuracion:" -ForegroundColor Yellow
Write-Host "  Android (google-services.json): " -NoNewline
if ($androidFile) {
    Write-Host "ENCONTRADO" -ForegroundColor Green
    $androidContent = Get-Content "android/app/google-services.json" -Raw
    if ($androidContent -match 'package_name') {
        Write-Host "    Archivo parece valido" -ForegroundColor Green
    }
} else {
    Write-Host "NO ENCONTRADO" -ForegroundColor Red
    Write-Host "    Debes descargarlo desde Firebase Console" -ForegroundColor Yellow
    Write-Host "    Colocalo en: android/app/google-services.json" -ForegroundColor Yellow
}

Write-Host "  iOS (GoogleService-Info.plist): " -NoNewline
if ($iosFile) {
    Write-Host "ENCONTRADO" -ForegroundColor Green
} else {
    Write-Host "No encontrado (opcional)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Verificacion de Package Name:" -ForegroundColor Yellow
$buildGradle = Get-Content "android/app/build.gradle.kts" -Raw
if ($buildGradle -match 'applicationId = "com\.example\.metropty"') {
    Write-Host "  Package name correcto: com.example.metropty" -ForegroundColor Green
} else {
    Write-Host "  Verifica el package name en build.gradle.kts" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Verificacion de Codigo:" -ForegroundColor Yellow
$mainDart = Get-Content "lib/main.dart" -Raw
if ($mainDart -match "Firebase.initializeApp") {
    Write-Host "  Firebase.initializeApp() encontrado" -ForegroundColor Green
} else {
    Write-Host "  Firebase.initializeApp() no encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "Proximos Pasos:" -ForegroundColor Cyan
if (-not $androidFile) {
    Write-Host "1. Ve a: https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "2. Crea proyecto MetroPTY" -ForegroundColor White
    Write-Host "3. Agrega app Android con package: com.example.metropty" -ForegroundColor White
    Write-Host "4. Descarga google-services.json" -ForegroundColor White
    Write-Host "5. Colocalo en: android/app/google-services.json" -ForegroundColor White
    Write-Host "6. Ejecuta este script nuevamente para verificar" -ForegroundColor White
} else {
    Write-Host "Firebase parece estar configurado correctamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prueba compilar con:" -ForegroundColor Yellow
    Write-Host "  flutter clean" -ForegroundColor White
    Write-Host "  flutter pub get" -ForegroundColor White
    Write-Host "  flutter build apk --debug" -ForegroundColor White
}

Write-Host ""
Write-Host "Ver guia completa: FIREBASE_CONFIGURACION_INTERACTIVA.md" -ForegroundColor Cyan
Write-Host ""
