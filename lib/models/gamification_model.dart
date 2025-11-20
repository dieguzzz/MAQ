import 'package:cloud_firestore/cloud_firestore.dart';

enum UserLevel {
  novato, // 0-10 reportes
  viajeroFrecuente, // 11-50 reportes
  reporteroConfiable, // 51-200 reportes
  heroeMetro, // 201+ reportes
}

enum BadgeType {
  primerReporte,
  verificador,
  ojoDeAguila,
  salvavidas,
  metroMaster,
  streakSemana,
  streakMes,
  topContribuidor,
}

class Badge {
  final BadgeType type;
  final String nombre;
  final String descripcion;
  final String icono;
  final DateTime? desbloqueadoEn;

  Badge({
    required this.type,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    this.desbloqueadoEn,
  });

  factory Badge.fromFirestore(Map<String, dynamic> data) {
    return Badge(
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => BadgeType.primerReporte,
      ),
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      icono: data['icono'] ?? '🏆',
      desbloqueadoEn: data['desbloqueado_en'] != null
          ? (data['desbloqueado_en'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString(),
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'desbloqueado_en': desbloqueadoEn != null
          ? Timestamp.fromDate(desbloqueadoEn!)
          : null,
    };
  }
}

class GamificationStats {
  final int puntos;
  final UserLevel nivel;
  final int streak; // Días consecutivos reportando
  final double precision; // 0.0 - 1.0
  final int reportesVerificados; // Reportes confirmados por otros
  final int verificacionesHechas; // Reportes de otros que confirmó
  final int seguidores;
  final int ranking;
  final int rankingLinea1;
  final int rankingLinea2;
  final List<Badge> badges;
  final DateTime? ultimoReporte;
  final Map<String, int> puntosPorLinea; // Puntos por cada línea

  GamificationStats({
    this.puntos = 0,
    UserLevel? nivel,
    this.streak = 0,
    this.precision = 0.0,
    this.reportesVerificados = 0,
    this.verificacionesHechas = 0,
    this.seguidores = 0,
    this.ranking = 0,
    this.rankingLinea1 = 0,
    this.rankingLinea2 = 0,
    List<Badge>? badges,
    this.ultimoReporte,
    Map<String, int>? puntosPorLinea,
  })  : nivel = nivel ?? UserLevel.novato,
        badges = badges ?? [],
        puntosPorLinea = puntosPorLinea ?? {};

  factory GamificationStats.fromFirestore(Map<String, dynamic> data) {
    return GamificationStats(
      puntos: data['puntos'] ?? 0,
      nivel: UserLevel.values.firstWhere(
        (e) => e.toString() == data['nivel'],
        orElse: () => UserLevel.novato,
      ),
      streak: data['streak'] ?? 0,
      precision: (data['precision'] ?? 0.0).toDouble(),
      reportesVerificados: data['reportes_verificados'] ?? 0,
      verificacionesHechas: data['verificaciones_hechas'] ?? 0,
      seguidores: data['seguidores'] ?? 0,
      ranking: data['ranking'] ?? 0,
      rankingLinea1: data['ranking_linea1'] ?? 0,
      rankingLinea2: data['ranking_linea2'] ?? 0,
      badges: (data['badges'] as List<dynamic>?)
              ?.map((b) => Badge.fromFirestore(b as Map<String, dynamic>))
              .toList() ??
          [],
      ultimoReporte: data['ultimo_reporte'] != null
          ? (data['ultimo_reporte'] as Timestamp).toDate()
          : null,
      puntosPorLinea: Map<String, int>.from(data['puntos_por_linea'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'puntos': puntos,
      'nivel': nivel.toString(),
      'streak': streak,
      'precision': precision,
      'reportes_verificados': reportesVerificados,
      'verificaciones_hechas': verificacionesHechas,
      'seguidores': seguidores,
      'ranking': ranking,
      'ranking_linea1': rankingLinea1,
      'ranking_linea2': rankingLinea2,
      'badges': badges.map((b) => b.toFirestore()).toList(),
      'ultimo_reporte': ultimoReporte != null
          ? Timestamp.fromDate(ultimoReporte!)
          : null,
      'puntos_por_linea': puntosPorLinea,
    };
  }

  String getNivelNombre() {
    switch (nivel) {
      case UserLevel.novato:
        return '🥚 Novato del Metro';
      case UserLevel.viajeroFrecuente:
        return '🚶 Viajero Frecuente';
      case UserLevel.reporteroConfiable:
        return '🎯 Reportero Confiable';
      case UserLevel.heroeMetro:
        return '👑 Héroe del Metro';
    }
  }

  String getNivelDescripcion() {
    switch (nivel) {
      case UserLevel.novato:
        return '0-10 reportes';
      case UserLevel.viajeroFrecuente:
        return '11-50 reportes';
      case UserLevel.reporteroConfiable:
        return '51-200 reportes';
      case UserLevel.heroeMetro:
        return '201+ reportes';
    }
  }
}

