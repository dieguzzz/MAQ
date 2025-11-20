import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoReporte {
  estacion,
  tren,
}

enum CategoriaReporte {
  aglomeracion,
  retraso,
  servicioNormal,
  fallaTecnica,
}

enum EstadoReporte {
  activo,
  resuelto,
  falso,
}

class ReportModel {
  final String id;
  final String usuarioId;
  final TipoReporte tipo;
  final String objetivoId; // ID de estación o tren
  final CategoriaReporte categoria;
  final String? descripcion;
  final GeoPoint ubicacion;
  final int verificaciones;
  final EstadoReporte estado;
  final DateTime creadoEn;

  ReportModel({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.objetivoId,
    required this.categoria,
    this.descripcion,
    required this.ubicacion,
    this.verificaciones = 0,
    this.estado = EstadoReporte.activo,
    required this.creadoEn,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      usuarioId: data['usuario_id'] ?? '',
      tipo: _parseTipoReporte(data['tipo'] ?? 'estacion'),
      objetivoId: data['objetivo_id'] ?? '',
      categoria: _parseCategoria(data['categoria'] ?? 'aglomeracion'),
      descripcion: data['descripcion'],
      ubicacion: data['ubicacion'] as GeoPoint,
      verificaciones: data['verificaciones'] ?? 0,
      estado: _parseEstadoReporte(data['estado'] ?? 'activo'),
      creadoEn: (data['creado_en'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'tipo': _tipoToString(tipo),
      'objetivo_id': objetivoId,
      'categoria': _categoriaToString(categoria),
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'verificaciones': verificaciones,
      'estado': _estadoToString(estado),
      'creado_en': Timestamp.fromDate(creadoEn),
    };
  }

  static TipoReporte _parseTipoReporte(String tipo) {
    return tipo == 'tren' ? TipoReporte.tren : TipoReporte.estacion;
  }

  static String _tipoToString(TipoReporte tipo) {
    return tipo == TipoReporte.tren ? 'tren' : 'estacion';
  }

  static CategoriaReporte _parseCategoria(String categoria) {
    switch (categoria) {
      case 'retraso':
        return CategoriaReporte.retraso;
      case 'servicio_normal':
        return CategoriaReporte.servicioNormal;
      case 'falla_tecnica':
        return CategoriaReporte.fallaTecnica;
      default:
        return CategoriaReporte.aglomeracion;
    }
  }

  static String _categoriaToString(CategoriaReporte categoria) {
    switch (categoria) {
      case CategoriaReporte.retraso:
        return 'retraso';
      case CategoriaReporte.servicioNormal:
        return 'servicio_normal';
      case CategoriaReporte.fallaTecnica:
        return 'falla_tecnica';
      default:
        return 'aglomeracion';
    }
  }

  static EstadoReporte _parseEstadoReporte(String estado) {
    switch (estado) {
      case 'resuelto':
        return EstadoReporte.resuelto;
      case 'falso':
        return EstadoReporte.falso;
      default:
        return EstadoReporte.activo;
    }
  }

  static String _estadoToString(EstadoReporte estado) {
    switch (estado) {
      case EstadoReporte.resuelto:
        return 'resuelto';
      case EstadoReporte.falso:
        return 'falso';
      default:
        return 'activo';
    }
  }
}

