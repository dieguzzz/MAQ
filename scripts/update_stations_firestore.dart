import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metropty/firebase_options.dart';

/// Script para actualizar todas las estaciones en Firestore con las coordenadas exactas
/// y eliminar documentos duplicados
/// 
/// Uso: dart run scripts/update_stations_firestore.dart

// Datos exactos de las estaciones
final Map<String, Map<String, dynamic>> stationsData = {
  // Línea 1
  'l1_albrook': {
    'id': 'l1_albrook',
    'nombre': 'Albrook',
    'linea': 'linea1',
    'lat': 8.973241195714332,
    'lng': -79.54980254173279,
  },
  'l1_5demayo': {
    'id': 'l1_5demayo',
    'nombre': '5 de Mayo',
    'linea': 'linea1',
    'lat': 8.96213183480186,
    'lng': -79.53980661928654,
  },
  'l1_loteria': {
    'id': 'l1_loteria',
    'nombre': 'Lotería',
    'linea': 'linea1',
    'lat': 8.967513186103329,
    'lng': -79.53582219779491,
  },
  'l1_santo_tomas': {
    'id': 'l1_santo_tomas',
    'nombre': 'Santo Tomás',
    'linea': 'linea1',
    'lat': 8.973220000655779,
    'lng': -79.53272726386786,
  },
  'l1_iglesia_carmen': {
    'id': 'l1_iglesia_carmen',
    'nombre': 'Iglesia del Carmen',
    'linea': 'linea1',
    'lat': 8.981927753730456,
    'lng': -79.52745974063873,
  },
  'l1_via_argentina': {
    'id': 'l1_via_argentina',
    'nombre': 'Vía Argentina',
    'linea': 'linea1',
    'lat': 8.98981336530052,
    'lng': -79.52214729040861,
  },
  'l1_fernandez_cordoba': {
    'id': 'l1_fernandez_cordoba',
    'nombre': 'Fernández de Córdoba',
    'linea': 'linea1',
    'lat': 8.996328833265732,
    'lng': -79.51964445412159,
  },
  'l1_el_ingenio': {
    'id': 'l1_el_ingenio',
    'nombre': 'El Ingenio',
    'linea': 'linea1',
    'lat': 9.007804050468373,
    'lng': -79.51892092823982,
  },
  'l1_12_octubre': {
    'id': 'l1_12_octubre',
    'nombre': '12 de Octubre',
    'linea': 'linea1',
    'lat': 9.016294410425926,
    'lng': -79.51720230281353,
  },
  'l1_pueblo_nuevo': {
    'id': 'l1_pueblo_nuevo',
    'nombre': 'Pueblo Nuevo',
    'linea': 'linea1',
    'lat': 9.023066687035316,
    'lng': -79.51264690607786,
  },
  'l1_san_miguelito': {
    'id': 'l1_san_miguelito',
    'nombre': 'San Miguelito',
    'linea': 'linea1',
    'lat': 9.029978238432253,
    'lng': -79.5061844587326,
  },
  'l1_pan_de_azucar': {
    'id': 'l1_pan_de_azucar',
    'nombre': 'Pan de Azúcar',
    'linea': 'linea1',
    'lat': 9.041112335593969,
    'lng': -79.50831983238459,
  },
  'l1_los_andes': {
    'id': 'l1_los_andes',
    'nombre': 'Los Andes',
    'linea': 'linea1',
    'lat': 9.049146644684965,
    'lng': -79.50847137719393,
  },
  'l1_san_isidro': {
    'id': 'l1_san_isidro',
    'nombre': 'San Isidro',
    'linea': 'linea1',
    'lat': 9.065018057870349,
    'lng': -79.51402623206377,
  },
  'l1_villa_zaita': {
    'id': 'l1_villa_zaita',
    'nombre': 'Villa Zaita',
    'linea': 'linea1',
    'lat': 9.079733650774982,
    'lng': -79.52711541205645,
  },
  // Línea 2
  'l2_san_miguelito': {
    'id': 'l2_san_miguelito',
    'nombre': 'San Miguelito',
    'linea': 'linea2',
    'lat': 9.030493462081608,
    'lng': -79.50519606471062,
  },
  'l2_paraiso': {
    'id': 'l2_paraiso',
    'nombre': 'Paraíso',
    'linea': 'linea2',
    'lat': 9.02978949950754,
    'lng': -79.49849590659142,
  },
  'l2_cincuentenario': {
    'id': 'l2_cincuentenario',
    'nombre': 'Cincuentenario',
    'linea': 'linea2',
    'lat': 9.030102408723574,
    'lng': -79.49148159474134,
  },
  'l2_villa_lucre': {
    'id': 'l2_villa_lucre',
    'nombre': 'Villa Lucre',
    'linea': 'linea2',
    'lat': 9.037024752017816,
    'lng': -79.48143772780895,
  },
  'l2_el_crisol': {
    'id': 'l2_el_crisol',
    'nombre': 'El Crisol',
    'linea': 'linea2',
    'lat': 9.043775779423067,
    'lng': -79.47162117809057,
  },
  'l2_brisas_golf': {
    'id': 'l2_brisas_golf',
    'nombre': 'Brisas del Golf',
    'linea': 'linea2',
    'lat': 9.049149955717043,
    'lng': -79.4590650871396,
  },
  'l2_cerro_viento': {
    'id': 'l2_cerro_viento',
    'nombre': 'Cerro Viento',
    'linea': 'linea2',
    'lat': 9.050503503082927,
    'lng': -79.45135373622179,
  },
  'l2_san_antonio': {
    'id': 'l2_san_antonio',
    'nombre': 'San Antonio',
    'linea': 'linea2',
    'lat': 9.051866647276066,
    'lng': -79.44489732384682,
  },
  'l2_pedregal': {
    'id': 'l2_pedregal',
    'nombre': 'Pedregal',
    'linea': 'linea2',
    'lat': 9.05978102130942,
    'lng': -79.42924711318817,
  },
  'l2_don_bosco': {
    'id': 'l2_don_bosco',
    'nombre': 'Don Bosco',
    'linea': 'linea2',
    'lat': 9.062991458890306,
    'lng': -79.42034639418125,
  },
  'l2_corredor_sur': {
    'id': 'l2_corredor_sur',
    'nombre': 'Corredor Sur',
    'linea': 'linea2',
    'lat': 9.068797083155014,
    'lng': -79.40713986754417,
  },
  'l2_las_mananitas': {
    'id': 'l2_las_mananitas',
    'nombre': 'Las Mañanitas',
    'linea': 'linea2',
    'lat': 9.079479054000116,
    'lng': -79.40004374831915,
  },
  'l2_hospital_este': {
    'id': 'l2_hospital_este',
    'nombre': 'Hospital del Este',
    'linea': 'linea2',
    'lat': 9.094394676685313,
    'lng': -79.39394138753414,
  },
  'l2_altos_tocumen': {
    'id': 'l2_altos_tocumen',
    'nombre': 'Altos de Tocumen',
    'linea': 'linea2',
    'lat': 9.103302767638866,
    'lng': -79.38015751540661,
  },
  'l2_24_diciembre': {
    'id': 'l2_24_diciembre',
    'nombre': '24 de Diciembre',
    'linea': 'linea2',
    'lat': 9.103358053522262,
    'lng': -79.37086164951324,
  },
  'l2_nuevo_tocumen': {
    'id': 'l2_nuevo_tocumen',
    'nombre': 'Nuevo Tocumen',
    'linea': 'linea2',
    'lat': 9.101879235961555,
    'lng': -79.35344874858856,
  },
  'l2_itse': {
    'id': 'l2_itse',
    'nombre': 'ITSE',
    'linea': 'linea2',
    'lat': 9.069297108228719,
    'lng': -79.39861995547997,
  },
  'l2_aeropuerto': {
    'id': 'l2_aeropuerto',
    'nombre': 'Aeropuerto',
    'linea': 'linea2',
    'lat': 9.065702417334673,
    'lng': -79.3895435705781,
  },
};

