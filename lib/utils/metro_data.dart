import '../models/station_model.dart';

/// Datos estáticos de las estaciones del Metro de Panamá
class MetroData {
  static List<StationModel> getLinea1Stations() {
    return _buildStations(_linea1Data, 'linea1');
  }

  static List<StationModel> getLinea2Stations() {
    return _buildStations(_linea2Data, 'linea2');
  }

  static List<StationModel> getAllStations() {
    return [
      ...getLinea1Stations(),
      ...getLinea2Stations(),
    ];
  }

  static List<StationModel> _buildStations(
    List<Map<String, dynamic>> data,
    String linea,
  ) {
    return data
        .map(
          (station) => StationModel.fromStaticData(
            id: station['id'] as String,
            nombre: station['nombre'] as String,
            linea: linea,
            ubicacion: [
              station['lat'] as double,
              station['lng'] as double,
            ],
          ),
        )
        .toList();
  }

  static const List<Map<String, dynamic>> _linea1Data = [
    {
      'id': 'l1_albrook',
      'nombre': 'Albrook',
      'lat': 8.97284310180716,
      'lng': -79.5496043881889,
    },
    {
      'id': 'l1_5demayo',
      'nombre': '5 de Mayo',
      'lat': 8.962787564477963,
      'lng': -79.53936824901903,
    },
    {
      'id': 'l1_loteria',
      'nombre': 'Lotería',
      'lat': 8.96767416101452,
      'lng': -79.53571022099202,
    },
    {
      'id': 'l1_santo_tomas',
      'nombre': 'Santo Tomás',
      'lat': 8.973467317003253,
      'lng': -79.52874712018835,
    },
    {
      'id': 'l1_iglesia_carmen',
      'nombre': 'Iglesia del Carmen',
      'lat': 8.980654764221373,
      'lng': -79.5278837783544,
    },
    {
      'id': 'l1_via_argentina',
      'nombre': 'Vía Argentina',
      'lat': 8.99014721115551,
      'lng': -79.52216691134721,
    },
    {
      'id': 'l1_fernandez_cordoba',
      'nombre': 'Fernández de Córdoba',
      'lat': 8.996651415421606,
      'lng': -79.51963261833278,
    },
    {
      'id': 'l1_el_ingenio',
      'nombre': 'El Ingenio',
      'lat': 9.006228801818388,
      'lng': -79.5097027831871,
    },
    {
      'id': 'l1_12_octubre',
      'nombre': '12 de Octubre',
      'lat': 9.01645876807501,
      'lng': -79.51734916621125,
    },
    {
      'id': 'l1_pueblo_nuevo',
      'nombre': 'Pueblo Nuevo',
      'lat': 9.023375942272808,
      'lng': -79.52155560131094,
    },
    {
      'id': 'l1_san_miguelito',
      'nombre': 'San Miguelito',
      'lat': 9.03013288450882,
      'lng': -79.50512601807982,
    },
    {
      'id': 'l1_pan_de_azucar',
      'nombre': 'Pan de Azúcar',
      'lat': 9.04015281060091,
      'lng': -79.50835923099005,
    },
    {
      'id': 'l1_los_andes',
      'nombre': 'Los Andes',
      'lat': 9.049336711106003,
      'lng': -79.50857162203218,
    },
    {
      'id': 'l1_san_isidro',
      'nombre': 'San Isidro',
      'lat': 9.056456951868949,
      'lng': -79.51400387959937,
    },
    {
      'id': 'l1_villa_zaita',
      'nombre': 'Villa Zaita',
      'lat': 9.079950770875326,
      'lng': -79.52720011166313,
    },
  ];

  static const List<Map<String, dynamic>> _linea2Data = [
    {
      'id': 'l2_san_miguelito_l1',
      'nombre': 'San Miguelito L1',
      'lat': 9.03009380657719,
      'lng': -79.50647483201674,
    },
    {
      'id': 'l2_san_miguelito',
      'nombre': 'San Miguelito',
      'lat': 9.03086218473252,
      'lng': -79.50989920880371,
    },
    {
      'id': 'l2_paraiso',
      'nombre': 'Paraíso',
      'lat': 9.030210453957453,
      'lng': -79.49884089156642,
    },
    {
      'id': 'l2_cincuentenario',
      'nombre': 'Cincuentenario',
      'lat': 9.030229727208727,
      'lng': -79.49105544000972,
    },
    {
      'id': 'l2_villa_lucre',
      'nombre': 'Villa Lucre',
      'lat': 9.037265500973115,
      'lng': -79.47913201610893,
    },
    {
      'id': 'l2_el_crisol',
      'nombre': 'El Crisol',
      'lat': 9.044060420725547,
      'lng': -79.47163384899839,
    },
    {
      'id': 'l2_brisas_golf',
      'nombre': 'Brisas del Golf',
      'lat': 9.049367609139999,
      'lng': -79.45894593983058,
    },
    {
      'id': 'l2_cerro_viento',
      'nombre': 'Cerro Viento',
      'lat': 9.05076761569645,
      'lng': -79.45131544891289,
    },
    {
      'id': 'l2_san_antonio',
      'nombre': 'San Antonio',
      'lat': 9.051932241357573,
      'lng': -79.44493340930068,
    },
    {
      'id': 'l2_pedregal',
      'nombre': 'Pedregal',
      'lat': 9.05978102130942,
      'lng': -79.42924711318817,
    },
    {
      'id': 'l2_don_bosco',
      'nombre': 'Don Bosco',
      'lat': 9.063172165893324,
      'lng': -79.40837840211105,
    },
    {
      'id': 'l2_corredor_sur',
      'nombre': 'Corredor Sur',
      'lat': 9.06834792220958,
      'lng': -79.39907529912155,
    },
    {
      'id': 'l2_las_mananitas',
      'nombre': 'Las Mañanitas',
      'lat': 9.074448454404435,
      'lng': -79.401046684207,
    },
    {
      'id': 'l2_hospital_este',
      'nombre': 'Hospital del Este',
      'lat': 9.09241880557992,
      'lng': -79.39394080945683,
    },
    {
      'id': 'l2_altos_tocumen',
      'nombre': 'Altos de Tocumen',
      'lat': 9.10345698031293,
      'lng': -79.383004946405,
    },
    {
      'id': 'l2_24_diciembre',
      'nombre': '24 de Diciembre',
      'lat': 9.103428018526477,
      'lng': -79.3708788214515,
    },
    {
      'id': 'l2_nuevo_tocumen',
      'nombre': 'Nuevo Tocumen',
      'lat': 9.105219123775048,
      'lng': -79.35304416254755,
    },
    {
      'id': 'l2_itse',
      'nombre': 'ITSE',
      'lat': 9.112985332,
      'lng': -79.338041025,
    },
    {
      'id': 'l2_aeropuerto',
      'nombre': 'Aeropuerto',
      'lat': 9.066095855824978,
      'lng': -79.38960768088664,
    },
  ];
}

