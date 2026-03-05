# Prompt - Refactorizar Widget Grande (Flutter)

Objetivo: dividir un widget >300 líneas sin cambiar comportamiento.

Instrucciones:
- Mantener API pública del widget (props y uso).
- Extraer subwidgets con responsabilidades claras:
  - Header
  - Lista
  - Empty state
  - Loading/Error
- Extraer lógica a provider/service si hoy está en UI.
- Asegurar `context.mounted` después de awaits.
- No tocar diseño a menos que sea necesario.

Salida:
- Lista de archivos tocados
- Checklist de verificación manual
