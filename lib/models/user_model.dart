import 'package:cloud_firestore/cloud_firestore.dart';
import 'gamification_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String? fotoUrl;
  final int reputacion; // 1-100
  final int reportesCount;
  final DateTime creadoEn;
  final GeoPoint? ultimaUbicacion;
  final GamificationStats? gamification;

  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    this.fotoUrl,
    this.reputacion = 50,
    this.reportesCount = 0,
    required this.creadoEn,
    this.ultimaUbicacion,
    this.gamification,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      fotoUrl: data['foto_url'],
      reputacion: data['reputacion'] ?? 50,
      reportesCount: data['reportes_count'] ?? 0,
      creadoEn: (data['creado_en'] as Timestamp).toDate(),
      ultimaUbicacion: data['ultima_ubicacion'] as GeoPoint?,
      gamification: data['gamification'] != null
          ? GamificationStats.fromFirestore(
              data['gamification'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'foto_url': fotoUrl,
      'reputacion': reputacion,
      'reportes_count': reportesCount,
      'creado_en': Timestamp.fromDate(creadoEn),
      'ultima_ubicacion': ultimaUbicacion,
      'gamification': gamification?.toFirestore(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? nombre,
    String? fotoUrl,
    int? reputacion,
    int? reportesCount,
    DateTime? creadoEn,
    GeoPoint? ultimaUbicacion,
    GamificationStats? gamification,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      reputacion: reputacion ?? this.reputacion,
      reportesCount: reportesCount ?? this.reportesCount,
      creadoEn: creadoEn ?? this.creadoEn,
      ultimaUbicacion: ultimaUbicacion ?? this.ultimaUbicacion,
      gamification: gamification ?? this.gamification,
    );
  }

  String getNivelReputacion() {
    if (reputacion >= 501) return 'Maestro Metro';
    if (reputacion >= 201) return 'Experto';
    if (reputacion >= 51) return 'Colaborador';
    return 'Principiante';
  }
}

