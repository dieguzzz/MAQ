import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoTren {
  normal,
  retrasado,
  detenido,
}

enum DireccionTren {
  norte,
  sur,
}

class TrainModel {
  final String id;
  final String linea;
  final DireccionTren direccion;
  final GeoPoint ubicacionActual;
  final double velocidad; // km/h
  final EstadoTren estado;
  final int aglomeracion; // 1-5
  final DateTime ultimaActualizacion;
  final String? confidence; // 'high'|'medium'|'low'
  final bool? isEstimated; // Si los datos son estimados

  TrainModel({
    required this.id,
    required this.linea,
    required this.direccion,
    required this.ubicacionActual,
    this.velocidad = 0.0,
    this.estado = EstadoTren.normal,
    this.aglomeracion = 1,
    required this.ultimaActualizacion,
    this.confidence,
    this.isEstimated,
  });

  factory TrainModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainModel(
      id: doc.id,
      linea: data['linea'] ?? '',
      direccion: _parseDireccion(data['direccion'] ?? 'norte'),
      ubicacionActual: data['ubicacion_actual'] as GeoPoint,
      velocidad: (data['velocidad'] ?? 0.0).toDouble(),
      estado: _parseEstadoTren(data['estado'] ?? 'normal'),
      aglomeracion: data['aglomeracion'] ?? 1,
      ultimaActualizacion: (data['ultima_actualizacion'] as Timestamp).toDate(),
      confidence: data['confidence'] as String?,
      isEstimated: data['is_estimated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'linea': linea,
      'direccion': _direccionToString(direccion),
      'ubicacion_actual': ubicacionActual,
      'velocidad': velocidad,
      'estado': _estadoToString(estado),
      'aglomeracion': aglomeracion,
      'ultima_actualizacion': Timestamp.fromDate(ultimaActualizacion),
      if (confidence != null) 'confidence': confidence,
      if (isEstimated != null) 'is_estimated': isEstimated,
    };
  }

  static DireccionTren _parseDireccion(String direccion) {
    return direccion == 'sur' ? DireccionTren.sur : DireccionTren.norte;
  }

  static String _direccionToString(DireccionTren direccion) {
    return direccion == DireccionTren.sur ? 'sur' : 'norte';
  }

  static EstadoTren _parseEstadoTren(String estado) {
    switch (estado) {
      case 'retrasado':
        return EstadoTren.retrasado;
      case 'detenido':
        return EstadoTren.detenido;
      default:
        return EstadoTren.normal;
    }
  }

  static String _estadoToString(EstadoTren estado) {
    switch (estado) {
      case EstadoTren.retrasado:
        return 'retrasado';
      case EstadoTren.detenido:
        return 'detenido';
      default:
        return 'normal';
    }
  }

  String getAglomeracionTexto() {
    switch (aglomeracion) {
      case 1:
        return 'Vacío';
      case 2:
        return 'Moderado';
      case 3:
        return 'Lleno';
      case 4:
        return 'Muy Lleno';
      case 5:
        return 'Sardina';
      default:
        return 'Desconocida';
    }
  }
}

