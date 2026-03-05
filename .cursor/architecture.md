# MetroPTY - Arquitectura (Reglas prácticas)

## Flujo
UI -> Provider -> Service -> Firebase
UI solo:
- Renderiza
- Dispara acciones
- Muestra loading/error

Provider:
- Estado (loading/error/data)
- Llama servicios
- notifyListeners()

Service:
- Firestore/Auth/Maps/Location
- Validaciones y transformaciones
- Sin BuildContext

## Principios
- Cambios pequeños y seguros (PRs mentales)
- Reusar patrones existentes en el repo
- Si un widget crece: extraer subwidgets + helpers
