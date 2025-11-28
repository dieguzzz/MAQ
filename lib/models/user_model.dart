import 'package:cloud_firestore/cloud_firestore.dart';
import 'gamification_model.dart';
import '../services/level_service.dart';

class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String? fotoUrl;
  final int reputacion; // 1-100
  final int reportesCount;
  final double precision; // 0.0-100.0
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
    this.precision = 0.0,
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
      precision: (data['precision'] ?? 0.0).toDouble(),
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
      'precision': precision,
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
    double? precision,
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
      precision: precision ?? this.precision,
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

  /// Obtiene el nivel actual del usuario (1-50) basado en puntos
  int get level {
    if (gamification == null) return 1;
    return LevelService.calculateLevel(gamification!.puntos);
  }

  /// Obtiene el nombre del nivel con emoji
  String get levelName {
    return LevelService.getLevelName(level);
  }

  /// Obtiene el progreso hacia el siguiente nivel (0.0-1.0)
  double get levelProgress {
    if (gamification == null) return 0.0;
    return LevelService.getProgress(gamification!.puntos, level);
  }
}

