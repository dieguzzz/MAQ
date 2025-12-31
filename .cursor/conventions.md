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
- No “print” suelto en producción
- Usar `debugPrint` y mensajes con contexto
- Servicios devuelven resultados tipados o lanzan excepciones controladas

## Firestore
- Siempre `.limit()`
- Siempre `orderBy()` donde aplique
- Manejo de errores try/catch
- Streams deben cancelarse o usar `StreamBuilder` con streams bien encapsulados