Future<void> main() async {
  print('🔥 Inicializando Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
    exit(1);
  }

  final firestore = FirebaseFirestore.instance;
  final stationsRef = firestore.collection('stations');

  print('\n📋 Iniciando actualización de estaciones...\n');

  try {
    // 1. Obtener todas las estaciones existentes
    print('📖 Leyendo estaciones existentes...');
    final snapshot = await stationsRef.get();
    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
    print('✅ Encontradas ${existingIds.length} estaciones existentes');

    // 2. Eliminar documentos duplicados o incorrectos
    print('\n🗑️  Eliminando documentos duplicados...');
    final idsToDelete = ['l2_san_miguelito_l1', 'l2_san_miguelito'];
    int deletedCount = 0;
    
    for (final idToDelete in idsToDelete) {
      if (existingIds.contains(idToDelete)) {
        try {
          await stationsRef.doc(idToDelete).delete();
          print('  ✅ Eliminado: $idToDelete');
          deletedCount++;
        } catch (e) {
          print('  ⚠️  Error eliminando $idToDelete: $e');
        }
      }
    }
    print('✅ Eliminados $deletedCount documentos duplicados');

    // 3. Actualizar o crear todas las estaciones con coordenadas exactas
    print('\n💾 Actualizando/creando estaciones con coordenadas exactas...');
    int updatedCount = 0;
    int createdCount = 0;

    // Usar batch para operaciones más eficientes (máximo 500 operaciones por batch)
    final batches = <WriteBatch>[];
    WriteBatch? currentBatch = firestore.batch();
    int operationsInBatch = 0;
    const maxBatchSize = 500;

    for (final entry in stationsData.entries) {
      final stationId = entry.key;
      final stationData = entry.value;

      final docRef = stationsRef.doc(stationId);
      final stationDoc = {
        'id': stationData['id'],
        'nombre': stationData['nombre'],
        'linea': stationData['linea'],
        'ubicacion': GeoPoint(stationData['lat'] as double, stationData['lng'] as double),
        'estado_actual': 'normal',
        'aglomeracion': 1,
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      };

      if (currentBatch == null || operationsInBatch >= maxBatchSize) {
        if (currentBatch != null) {
          batches.add(currentBatch);
        }
        currentBatch = firestore.batch();
        operationsInBatch = 0;
      }

      if (existingIds.contains(stationId)) {
        currentBatch!.update(docRef, stationDoc);
        updatedCount++;
      } else {
        currentBatch!.set(docRef, stationDoc);
        createdCount++;
      }
      operationsInBatch++;
    }

    // Agregar el último batch si tiene operaciones
    if (currentBatch != null && operationsInBatch > 0) {
      batches.add(currentBatch);
    }

    // Ejecutar todos los batches
    print('  📦 Ejecutando ${batches.length} batch(es)...');
    for (int i = 0; i < batches.length; i++) {
      await batches[i].commit();
      print('  ✅ Batch ${i + 1}/${batches.length} completado');
    }

    print('\n✅ Actualización completada:');
    print('   - Actualizadas: $updatedCount estaciones');
    print('   - Creadas: $createdCount estaciones');
    print('   - Eliminadas: $deletedCount estaciones duplicadas');
    print('   - Total esperado: ${stationsData.length} estaciones');

    // 4. Verificar resultado final
    print('\n🔍 Verificando resultado final...');
    final finalSnapshot = await stationsRef.get();
    final finalIds = finalSnapshot.docs.map((doc) => doc.id).toSet();
    print('✅ Total de estaciones en Firestore: ${finalIds.length}');

    // Verificar que no haya San Miguelitos duplicados
    final sanMiguelitoStations = finalIds.where((id) => 
      id.contains('san_miguelito')
    ).toList();
    print('📊 Estaciones San Miguelito encontradas: ${sanMiguelitoStations.length}');
    for (final id in sanMiguelitoStations) {
      print('   - $id');
    }

    if (sanMiguelitoStations.length == 2) {
      print('✅ Correcto: Solo hay 2 San Miguelito (uno por línea)');
    } else {
      print('⚠️  Advertencia: Se encontraron ${sanMiguelitoStations.length} San Miguelito');
    }

    print('\n🎉 ¡Script completado exitosamente!');
  } catch (e, stackTrace) {
    print('\n❌ Error ejecutando script: $e');
    print('📍 Stack trace: $stackTrace');
    exit(1);
  }
}

