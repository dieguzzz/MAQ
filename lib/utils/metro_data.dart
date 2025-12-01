import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';

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

  static List<TrainModel> getSampleTrains() {
    final now = DateTime.now();
    return [
      // Línea 1 - 3 trenes de ida (norte) y 3 de regreso (sur)
      // Trenes de ida (norte)
      TrainModel(
        id: 'train_l1_norte_1',
        linea: 'linea1',
        direccion: DireccionTren.norte,
        ubicacionActual: const GeoPoint(8.9755, -79.5330),
        velocidad: 40,
        estado: EstadoTren.normal,
        aglomeracion: 2,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l1_norte_2',
        linea: 'linea1',
        direccion: DireccionTren.norte,
        ubicacionActual: const GeoPoint(9.0062, -79.5097),
        velocidad: 38,
        estado: EstadoTren.normal,
        aglomeracion: 3,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l1_norte_3',
        linea: 'linea1',
        direccion: DireccionTren.norte,
        ubicacionActual: const GeoPoint(9.0405, -79.5070),
        velocidad: 42,
        estado: EstadoTren.normal,
        aglomeracion: 2,
        ultimaActualizacion: now,
      ),
      // Trenes de regreso (sur)
      TrainModel(
        id: 'train_l1_sur_1',
        linea: 'linea1',
        direccion: DireccionTren.sur,
        ubicacionActual: const GeoPoint(9.0799, -79.5272),
        velocidad: 39,
        estado: EstadoTren.normal,
        aglomeracion: 3,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l1_sur_2',
        linea: 'linea1',
        direccion: DireccionTren.sur,
        ubicacionActual: const GeoPoint(9.0301, -79.5051),
        velocidad: 37,
        estado: EstadoTren.normal,
        aglomeracion: 2,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l1_sur_3',
        linea: 'linea1',
        direccion: DireccionTren.sur,
        ubicacionActual: const GeoPoint(8.9901, -79.5222),
        velocidad: 41,
        estado: EstadoTren.normal,
        aglomeracion: 4,
        ultimaActualizacion: now,
      ),
      // Línea 2 - 3 trenes de ida (norte) y 3 de regreso (sur)
      // Trenes de ida (norte)
      TrainModel(
        id: 'train_l2_norte_1',
        linea: 'linea2',
        direccion: DireccionTren.norte,
        ubicacionActual: const GeoPoint(9.0301, -79.5065),
        velocidad: 40,
        estado: EstadoTren.normal,
        aglomeracion: 2,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l2_norte_2',
        linea: 'linea2',
        direccion: DireccionTren.norte,
        ubicacionActual: const GeoPoint(9.0440, -79.4710),
        velocidad: 38,
        estado: EstadoTren.normal,
        aglomeracion: 3,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l2_norte_3',
        linea: 'linea2',
        direccion: DireccionTren.norte,
        ubicacionActual: const GeoPoint(9.0598, -79.4292),
        velocidad: 42,
        estado: EstadoTren.normal,
        aglomeracion: 2,
        ultimaActualizacion: now,
      ),
      // Trenes de regreso (sur)
      TrainModel(
        id: 'train_l2_sur_1',
        linea: 'linea2',
        direccion: DireccionTren.sur,
        ubicacionActual: const GeoPoint(9.1129, -79.3380),
        velocidad: 39,
        estado: EstadoTren.normal,
        aglomeracion: 3,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l2_sur_2',
        linea: 'linea2',
        direccion: DireccionTren.sur,
        ubicacionActual: const GeoPoint(9.0744, -79.4010),
        velocidad: 37,
        estado: EstadoTren.normal,
        aglomeracion: 2,
        ultimaActualizacion: now,
      ),
      TrainModel(
        id: 'train_l2_sur_3',
        linea: 'linea2',
        direccion: DireccionTren.sur,
        ubicacionActual: const GeoPoint(9.0519, -79.4449),
        velocidad: 41,
        estado: EstadoTren.normal,
        aglomeracion: 4,
        ultimaActualizacion: now,
      ),
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
    // Orden: Albrook es el inicio, Villa Zaita se conecta con San Isidro
    {
      'id': 'l1_albrook',
      'nombre': 'Albrook',
      'lat': 8.973241195714332,
      'lng': -79.54980254173279,
    },
    {
      'id': 'l1_5demayo',
      'nombre': '5 de Mayo',
      'lat': 8.96213183480186,
      'lng': -79.53980661928654,
    },
    {
      'id': 'l1_loteria',
      'nombre': 'Lotería',
      'lat': 8.967513186103329,
      'lng': -79.53582219779491,
    },
    {
      'id': 'l1_santo_tomas',
      'nombre': 'Santo Tomás',
      'lat': 8.973220000655779,
      'lng': -79.53272726386786,
    },
    {
      'id': 'l1_iglesia_carmen',
      'nombre': 'Iglesia del Carmen',
      'lat': 8.981927753730456,
      'lng': -79.52745974063873,
    },
    {
      'id': 'l1_via_argentina',
      'nombre': 'Vía Argentina',
      'lat': 8.98981336530052,
      'lng': -79.52214729040861,
    },
    {
      'id': 'l1_fernandez_cordoba',
      'nombre': 'Fernández de Córdoba',
      'lat': 8.996328833265732,
      'lng': -79.51964445412159,
    },
    {
      'id': 'l1_el_ingenio',
      'nombre': 'El Ingenio',
      'lat': 9.007804050468373,
      'lng': -79.51892092823982,
    },
    {
      'id': 'l1_12_octubre',
      'nombre': '12 de Octubre',
      'lat': 9.016294410425926,
      'lng': -79.51720230281353,
    },
    {
      'id': 'l1_pueblo_nuevo',
      'nombre': 'Pueblo Nuevo',
      'lat': 9.023066687035316,
      'lng': -79.51264690607786,
    },
    {
      'id': 'l1_san_miguelito',
      'nombre': 'San Miguelito',
      'lat': 9.029978238432253,
      'lng': -79.5061844587326,
    },
    {
      'id': 'l1_pan_de_azucar',
      'nombre': 'Pan de Azúcar',
      'lat': 9.041112335593969,
      'lng': -79.50831983238459,
    },
    {
      'id': 'l1_los_andes',
      'nombre': 'Los Andes',
      'lat': 9.049146644684965,
      'lng': -79.50847137719393,
    },
    {
      'id': 'l1_san_isidro',
      'nombre': 'San Isidro',
      'lat': 9.065018057870349,
      'lng': -79.51402623206377,
    },
    {
      'id': 'l1_villa_zaita',
      'nombre': 'Villa Zaita',
      'lat': 9.079733650774982,
      'lng': -79.52711541205645,
    },
  ];

  static const List<Map<String, dynamic>> _linea2Data = [
    // Orden de sur a norte (línea principal)
    {
      'id': 'l2_paraiso',
      'nombre': 'Paraíso',
      'lat': 9.02978949950754,
      'lng': -79.49849590659142,
    },
    {
      'id': 'l2_cincuentenario',
      'nombre': 'Cincuentenario',
      'lat': 9.030102408723574,
      'lng': -79.49148159474134,
    },
    {
      'id': 'l2_villa_lucre',
      'nombre': 'Villa Lucre',
      'lat': 9.037024752017816,
      'lng': -79.48143772780895,
    },
    {
      'id': 'l2_el_crisol',
      'nombre': 'El Crisol',
      'lat': 9.043775779423067,
      'lng': -79.47162117809057,
    },
    {
      'id': 'l2_brisas_golf',
      'nombre': 'Brisas del Golf',
      'lat': 9.049149955717043,
      'lng': -79.4590650871396,
    },
    {
      'id': 'l2_cerro_viento',
      'nombre': 'Cerro Viento',
      'lat': 9.050503503082927,
      'lng': -79.45135373622179,
    },
    {
      'id': 'l2_san_antonio',
      'nombre': 'San Antonio',
      'lat': 9.051866647276066,
      'lng': -79.44489732384682,
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
      'lat': 9.062991458890306,
      'lng': -79.42034639418125,
    },
    {
      'id': 'l2_corredor_sur',
      'nombre': 'Corredor Sur',
      'lat': 9.068797083155014,
      'lng': -79.40713986754417,
    },
    {
      'id': 'l2_las_mananitas',
      'nombre': 'Las Mañanitas',
      'lat': 9.079479054000116,
      'lng': -79.40004374831915,
    },
    {
      'id': 'l2_hospital_este',
      'nombre': 'Hospital del Este',
      'lat': 9.094394676685313,
      'lng': -79.39394138753414,
    },
    {
      'id': 'l2_altos_tocumen',
      'nombre': 'Altos de Tocumen',
      'lat': 9.103302767638866,
      'lng': -79.38015751540661,
    },
    {
      'id': 'l2_24_diciembre',
      'nombre': '24 de Diciembre',
      'lat': 9.103358053522262,
      'lng': -79.37086164951324,
    },
    {
      'id': 'l2_nuevo_tocumen',
      'nombre': 'Nuevo Tocumen',
      'lat': 9.101879235961555,
      'lng': -79.35344874858856,
    },
    // Rama del aeropuerto: Corredor Sur se conecta con ITSE y Las Mañanitas
    {
      'id': 'l2_itse',
      'nombre': 'ITSE',
      'lat': 9.069297108228719,
      'lng': -79.39861995547997,
    },
    {
      'id': 'l2_aeropuerto',
      'nombre': 'Aeropuerto',
      'lat': 9.065702417334673,
      'lng': -79.3895435705781,
    },
  ];
}

