import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../models/report_model.dart';
import '../models/route_model.dart';
import '../models/learning_report_model.dart';
import 'error_handler_service.dart';
import 'gamification_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  FirebaseFirestore get firestore => _firestore;

  // User operations
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Error al crear usuario: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      print('Error getting user: ${ErrorHandlerService.getErrorMessage(e)}');
      return null;
    } catch (e) {
      print('Error getting user: ${ErrorHandlerService.getErrorMessage(e)}');
      return null;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Error al actualizar usuario: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Station operations
  Stream<List<StationModel>> getStationsStream() {
    return _firestore
        .collection('stations')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StationModel.fromFirestore(doc))
            .toList());
  }

  Future<List<StationModel>> getStations() async {
    final snapshot = await _firestore.collection('stations').get();
    return snapshot.docs
        .map((doc) => StationModel.fromFirestore(doc))
        .toList();
  }

  Future<void> updateStation(String id, Map<String, dynamic> data) async {
    await _firestore.collection('stations').doc(id).update(data);
  }

  // Train operations
  Stream<List<TrainModel>> getTrainsStream() {
    return _firestore
        .collection('trains')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainModel.fromFirestore(doc))
            .toList());
  }

  Future<List<TrainModel>> getTrains() async {
    final snapshot = await _firestore.collection('trains').get();
    return snapshot.docs.map((doc) => TrainModel.fromFirestore(doc)).toList();
  }

  // Report operations
  Future<String> createReport(ReportModel report) async {
    try {
      // Validar datos antes de enviar
      final reportData = report.toFirestore();
      
      // Validaciones básicas
      if (reportData['usuario_id'] == null || reportData['usuario_id'].toString().isEmpty) {
        throw Exception('El ID de usuario es requerido');
      }
      if (reportData['objetivo_id'] == null || reportData['objetivo_id'].toString().isEmpty) {
        throw Exception('El ID del objetivo es requerido');
      }
      if (reportData['ubicacion'] == null) {
        throw Exception('La ubicación es requerida');
      }
      
      final docRef = await _firestore.collection('reports').add(reportData);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error al crear reporte: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  Stream<List<ReportModel>> getActiveReportsStream() {
    return _firestore
        .collection('reports')
        .where('estado', isEqualTo: 'activo')
        .orderBy('creado_en', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }

  Future<List<ReportModel>> getReportsByLocation(
      GeoPoint location, double radiusKm) async {
    // Nota: Firestore no soporta queries geográficas nativas
    // Esto debería implementarse con Cloud Functions o usar geohashing
    final snapshot = await _firestore
        .collection('reports')
        .where('estado', isEqualTo: 'activo')
        .get();
    
    // Filtrar por distancia (implementación básica)
    final reports = snapshot.docs
        .map((doc) => ReportModel.fromFirestore(doc))
        .where((report) {
      final distance = _calculateDistance(
        location.latitude,
        location.longitude,
        report.ubicacion.latitude,
        report.ubicacion.longitude,
      );
      return distance <= radiusKm;
    }).toList();
    
    return reports;
  }

  /// Confirma un reporte (nuevo sistema de confirmaciones)
  Future<void> confirmReport(String reportId, String userId) async {
    try {
      // Validaciones básicas
      if (reportId.isEmpty) {
        throw Exception('El ID del reporte es requerido');
      }
      if (userId.isEmpty) {
        throw Exception('El ID del usuario es requerido');
      }

      final reportRef = _firestore.collection('reports').doc(reportId);
      final confirmationsRef = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('confirmations')
          .doc(userId);

      // Obtener el reporte primero para validar y obtener el userId del autor
      final reportDoc = await reportRef.get();
      if (!reportDoc.exists) {
        throw Exception('El reporte no existe');
      }

      final reportData = reportDoc.data()!;
      final reportUserId = (reportData['userId'] ?? reportData['usuario_id']) as String?;
      
      // Validar que el reporte tenga un usuario_id
      if (reportUserId == null || reportUserId.isEmpty) {
        throw Exception('El reporte no tiene un usuario_id válido');
      }
      
      // Verificar que el usuario no esté confirmando su propio reporte
      if (reportUserId == userId) {
        throw Exception('No puedes confirmar tu propio reporte');
      }

      await _firestore.runTransaction((transaction) async {
        // Verificar que el usuario no haya confirmado antes
        final confirmationDoc = await transaction.get(confirmationsRef);
        if (confirmationDoc.exists) {
          throw Exception('Ya confirmaste este reporte');
        }

        // Obtener el reporte nuevamente en la transacción
        final transactionReportDoc = await transaction.get(reportRef);
        if (!transactionReportDoc.exists) {
          throw Exception('El reporte no existe');
        }

        final transactionReportData = transactionReportDoc.data()!;
        
        // Usar 'confirmations' (modelo simplificado) o 'confirmation_count' (legacy)
        final currentConfirmations = transactionReportData['confirmations'] ?? transactionReportData['confirmation_count'] ?? 0;
        final newConfirmations = currentConfirmations + 1;

        // Crear la confirmación
        transaction.set(confirmationsRef, {
          'usuario_id': userId,
          'confirmado_en': FieldValue.serverTimestamp(),
        });

        // Actualizar contador de confirmaciones (usar ambos campos para compatibilidad)
        final updateData = <String, dynamic>{
          'confirmations': newConfirmations,
          'confirmation_count': newConfirmations, // Legacy
        };

        // Si alcanza 3 confirmaciones, marcar como verificado por la comunidad
        if (newConfirmations >= 3) {
          updateData['verification_status'] = 'community_verified';
          updateData['confidence'] = 0.9; // Alta confianza
        }

        transaction.update(reportRef, updateData);
      });
      
      // Otorgar puntos al autor del reporte cuando alguien lo confirma (fuera de la transacción)
      final gamificationService = GamificationService();
      await gamificationService.awardPointsToReportAuthor(reportUserId, reportId);
      
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error al confirmar reporte: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  /// Verifica si un usuario ya confirmó un reporte
  Future<bool> hasUserConfirmedReport(String reportId, String userId) async {
    try {
      final confirmationDoc = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('confirmations')
          .doc(userId)
          .get();
      return confirmationDoc.exists;
    } catch (e) {
      print('Error checking confirmation: $e');
      return false;
    }
  }

  /// Obtiene el stream del leaderboard global (top 100 usuarios por puntos)
  Stream<QuerySnapshot> getGlobalLeaderboardStream() {
    return _firestore
        .collection('users')
        .orderBy('gamification.puntos', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Obtiene el stream del leaderboard por línea (top 50 usuarios por puntos en una línea)
  Stream<QuerySnapshot> getLineaLeaderboardStream(String linea) {
    // Nota: Esto requiere un índice compuesto en Firestore
    // Por ahora, filtramos en memoria después de obtener los datos
    return _firestore
        .collection('users')
        .orderBy('gamification.puntos', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Obtiene el stream del leaderboard por precisión (top 50 usuarios más precisos)
  Stream<QuerySnapshot> getAccuracyLeaderboardStream() {
    return _firestore
        .collection('users')
        .orderBy('precision', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Obtiene el stream del leaderboard por streak (top 50 usuarios con mayor racha)
  Stream<QuerySnapshot> getStreakLeaderboardStream() {
    return _firestore
        .collection('users')
        .orderBy('gamification.streak', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Obtiene el stream del leaderboard de helpers (top 50 usuarios que más verifican)
  Stream<QuerySnapshot> getHelpersLeaderboardStream() {
    return _firestore
        .collection('users')
        .orderBy('gamification.verificaciones_hechas', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Método legacy - mantener para compatibilidad
  Future<void> verifyReport(String reportId, String userId) async {
    // Usar el nuevo sistema de confirmaciones
    await confirmReport(reportId, userId);
  }

  /// Busca reportes similares en los últimos 10 minutos
  /// Similar = mismo objetivoId y mismo estadoPrincipal
  Future<List<ReportModel>> findSimilarReports(
    String objetivoId,
    String? estadoPrincipal,
    DateTime createdAt,
  ) async {
    try {
      final tenMinutesAgo = createdAt.subtract(const Duration(minutes: 10));
      
      Query query = _firestore
          .collection('reports')
          .where('objetivo_id', isEqualTo: objetivoId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(tenMinutesAgo))
          .where('estado', isEqualTo: 'activo');

      // Si hay estadoPrincipal, filtrar por él también
      if (estadoPrincipal != null && estadoPrincipal.isNotEmpty) {
        query = query.where('estado_principal', isEqualTo: estadoPrincipal);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error finding similar reports: $e');
      return [];
    }
  }

  /// Obtiene todos los reportes de un usuario específico
  Stream<List<ReportModel>> getUserReportsStream(String userId) {
    return _firestore
        .collection('reports')
        .where('usuario_id', isEqualTo: userId)
        .orderBy('creado_en', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }

  /// Obtiene todos los reportes de un usuario (una vez)
  Future<List<ReportModel>> getUserReports(String userId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('usuario_id', isEqualTo: userId)
        .orderBy('creado_en', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ReportModel.fromFirestore(doc))
        .toList();
  }

  /// Elimina todos los datos del usuario de Firestore
  /// Nota: Los reportes no se eliminan (solo se marcan como inactivos si es necesario)
  /// ya que las reglas de Firestore no permiten eliminar reportes
  Future<void> deleteUserData(String userId) async {
    // Eliminar documento del usuario
    await _firestore.collection('users').doc(userId).delete();
    
    // Nota: Los reportes no se eliminan porque las reglas de Firestore
    // no permiten eliminar reportes. Si se necesita, se pueden marcar
    // como eliminados o anónimos en una actualización futura.
  }

  /// Elimina la cuenta de Firebase Auth
  Future<void> deleteAuthAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  // Route operations
  Future<RouteModel?> getRoute(String origen, String destino) async {
    final snapshot = await _firestore
        .collection('routes')
        .where('origen', isEqualTo: origen)
        .where('destino', isEqualTo: destino)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return RouteModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Auth operations
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> getAuthStateChanges() {
    return _auth.authStateChanges();
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Error al crear cuenta: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Error al iniciar sesión como invitado: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Inicializar GoogleSignIn (solo la primera vez)
        await _googleSignIn.initialize();
        
        // Autenticar con Google
        final GoogleSignInAccount account = await _googleSignIn.authenticate(scopeHint: ['email']);
        
        // Obtener idToken de la autenticación
        final GoogleSignInAuthentication auth = account.authentication;
        final String? idToken = auth.idToken;
        
        // Obtener accessToken del cliente de autorización
        final GoogleSignInClientAuthorization? clientAuth = 
            await account.authorizationClient.authorizationForScopes(['email']);
        final String? accessToken = clientAuth?.accessToken;
        
        if (idToken == null || accessToken == null) {
          throw Exception('No se pudieron obtener los tokens de autenticación');
        }
        
        final credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  // Helper: Calculate distance between two points (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final cosLat1 = math.cos(_toRadians(lat1));
    final cosLat2 = math.cos(_toRadians(lat2));
    
    final a = sinDLat * sinDLat +
        cosLat1 * cosLat2 * sinDLon * sinDLon;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Learning Reports operations
  /// Crea un reporte de aprendizaje en Firestore
  Future<String> createLearningReport(LearningReportModel report) async {
    try {
      final docRef = await _firestore
          .collection('learning_reports')
          .add(report.toFirestore());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception(
          'Error al crear reporte de aprendizaje: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  /// Obtiene un stream de reportes de aprendizaje recientes
  Stream<List<LearningReportModel>> getLearningReportsStream(
      {int days = 14}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return _firestore
        .collection('learning_reports')
        .where('creado_en',
            isGreaterThan: Timestamp.fromDate(cutoffDate))
        .orderBy('creado_en', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LearningReportModel.fromFirestore(doc))
            .toList());
  }

  /// Obtiene reportes de aprendizaje por estación
  Future<List<LearningReportModel>> getLearningReportsByStation(
      String stationId,
      {int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('learning_reports')
          .where('estacion_id', isEqualTo: stationId)
          .where('creado_en',
              isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('creado_en', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LearningReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting learning reports by station: $e');
      return [];
    }
  }

  /// Obtiene el stream del leaderboard de profesores (top usuarios por teachingScore)
  Stream<QuerySnapshot> getTeachersLeaderboardStream({int limit = 50}) {
    return _firestore
        .collection('users')
        .orderBy('gamification.teaching_score', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Model Metrics operations
  /// Referencia a la colección de métricas del modelo
  CollectionReference get modelMetricsRef =>
      _firestore.collection('model_metrics');

  /// Guarda o actualiza las métricas del modelo
  Future<void> updateModelMetrics(Map<String, dynamic> metrics) async {
    try {
      await modelMetricsRef.doc('current').set(metrics, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    } catch (e) {
      throw Exception(
          'Error al actualizar métricas del modelo: ${ErrorHandlerService.getErrorMessage(e)}');
    }
  }

  /// Obtiene las métricas actuales del modelo
  Future<Map<String, dynamic>?> getModelMetrics() async {
    try {
      final doc = await modelMetricsRef.doc('current').get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting model metrics: $e');
      return null;
    }
  }

  /// Obtiene un stream de las métricas del modelo
  Stream<DocumentSnapshot> getModelPerformanceStream() {
    return modelMetricsRef.doc('current').snapshots();
  }
}

