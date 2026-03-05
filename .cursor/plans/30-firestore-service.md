# Prompt - Implementar/Mejorar Servicio Firestore

Meta: servicio robusto, tipado, seguro.

Requerido:
- Métodos `Future<List<T>>`, `Future<T?>`, `Stream<List<T>>` según caso
- try/catch con mensajes útiles
- `.limit(n)` siempre
- Evitar N+1 queries si es posible
- Mapear docs a modelos con factory (fromFirestore)

Entregables:
- Código del service
- Ejemplo de uso desde provider
- Índices sugeridos si query compuesta
