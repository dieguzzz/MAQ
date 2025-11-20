import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class ReportProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GamificationService _gamificationService = GamificationService();
  
  List<ReportModel> _activeReports = [];
  bool _isLoading = false;

  List<ReportModel> get activeReports => _activeReports;
  bool get isLoading => _isLoading;

  ReportProvider() {
    _init();
  }

  void _init() {
    // Listen to active reports stream
    _firebaseService.getActiveReportsStream().listen((reports) {
      _activeReports = reports;
      notifyListeners();
    });
  }

  Future<String?> createReport({
    required String usuarioId,
    required TipoReporte tipo,
    required String objetivoId,
    required CategoriaReporte categoria,
    String? descripcion,
    required GeoPoint ubicacion,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final report = ReportModel(
        id: '', // Se generará en Firestore
        usuarioId: usuarioId,
        tipo: tipo,
        objetivoId: objetivoId,
        categoria: categoria,
        descripcion: descripcion,
        ubicacion: ubicacion,
        creadoEn: DateTime.now(),
      );

      final reportId = await _firebaseService.createReport(report);
      
      // Incrementar contador de reportes del usuario
      final user = await _firebaseService.getUser(usuarioId);
      if (user != null) {
        await _firebaseService.updateUser(
          usuarioId,
          {'reportes_count': user.reportesCount + 1},
        );
        
        // Actualizar streak y gamificación
        await _gamificationService.updateStreak(usuarioId);
      }

      _isLoading = false;
      notifyListeners();
      return reportId;
    } catch (e) {
      print('Error creating report: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> verifyReport(String reportId, String userId) async {
    try {
      await _firebaseService.verifyReport(reportId, userId);
      
      // Obtener información del reporte para saber la línea
      final reportDoc = await _firebaseService.firestore
          .collection('reports')
          .doc(reportId)
          .get();
      
      final reportData = reportDoc.data();
      final objetivoId = reportData?['objetivo_id'] as String?;
      
      // Obtener estación para saber la línea
      String? linea;
      if (objetivoId != null) {
        final stationDoc = await _firebaseService.firestore
            .collection('stations')
            .doc(objetivoId)
            .get();
        linea = stationDoc.data()?['linea'] as String?;
      }
      
      // Otorgar puntos por verificar
      await _gamificationService.awardPointsForVerifying(userId, reportId);
      
      // Si el reporte tiene muchas verificaciones, otorgar puntos al creador
      final verificaciones = reportData?['verificaciones'] ?? 0;
      if (verificaciones >= 3) {
        final creadorId = reportData?['usuario_id'] as String?;
        if (creadorId != null && linea != null) {
          await _gamificationService.awardPointsForVerifiedReport(
            creadorId,
            reportId,
            linea,
          );
        }
      }
      
      // Incrementar reputación del usuario que verificó
      final user = await _firebaseService.getUser(userId);
      if (user != null) {
        final newReputacion = (user.reputacion + 5).clamp(0, 100);
        await _firebaseService.updateUser(
          userId,
          {'reputacion': newReputacion},
        );
      }
    } catch (e) {
      print('Error verifying report: $e');
    }
  }

  Future<List<ReportModel>> getReportsByLocation(
      GeoPoint location, double radiusKm) async {
    try {
      return await _firebaseService.getReportsByLocation(location, radiusKm);
    } catch (e) {
      print('Error getting reports by location: $e');
      return [];
    }
  }
}

