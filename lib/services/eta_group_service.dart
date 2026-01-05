import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eta_group_model.dart';

/// Servicio de lectura para `eta_groups`.
///
/// UI debe leer agregados (1 doc) en vez de streams grandes.
class EtaGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Observa el mejor grupo activo para la estación (elige el de mayor confidence
  /// entre los grupos recientes y no expirados).
  ///
  /// Nota: evitamos filtros con inequality (`expiresAt > now`) para no depender
  /// de índices/ordenamientos complejos; filtramos en memoria después del `limit`.
  Stream<EtaGroupModel?> watchBestActiveGroupForStation(String stationId) {
    return _firestore
        .collection('eta_groups')
        .where('stationId', isEqualTo: stationId)
        .where('status', isEqualTo: 'active')
        .orderBy('bucketStart', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final groups = snapshot.docs
          .map((d) => EtaGroupModel.fromFirestore(d))
          .where((g) => now.isBefore(g.expiresAt))
          .toList();

      if (groups.isEmpty) return null;

      groups.sort((a, b) {
        final c = b.confidence.compareTo(a.confidence);
        if (c != 0) return c;
        return b.bucketStart.compareTo(a.bucketStart);
      });

      return groups.first;
    });
  }

  /// Observa los mejores grupos activos para ambas direcciones (A y B) de una estación.
  /// Retorna un mapa con 'A' y 'B' como keys, y el mejor grupo como value (o null si no hay).
  Stream<Map<String, EtaGroupModel?>> watchActiveGroupsByDirectionForStation(String stationId) {
    return _firestore
        .collection('eta_groups')
        .where('stationId', isEqualTo: stationId)
        .where('status', isEqualTo: 'active')
        .orderBy('bucketStart', descending: true)
        .limit(20) // Más documentos porque hay dos direcciones
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final groups = snapshot.docs
          .map((d) => EtaGroupModel.fromFirestore(d))
          .where((g) => now.isBefore(g.expiresAt))
          .toList();

      // Separar por dirección
      final groupsByDirection = <String, List<EtaGroupModel>>{};
      for (final group in groups) {
        groupsByDirection.putIfAbsent(group.directionCode, () => []).add(group);
      }

      // Para cada dirección, obtener el mejor grupo (mayor confidence, más reciente)
      final result = <String, EtaGroupModel?>{'A': null, 'B': null};
      
      for (final direction in ['A', 'B']) {
        final directionGroups = groupsByDirection[direction] ?? [];
        if (directionGroups.isNotEmpty) {
          directionGroups.sort((a, b) {
            final c = b.confidence.compareTo(a.confidence);
            if (c != 0) return c;
            return b.bucketStart.compareTo(a.bucketStart);
          });
          result[direction] = directionGroups.first;
        }
      }

      return result;
    });
  }

  /// Helper para obtener el label de dirección formateado
  static String getDirectionLabel(EtaGroupModel group) {
    // Si el backend ya provee directionLabel, usarlo
    if (group.directionLabel != null && group.directionLabel!.isNotEmpty) {
      return 'Hacia ${group.directionLabel}';
    }
    
    // Fallback: generar desde directionCode y línea
    if (group.line == 'linea1') {
      return group.directionCode == 'A' 
          ? 'Hacia Villa Zaita' 
          : 'Hacia Albrook';
    } else if (group.line == 'linea2') {
      return group.directionCode == 'A'
          ? 'Hacia Nuevo Tocumen'
          : 'Hacia San Miguelito';
    }
    
    return 'Dirección ${group.directionCode}';
  }

  /// Convierte bucket ETA a minutos para UI.
  static int? etaBucketToMinutes(String? etaBucket) {
    if (etaBucket == null || etaBucket.isEmpty || etaBucket == 'unknown') {
      return null;
    }

    switch (etaBucket) {
      case '1-2':
        return 2;
      case '3-5':
        return 4;
      case '6-8':
        return 7;
      case '9+':
        return 11;
      default:
        return null;
    }
  }
}


