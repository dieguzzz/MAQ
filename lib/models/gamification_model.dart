import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';

enum BadgeType {
  primerReporte,
  verificador,
  ojoDeAguila,
  salvavidas,
  metroMaster,
  streakSemana,
  streakMes,
  topContribuidor,
  // Badges de precisión
  francotirador,  // 95%+ precisión
  detective,      // 85%+ precisión
  observador,     // 70%+ precisión
  ojoDeAguila80,  // 80%+ precisión
  // Badges de comunidad
  ayudanteComunidad,  // 50 verificaciones
  influencerMetro,    // 100+ personas ayudadas
  // Badges de especialización
  expertoLinea1,      // 100+ reportes Línea 1
  maestroLinea2,      // 100+ reportes Línea 2
  // Badges de eventos panameños
  almaPollera,        // Reportar durante mes patrio
  reyCarnaval,        // Reportar durante carnavales
  // Badges de enseñanza
  profesorDelMetro,   // 10+ reportes de enseñanza
  // Badges de Fundador (Semana 1)
  fundador,              // Usuario de primera semana
  fundadorPlatino,       // Completó todas las misiones
  pioneroEstacion,       // Primero en reportar una estación
  mejoradorDatos,        // Subió confianza de baja a media
  confirmadorConfiable,  // 5 confirmaciones
  exploradorUrbano,      // 3 estaciones diferentes
  heroeHoraPico,         // Reportó en hora pico (7-9 AM)
  verificadorElite,      // 10 confirmaciones
  maestroL1,            // Todas estaciones L1
  maestroL2,            // Todas estaciones L2
  leyendaFundadora,     // 20 reportes en primera semana
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
  final int nivel; // Nivel 1-50
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
  final int teachingReportsCount; // Reportes de enseñanza realizados
  final int teachingScore; // Puntuación para ranking de profesores

  GamificationStats({
    this.puntos = 0,
    int? nivel,
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
    this.teachingReportsCount = 0,
    this.teachingScore = 0,
  })  : nivel = nivel ?? LevelService.calculateLevel(0),
        badges = badges ?? [],
        puntosPorLinea = puntosPorLinea ?? {};

  factory GamificationStats.fromFirestore(Map<String, dynamic> data) {
    final puntos = data['puntos'] ?? 0;
    
    // Migración: Si nivel es string (enum antiguo), calcular desde puntos
    // Si es int, usarlo directamente
    int nivelCalculado;
    if (data['nivel'] is int) {
      nivelCalculado = data['nivel'] as int;
    } else if (data['nivel'] is String) {
      // Migración desde enum antiguo - calcular desde puntos
      nivelCalculado = LevelService.calculateLevel(puntos);
    } else {
      // Calcular desde puntos si no existe
      nivelCalculado = LevelService.calculateLevel(puntos);
    }
    
    return GamificationStats(
      puntos: puntos,
      nivel: nivelCalculado,
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
      teachingReportsCount: data['teaching_reports_count'] ?? 0,
      teachingScore: data['teaching_score'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    // Recalcular nivel desde puntos para asegurar consistencia
    final nivelCalculado = LevelService.calculateLevel(puntos);
    
    return {
      'puntos': puntos,
      'nivel': nivelCalculado, // Guardar como int
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
      'teaching_reports_count': teachingReportsCount,
      'teaching_score': teachingScore,
    };
  }

  String getNivelNombre() {
    return LevelService.getLevelName(nivel);
  }

  String getNivelDescripcion() {
    return LevelService.getLevelDescription(nivel);
  }
  
  /// Obtiene el progreso hacia el siguiente nivel (0.0-1.0)
  double getProgress() {
    return LevelService.getProgress(puntos, nivel);
  }
}

