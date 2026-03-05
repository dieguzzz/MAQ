import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import '../../core/logger.dart';

enum AppMode {
  development,
  test,
}

class AppModeService {
  static final AppModeService _instance = AppModeService._internal();
  factory AppModeService() => _instance;
  AppModeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Convierte String a AppMode
  static AppMode fromString(String? mode) {
    switch (mode) {
      case 'test':
        return AppMode.test;
      case 'development':
      default:
        return AppMode.development;
    }
  }

  /// Convierte AppMode a String
  static String toModeString(AppMode mode) {
    switch (mode) {
      case AppMode.test:
        return 'test';
      case AppMode.development:
        return 'development';
    }
  }

  /// Obtiene el modo actual del usuario
  Future<AppMode> getCurrentMode(String userId) async {
    try {
      final user = await _firebaseService.getUser(userId);
      if (user == null) {
        return AppMode.development; // Modo por defecto
      }
      return fromString(user.appMode);
    } catch (e) {
      AppLogger.error('Error obteniendo modo de app: $e');
      return AppMode.development; // Modo por defecto en caso de error
    }
  }

  /// Establece el modo de la aplicación para el usuario
  Future<void> setMode(String userId, AppMode mode) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'app_mode': toModeString(mode),
        'updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.debug('✅ Modo de app actualizado: ${toModeString(mode)}');
    } catch (e) {
      AppLogger.error('❌ Error actualizando modo de app: $e');
      rethrow;
    }
  }

  /// Stream para escuchar cambios en el modo del usuario
  Stream<AppMode> watchMode(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return AppMode.development;
      }
      final data = doc.data();
      return fromString(data?['app_mode'] as String?);
    });
  }

  /// Verifica si el modo actual es Test
  Future<bool> isTestMode(String userId) async {
    final mode = await getCurrentMode(userId);
    return mode == AppMode.test;
  }
}
