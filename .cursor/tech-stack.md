# MetroPTY - Tech Stack

## Core
- Flutter (stable) + Dart (null safety)
- State management: Provider (ChangeNotifier + selectors)
- Firebase:
  - Auth
  - Firestore
  - Cloud Messaging (FCM) si aplica
  - (Opcional) Functions

## Maps
- google_maps_flutter
- geolocator (ubicación)
- permission_handler (permisos)

## Quality
- flutter_lints
- flutter_test
- (Opcional) mocktail / firebase_mocks para tests

## Non-goals (evitar “inventos”)
- No migrar a Riverpod/BLoC/GetX sin autorización.
- No reestructurar carpetas masivamente.
- No introducir patrones enterprise si no aportan valor directo.
