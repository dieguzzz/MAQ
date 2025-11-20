import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoEstacion {
  normal,
  congestionado,
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

  StationModel({
    required this.id,
    required this.nombre,
    required this.linea,
    required this.ubicacion,
    this.estadoActual = EstadoEstacion.normal,
    this.aglomeracion = 1,
    required this.ultimaActualizacion,
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
    };
  }

  static EstadoEstacion _parseEstadoEstacion(String estado) {
    switch (estado) {
      case 'congestionado':
        return EstadoEstacion.congestionado;
      case 'cerrado':
        return EstadoEstacion.cerrado;
      default:
        return EstadoEstacion.normal;
    }
  }

  static String _estadoToString(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.congestionado:
        return 'congestionado';
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

