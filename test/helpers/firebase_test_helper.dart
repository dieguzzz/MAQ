import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper para configurar Firebase en tests
/// 
/// Nota: Para tests reales con Firebase Emulator, se necesita:
/// 1. Inicializar Firebase con emulator
/// 2. Configurar variables de entorno
/// 
/// Por ahora, este helper proporciona estructura básica
class FirebaseTestHelper {
  static bool _initialized = false;

  /// Inicializa Firebase para tests
  /// 
  /// En un entorno real, esto configuraría el emulador:
  /// ```dart
  /// await Firebase.initializeApp();
  /// FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  /// ```
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // TODO: Configurar Firebase Emulator cuando esté disponible
    // Por ahora, solo marcamos como inicializado
    _initialized = true;
  }

  /// Crea datos de prueba para una estación
  static Map<String, dynamic> createTestStation({
    required String id,
    required String nombre,
    required String linea,
    required double lat,
    required double lng,
  }) {
    return {
      'id': id,
      'nombre': nombre,
      'linea': linea,
      'ubicacion': GeoPoint(lat, lng),
      'estado_actual': 'normal',
      'aglomeracion': 1,
      'ultima_actualizacion': FieldValue.serverTimestamp(),
      'confidence': 'low',
      'is_estimated': false,
    };
  }

  /// Crea datos de prueba para un reporte simplificado
  static Map<String, dynamic> createTestReport({
    required String id,
    required String stationId,
    required String userId,
    String? stationOperational,
    int? stationCrowd,
    List<String>? stationIssues,
    int confirmations = 0,
    double confidence = 0.5,
  }) {
    return {
      'id': id,
      'scope': 'station',
      'stationId': stationId,
      'userId': userId,
      if (stationOperational != null) 'stationOperational': stationOperational,
      if (stationCrowd != null) 'stationCrowd': stationCrowd,
      'stationIssues': stationIssues ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'confirmations': confirmations,
      'confidence': confidence,
      'basePoints': 15,
      'bonusPoints': 0,
      'totalPoints': 15,
    };
  }

  /// Limpia datos de prueba
  /// 
  /// En un entorno real con emulador, esto limpiaría las colecciones
  static Future<void> cleanup() async {
    // TODO: Implementar limpieza cuando Firebase Emulator esté configurado
  }
}

