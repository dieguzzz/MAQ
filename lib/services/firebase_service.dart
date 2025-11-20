import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../models/report_model.dart';
import '../models/route_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  FirebaseFirestore get firestore => _firestore;

  // User operations
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
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
    final docRef = await _firestore.collection('reports').add(report.toFirestore());
    return docRef.id;
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

  Future<void> verifyReport(String reportId, String userId) async {
    final reportRef = _firestore.collection('reports').doc(reportId);
    await _firestore.runTransaction((transaction) async {
      final reportDoc = await transaction.get(reportRef);
      if (reportDoc.exists) {
        final currentVerificaciones = reportDoc.data()?['verificaciones'] ?? 0;
        transaction.update(reportRef, {
          'verificaciones': currentVerificaciones + 1,
        });
      }
    });
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
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
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
}

