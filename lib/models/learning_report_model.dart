import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para reportes de aprendizaje (llegadas reales)
/// Estos reportes son diferentes de ReportModel - son específicos para enseñar al algoritmo
class LearningReportModel {
  final String id;
  final String usuarioId;
  final String estacionId;
  final String linea;
  final DateTime horaLlegadaReal;
  final int tiempoEstimadoMostrado; // minutos
  final int retrasoMinutos; // 0 si llegó a tiempo
  final bool llegadaATiempo;
  final String? razonRetraso; // opcional
  final DateTime creadoEn;
  final double
      calidadReporte; // 0.0-1.0 basado en precisión histórica del usuario

  LearningReportModel({
    required this.id,
    required this.usuarioId,
    required this.estacionId,
    required this.linea,
    required this.horaLlegadaReal,
    required this.tiempoEstimadoMostrado,
    required this.retrasoMinutos,
    required this.llegadaATiempo,
    this.razonRetraso,
    required this.creadoEn,
    this.calidadReporte = 0.5,
  });

  factory LearningReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LearningReportModel(
      id: doc.id,
      usuarioId: data['usuario_id'] ?? '',
      estacionId: data['estacion_id'] ?? '',
      linea: data['linea'] ?? '',
      horaLlegadaReal: (data['hora_llegada_real'] as Timestamp).toDate(),
      tiempoEstimadoMostrado: data['tiempo_estimado_mostrado'] ?? 0,
      retrasoMinutos: data['retraso_minutos'] ?? 0,
      llegadaATiempo: data['llegada_a_tiempo'] ?? false,
      razonRetraso: data['razon_retraso'] as String?,
      creadoEn: (data['creado_en'] as Timestamp).toDate(),
      calidadReporte: (data['calidad_reporte'] ?? 0.5).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'usuario_id': usuarioId,
      'estacion_id': estacionId,
      'linea': linea,
      'hora_llegada_real': Timestamp.fromDate(horaLlegadaReal),
      'tiempo_estimado_mostrado': tiempoEstimadoMostrado,
      'retraso_minutos': retrasoMinutos,
      'llegada_a_tiempo': llegadaATiempo,
      'razon_retraso': razonRetraso,
      'creado_en': Timestamp.fromDate(creadoEn),
      'calidad_reporte': calidadReporte,
    };
  }

  LearningReportModel copyWith({
    String? id,
    String? usuarioId,
    String? estacionId,
    String? linea,
    DateTime? horaLlegadaReal,
    int? tiempoEstimadoMostrado,
    int? retrasoMinutos,
    bool? llegadaATiempo,
    String? razonRetraso,
    DateTime? creadoEn,
    double? calidadReporte,
  }) {
    return LearningReportModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      estacionId: estacionId ?? this.estacionId,
      linea: linea ?? this.linea,
      horaLlegadaReal: horaLlegadaReal ?? this.horaLlegadaReal,
      tiempoEstimadoMostrado:
          tiempoEstimadoMostrado ?? this.tiempoEstimadoMostrado,
      retrasoMinutos: retrasoMinutos ?? this.retrasoMinutos,
      llegadaATiempo: llegadaATiempo ?? this.llegadaATiempo,
      razonRetraso: razonRetraso ?? this.razonRetraso,
      creadoEn: creadoEn ?? this.creadoEn,
      calidadReporte: calidadReporte ?? this.calidadReporte,
    );
  }
}
