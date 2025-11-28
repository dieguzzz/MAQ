import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class ConfidenceService {
  final FirebaseService _firebaseService = FirebaseService();

  /// Calcula la confianza de un reporte basado en múltiples factores
  /// Retorna un valor entre 0.0 y 1.0
  Future<double> calculateConfidence(ReportModel report) async {
    double baseScore = 0.5;

    // Factor 1: Reputación del usuario (0-0.3)
    final user = await _firebaseService.getUser(report.usuarioId);
    if (user != null) {
      // Reputación va de 0-100, convertir a 0-0.3
      final reputationScore = (user.reputacion / 100) * 0.3;
      baseScore += reputationScore;
    }

    // Factor 2: Confirmaciones de otros usuarios (0-0.3)
    // Cada confirmación agrega 0.1, máximo 0.3 (3 confirmaciones)
    final confirmationScore = (report.confirmationCount * 0.1).clamp(0.0, 0.3);
    baseScore += confirmationScore;

    // Factor 3: Ubicación coincidente (0-0.2)
    // Si el usuario está cerca de la ubicación reportada, aumenta confianza
    // Esto se verifica en el cliente, aquí asumimos que si pasó la validación, es válido
    // Por ahora, no podemos verificar esto sin la ubicación del usuario
    // baseScore += 0.1; // Se puede agregar si se pasa la ubicación del usuario

    // Factor 4: Reporte verificado automáticamente (0-0.2)
    if (report.verificationStatus == 'verified' || 
        report.verificationStatus == 'community_verified') {
      baseScore += 0.2;
    }

    // Factor 5: Tiene foto (0-0.1)
    if (report.fotoUrl != null && report.fotoUrl!.isNotEmpty) {
      baseScore += 0.1;
    }

    return baseScore.clamp(0.0, 1.0);
  }

  /// Actualiza la confianza de un reporte
  Future<void> updateReportConfidence(String reportId) async {
    try {
      final reportDoc = await _firebaseService.firestore
          .collection('reports')
          .doc(reportId)
          .get();

      if (!reportDoc.exists) return;

      final report = ReportModel.fromFirestore(reportDoc);
      final newConfidence = await calculateConfidence(report);

      await _firebaseService.firestore
          .collection('reports')
          .doc(reportId)
          .update({
        'confidence': newConfidence,
      });
    } catch (e) {
      print('Error updating report confidence: $e');
    }
  }
}

