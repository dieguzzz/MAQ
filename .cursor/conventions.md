# MetroPTY - Convenciones de Código

## Estilo
- Null safety estricto
- Preferir `const` en widgets y constructores
- Widgets pequeños:
  - Widget: <= 300 líneas
  - Función: <= 50 líneas
- No lógica de negocio en UI

## Naming
- Clases: PascalCase
- Variables/métodos: camelCase
- Privados: _prefix
- Constantes: kPascalCase o const normal en constants.dart

## Errores y logging
- NUNCA usar `print()` — usar `AppLogger` de `lib/core/logger.dart`
- `AppLogger` solo imprime en `kDebugMode` (zero output en release)
- Niveles: `debug()`, `info()`, `warning()`, `error()`
- Mensajes de error al usuario: genéricos, NUNCA exponer error.code/message
- Servicios devuelven resultados tipados o lanzan excepciones controladas

## Seguridad
- Ver reglas completas en `.cursor/plans/90-security.md`
- Escrituras a colecciones compartidas: solo via Cloud Functions
- API keys: en `local.properties` (git-ignored), nunca en código
- Usuarios anónimos: sin acceso a crear reportes/confirmaciones
- Rate limiting: implementar en cliente Y servidor
- Validación server-side: usar whitelists, no blacklists

## Firestore
- Siempre `.limit()`
- Siempre `orderBy()` donde aplique
- Manejo de errores try/catch
- Streams deben cancelarse o usar `StreamBuilder` con streams bien encapsulados
