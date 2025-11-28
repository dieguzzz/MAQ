import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AccuracyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Calcula la precisión de un usuario basado en sus reportes verificados
  /// Retorna un valor entre 0 y 100
  Future<double> calculateUserAccuracy(String userId) async {
    try {
      // Obtener todos los reportes del usuario
      final userReports = await _firebaseService.getUserReports(userId);

      if (userReports.isEmpty) {
        return 0.0; // Sin reportes, sin precisión
      }

      // Contar reportes verificados
      int verifiedReports = 0;
      for (final report in userReports) {
        if (report.verificationStatus == 'verified' ||
            report.verificationStatus == 'community_verified' ||
            report.confirmationCount >= 3) {
          verifiedReports++;
        }
      }

      // Calcular porcentaje
      final accuracy = (verifiedReports / userReports.length) * 100;
      return accuracy.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating user accuracy: $e');
      return 0.0;
    }
  }

  /// Actualiza la precisión del usuario en Firestore
  Future<void> updateUserAccuracy(String userId) async {
    try {
      final accuracy = await calculateUserAccuracy(userId);

      await _firebaseService.updateUser(
        userId,
        {'precision': accuracy},
      );
    } catch (e) {
      print('Error updating user accuracy: $e');
    }
  }

  /// Obtiene el badge de precisión del usuario
  String getAccuracyBadge(double accuracy) {
    if (accuracy >= 95) return '🎯 Francotirador';
    if (accuracy >= 85) return '🔍 Detective';
    if (accuracy >= 70) return '👀 Observador';
    return '📝 Reportero';
  }

  /// Actualiza la precisión cuando se verifica un reporte
  Future<void> onReportVerified(String userId) async {
    await updateUserAccuracy(userId);
  }
}

