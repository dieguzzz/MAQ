import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoEstacion {
  normal,
  moderado,
  lleno,
  cerrado,
}

class StationModel {
  final String id;
  final String nombre;
  final String linea;
  final GeoPoint ubicacion;
  final EstadoEstacion estadoActual;
  final int aglomeracion; // 1-5
  final DateTime ultimaActualizacion;
  final String? confidence; // 'high'|'medium'|'low'
  final bool? isEstimated; // Si los datos son estimados

  StationModel({
    required this.id,
    required this.nombre,
    required this.linea,
    required this.ubicacion,
    this.estadoActual = EstadoEstacion.normal,
    this.aglomeracion = 1,
    required this.ultimaActualizacion,
    this.confidence,
    this.isEstimated,
  });

  factory StationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StationModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      linea: data['linea'] ?? '',
      ubicacion: data['ubicacion'] as GeoPoint,
      estadoActual: _parseEstadoEstacion(data['estado_actual'] ?? 'normal'),
      aglomeracion: data['aglomeracion'] ?? 1,
      ultimaActualizacion: (data['ultima_actualizacion'] as Timestamp).toDate(),
      confidence: data['confidence'] as String?,
      isEstimated: data['is_estimated'] as bool? ?? false,
    );
  }

  factory StationModel.fromStaticData({
    required String id,
    required String nombre,
    required String linea,
    required List<double> ubicacion,
  }) {
    return StationModel(
      id: id,
      nombre: nombre,
      linea: linea,
      ubicacion: GeoPoint(ubicacion[0], ubicacion[1]),
      estadoActual: EstadoEstacion.normal,
      aglomeracion: 1,
      ultimaActualizacion: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': nombre,
      'linea': linea,
      'ubicacion': ubicacion,
      'estado_actual': _estadoToString(estadoActual),
      'aglomeracion': aglomeracion,
      'ultima_actualizacion': Timestamp.fromDate(ultimaActualizacion),
      if (confidence != null) 'confidence': confidence,
      if (isEstimated != null) 'is_estimated': isEstimated,
    };
  }

  static EstadoEstacion _parseEstadoEstacion(String estado) {
    switch (estado) {
      case 'moderado':
      case 'congestionado':
        return EstadoEstacion.moderado;
      case 'lleno':
      case 'critico':
        return EstadoEstacion.lleno;
      case 'cerrado':
        return EstadoEstacion.cerrado;
      default:
        return EstadoEstacion.normal;
    }
  }

  static String _estadoToString(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.moderado:
        return 'moderado';
      case EstadoEstacion.lleno:
        return 'lleno';
      case EstadoEstacion.cerrado:
        return 'cerrado';
      default:
        return 'normal';
    }
  }

  String getAglomeracionTexto() {
    switch (aglomeracion) {
      case 1:
        return 'Vacía';
      case 2:
        return 'Baja';
      case 3:
        return 'Media';
      case 4:
        return 'Alta';
      case 5:
        return 'Muy Alta';
      default:
        return 'Desconocida';
    }
  }
}
