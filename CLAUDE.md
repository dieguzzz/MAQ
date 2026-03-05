# MetroPTY (MAQ) - Claude Code Rules

## Project
Flutter + Firebase metro transit app for Panama City. Provider-based state management.

## Architecture
```
UI → Provider → Service → Firebase
```
- Widgets: only render, dispatch actions, show loading/error
- Providers: state (loading/error/data), call services, `notifyListeners()`
- Services: Firestore/Auth/Maps/Location, validations, no BuildContext

## Structure (DO NOT change)
```
lib/
├── core/          # logger.dart, constants
├── models/
├── services/      # Domain-based: core/, stations/, reports/, location/, etc.
├── providers/
├── screens/
├── widgets/
└── utils/
```

## Critical Rules

### Logging
- **NEVER** use `print()`. Use `AppLogger` from `lib/core/logger.dart`
- AppLogger only outputs in `kDebugMode` (zero output in release builds)
- **NEVER** show error.code, error.message, or stack traces to users

### Firebase Security
- **NEVER** write directly to shared collections (stations, trains, model_metrics) from client
- Use Cloud Functions (callable or triggers) for shared data writes
- Update `firestore.rules` for every new collection/subcollection
- Update `storage.rules` for every new upload path
- Block anonymous users from sensitive operations (reports, confirmations)
- FCM tokens go in `fcm_tokens/{userId}` collection, NOT in user document

### API Keys
- **NEVER** hardcode API keys in Dart code or AndroidManifest.xml
- Keys go in `android/local.properties` (git-ignored), loaded via build.gradle manifestPlaceholders
- `google-services.json` and `GoogleService-Info.plist` are git-ignored

### Validation
- Client-side: anti-spam (10 reports/hr), location (500m radius, no mock GPS)
- Server-side: field whitelists, rate limiting, GeoPoint bounds (Panama: lat 8.9-9.15, lng -79.6 to -79.35)
- Points cap: 500/day (server-enforced)
- Storage uploads: max 5MB, image types only (jpeg/png/webp)

### Code Quality
- `flutter analyze` must pass with 0 errors/warnings
- Max widget: 300 lines, max function: 50 lines, max service: 400 lines
- Null safety strict, `const` constructors where possible
- Firestore queries always use `.limit()` and `.orderBy()` where applicable
- Cancel all stream subscriptions in `dispose()`

## Full Security Reference
See `.cursor/plans/90-security.md` for complete security checklist, templates, and rules.
