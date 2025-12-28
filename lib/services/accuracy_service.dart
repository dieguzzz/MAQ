import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/report_model.dart';
import '../models/simplified_report_model.dart';

class AccuracyService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calcula la precisión de un usuario basado en sus reportes verificados
  /// Retorna un valor entre 0 y 100
  /// Considera tanto reportes del modelo antiguo como SimplifiedReportModel
  Future<double> calculateUserAccuracy(String userId) async {
    try {
      // Obtener todos los reportes del usuario (modelo antiguo)
      final userReports = await _firebaseService.getUserReports(userId);

      // Obtener reportes simplificados del usuario
      final simplifiedReportsSnapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .get();

      final simplifiedReports = simplifiedReportsSnapshot.docs
          .map((doc) {
            try {
              return SimplifiedReportModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .where((report) => report != null)
          .cast<SimplifiedReportModel>()
          .toList();

      // Contar total de reportes
      int totalReports = userReports.length + simplifiedReports.length;

      if (totalReports == 0) {
        return 0.0; // Sin reportes, sin precisión
      }

      // Contar reportes verificados (modelo antiguo)
      int verifiedReports = 0;
      for (final report in userReports) {
        if (report.verificationStatus == 'verified' ||
            report.verificationStatus == 'community_verified' ||
            report.confirmationCount >= 3) {
          verifiedReports++;
        }
      }

      // Contar reportes simplificados verificados (confirmations >= 3)
      for (final report in simplifiedReports) {
        if (report.confirmations >= 3) {
          verifiedReports++;
        }
      }

      // Calcular porcentaje
      final accuracy = (verifiedReports / totalReports) * 100;
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

