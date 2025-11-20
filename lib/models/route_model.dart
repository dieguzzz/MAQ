import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoRuta {
  optima,
  congestionada,
  interrumpida,
}

class RouteModel {
  final String origen;
  final String destino;
  final int tiempoEstimado; // en minutos
  final EstadoRuta estadoRuta;
  final DateTime actualizadoEn;

  RouteModel({
    required this.origen,
    required this.destino,
    required this.tiempoEstimado,
    this.estadoRuta = EstadoRuta.optima,
    required this.actualizadoEn,
  });

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RouteModel(
      origen: data['origen'] ?? '',
      destino: data['destino'] ?? '',
      tiempoEstimado: data['tiempo_estimado'] ?? 0,
      estadoRuta: _parseEstadoRuta(data['estado_ruta'] ?? 'optima'),
      actualizadoEn: (data['actualizado_en'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'origen': origen,
      'destino': destino,
      'tiempo_estimado': tiempoEstimado,
      'estado_ruta': _estadoToString(estadoRuta),
      'actualizado_en': Timestamp.fromDate(actualizadoEn),
    };
  }

  static EstadoRuta _parseEstadoRuta(String estado) {
    switch (estado) {
      case 'congestionada':
        return EstadoRuta.congestionada;
      case 'interrumpida':
        return EstadoRuta.interrumpida;
      default:
        return EstadoRuta.optima;
    }
  }

  static String _estadoToString(EstadoRuta estado) {
    switch (estado) {
      case EstadoRuta.congestionada:
        return 'congestionada';
      case EstadoRuta.interrumpida:
        return 'interrumpida';
      default:
        return 'optima';
    }
  }

  String getEstadoTexto() {
    switch (estadoRuta) {
      case EstadoRuta.congestionada:
        return 'Congestionada';
      case EstadoRuta.interrumpida:
        return 'Interrumpida';
      default:
        return 'Óptima';
    }
  }
}

