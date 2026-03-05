# Prompt - Google Maps Feature

Objetivo: integrar mapa sin hardcodear keys, y con buen performance.

Requerido:
- Markers tipados y actualizables
- No recalcular markers innecesariamente
- Separar MapWidget (UI) de MapService (helpers/transformaciones)
- Manejo de permisos (location) con UX clara
- No guardar API keys en Dart

Salida:
- Cambios exactos en AndroidManifest/Info.plist si aplica
- Lista de escenarios a probar (permisos on/off, GPS off, etc.)
