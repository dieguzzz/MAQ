import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import '../services/report_validation_service.dart';
import '../services/confidence_service.dart';
import '../services/alert_service.dart';
import '../services/accuracy_service.dart';
import '../services/error_handler_service.dart';
import '../services/app_mode_service.dart';
import '../services/time_estimation_service.dart';
import '../models/report_model.dart';
import '../models/train_model.dart';
import '../models/station_model.dart';
import '../providers/metro_data_provider.dart';

class ReportProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GamificationService _gamificationService = GamificationService();
  final ReportValidationService _validationService = ReportValidationService();
  final ConfidenceService _confidenceService = ConfidenceService();
  final AlertService _alertService = AlertService();
  final AccuracyService _accuracyService = AccuracyService();
  final TimeEstimationService _timeEstimationService = TimeEstimationService();
  
  List<ReportModel> _activeReports = [];
  bool _isLoading = false;
  bool _streamInitialized = false;

  List<ReportModel> get activeReports {
    _ensureStreamInitialized();
    return _activeReports;
  }
  
  bool get isLoading => _isLoading;

  ReportProvider() {
    // No inicializar streams aquí - se hará de forma lazy cuando se necesiten
  }

  /// Inicializa los streams solo cuando se necesitan (lazy initialization)
  void _ensureStreamInitialized() {
    if (_streamInitialized) return;
    _streamInitialized = true;
    _init();
  }

  void _init() {
    // Listen to active reports stream de forma segura
    try {
      _firebaseService.getActiveReportsStream().listen(
        (reports) {
          _activeReports = reports;
          notifyListeners();
        },
        onError: (error) {
          print('Error listening to reports stream: $error');
          // No hacer nada, solo loggear el error
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error initializing reports stream: $e');
      // Continuar sin el stream si hay un error
    }
  }

  Future<String?> createReport({
    required String usuarioId,
    required TipoReporte tipo,
    required String objetivoId,
    required CategoriaReporte categoria,
    String? descripcion,
    required GeoPoint ubicacion,
    String? estadoPrincipal,
    List<String> problemasEspecificos = const [],
    bool prioridad = false,
    String? fotoUrl,
    Position? userLocation,
    int? tiempoEstimadoReportado,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Obtener el modo de app del usuario
      final appModeService = AppModeService();
      final appMode = await appModeService.getCurrentMode(usuarioId);
      
      // Validación anti-spam
      final canReport = await _validationService.canUserReport(usuarioId, objetivoId);
      if (!canReport) {
        _isLoading = false;
        notifyListeners();
        
        // Obtener mensaje de error específico
        final errorMessage = await _validationService.getValidationErrorMessage(
          usuarioId,
          objetivoId,
          userLocation,
          ubicacion,
          appMode: appMode,
        );
        
        throw Exception(errorMessage ?? 'No puedes reportar en este momento. Límite de spam alcanzado o ya reportaste recientemente.');
      }

      // Validación de ubicación (omitida en modo Test)
      if (appMode != AppMode.test && userLocation != null) {
        final isValidLocation = _validationService.isValidReportLocation(
          userLocation,
          ubicacion,
          appMode: appMode,
        );
        if (!isValidLocation) {
          _isLoading = false;
          notifyListeners();
          throw Exception('Debes estar a menos de 1 km de la estación/tren para reportar.');
        }
      }

      final createdAt = DateTime.now();
      
      // Buscar reportes similares para verificación automática
      final similarReports = await _firebaseService.findSimilarReports(
        objetivoId,
        estadoPrincipal,
        createdAt,
      );

      // Calcular confidence inicial
      double confidence = 0.5;
      String verificationStatus = 'pending';
      
      // Si hay 2 o más reportes similares, marcar como verificado
      if (similarReports.length >= 2) {
        confidence = 0.8;
        verificationStatus = 'verified';
      }

      // Validar tiempo estimado si se proporcionó
      bool? tiempoEstimadoValidado;
      if (tiempoEstimadoReportado != null && tipo == TipoReporte.estacion) {
        // Obtener el tren más cercano y la estación para validar
        // Nota: Esto requiere acceso a MetroDataProvider, por ahora lo dejamos como null
        // La validación se puede hacer después de crear el reporte
        tiempoEstimadoValidado = null; // Se validará después si es posible
      }

      final report = ReportModel(
        id: '', // Se generará en Firestore
        usuarioId: usuarioId,
        tipo: tipo,
        objetivoId: objetivoId,
        categoria: categoria,
        descripcion: descripcion,
        ubicacion: ubicacion,
        creadoEn: createdAt,
        estadoPrincipal: estadoPrincipal,
        problemasEspecificos: problemasEspecificos,
        prioridad: prioridad,
        fotoUrl: fotoUrl,
        confidence: confidence,
        verificationStatus: verificationStatus,
        confirmationCount: 0,
        tiempoEstimadoReportado: tiempoEstimadoReportado,
        tiempoEstimadoValidado: tiempoEstimadoValidado,
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

      // Enviar alertas a usuarios afectados (en background)
      if (prioridad || estadoPrincipal == 'lleno' || 
          estadoPrincipal == 'cerrado' || estadoPrincipal == 'detenido' ||
          estadoPrincipal == 'sardina') {
        // Crear reporte con ID para alertas
        final reportWithId = ReportModel(
          id: reportId,
          usuarioId: report.usuarioId,
          tipo: report.tipo,
          objetivoId: report.objetivoId,
          categoria: report.categoria,
          descripcion: report.descripcion,
          ubicacion: report.ubicacion,
          verificaciones: report.verificaciones,
          estado: report.estado,
          creadoEn: report.creadoEn,
          estadoPrincipal: report.estadoPrincipal,
          problemasEspecificos: report.problemasEspecificos,
          prioridad: report.prioridad,
          fotoUrl: report.fotoUrl,
          confidence: report.confidence,
          verificationStatus: report.verificationStatus,
          confirmationCount: report.confirmationCount,
        );

        // Enviar alertas (no esperar para no bloquear)
        if (prioridad) {
          _alertService.sendPriorityAlert(reportWithId);
        } else {
          _alertService.sendRelevantAlerts(reportWithId);
        }
      }

      _isLoading = false;
      notifyListeners();
      return reportId;
    } catch (e) {
      print('Error creating report: $e');
      _isLoading = false;
      notifyListeners();
      // Re-lanzar la excepción con mensaje amigable
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  /// Confirma un reporte de otro usuario
  Future<bool> confirmReport(String reportId, String userId) async {
    try {
      // Verificar si ya confirmó
      final hasConfirmed = await _firebaseService.hasUserConfirmedReport(reportId, userId);
      if (hasConfirmed) {
        return false; // Ya confirmó este reporte
      }

      // Confirmar el reporte
      await _firebaseService.confirmReport(reportId, userId);
      
      // Obtener información del reporte para saber la línea
      final reportDoc = await _firebaseService.firestore
          .collection('reports')
          .doc(reportId)
          .get();
      
      final reportData = reportDoc.data();
      if (reportData == null) {
        return false; // El reporte no existe
      }

      final objetivoId = reportData['objetivo_id'] as String?;
      final confirmationCount = reportData['confirmation_count'] ?? 0;
      
      // Obtener estación para saber la línea
      String? linea;
      if (objetivoId != null) {
        final stationDoc = await _firebaseService.firestore
            .collection('stations')
            .doc(objetivoId)
            .get();
        linea = stationDoc.data()?['linea'] as String?;
      }
      
      // Otorgar puntos por confirmar
      await _gamificationService.awardPointsForVerifying(userId, reportId);
      
      // Si el reporte alcanza 3 confirmaciones, otorgar puntos al creador
      if (confirmationCount >= 3) {
        final creadorId = reportData['usuario_id'] as String?;
        if (creadorId != null && linea != null) {
          await _gamificationService.awardPointsForVerifiedReport(
            creadorId,
            reportId,
            linea,
          );
        }

        // Actualizar estado de estación/tren basado en reportes verificados
        if (objetivoId != null) {
          await _updateStationStatusFromReport(objetivoId, reportData);
        }
      }
      
      // Actualizar confianza del reporte
      await _confidenceService.updateReportConfidence(reportId);
      
      // Actualizar precisión del creador del reporte
      final creadorId = reportData['usuario_id'] as String?;
      if (creadorId != null) {
        await _accuracyService.onReportVerified(creadorId);
      }
      
      // Incrementar reputación del usuario que confirmó
      final user = await _firebaseService.getUser(userId);
      if (user != null) {
        final newReputacion = (user.reputacion + 5).clamp(0, 100);
        await _firebaseService.updateUser(
          userId,
          {'reputacion': newReputacion},
        );
      }

      return true;
    } catch (e) {
      print('Error confirming report: $e');
      // Re-lanzar la excepción con mensaje amigable
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  /// Actualiza el estado de una estación/tren basado en reportes verificados
  Future<void> _updateStationStatusFromReport(
    String objetivoId,
    Map<String, dynamic> reportData,
  ) async {
    try {
      final tipo = reportData['tipo'] as String?;
      final estadoPrincipal = reportData['estado_principal'] as String?;
      
      if (estadoPrincipal == null) return;

      if (tipo == 'estacion') {
        // Actualizar estado de estación
        final stationRef = _firebaseService.firestore
            .collection('stations')
            .doc(objetivoId);
        
        // Mapear estadoPrincipal a estadoActual de estación
        String? estadoActual;
        switch (estadoPrincipal) {
          case 'normal':
            estadoActual = 'normal';
            break;
          case 'moderado':
            estadoActual = 'moderado';
            break;
          case 'lleno':
            estadoActual = 'lleno';
            break;
          case 'cerrado':
            estadoActual = 'cerrado';
            break;
        }

        if (estadoActual != null) {
          await stationRef.update({
            'estado_actual': estadoActual,
            'ultima_actualizacion': FieldValue.serverTimestamp(),
          });
        }
      } else if (tipo == 'tren') {
        // Actualizar estado de tren
        final trainRef = _firebaseService.firestore
            .collection('trains')
            .doc(objetivoId);
        
        // Mapear estadoPrincipal a estado de tren
        String? estadoTren;
        switch (estadoPrincipal) {
          case 'asientos_disponibles':
          case 'de_pie_comodo':
            estadoTren = 'normal';
            break;
          case 'sardina':
            estadoTren = 'retrasado';
            break;
          case 'lento':
          case 'detenido':
            estadoTren = 'detenido';
            break;
        }

        if (estadoTren != null) {
          await trainRef.update({
            'estado': estadoTren,
            'ultima_actualizacion': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error updating station/train status: $e');
    }
  }

  /// Método legacy - mantener para compatibilidad
  Future<void> verifyReport(String reportId, String userId) async {
    await confirmReport(reportId, userId);
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

