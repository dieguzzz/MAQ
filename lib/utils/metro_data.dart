import '../models/station_model.dart';

/// Datos estáticos de las estaciones del Metro de Panamá
class MetroData {
  static List<StationModel> getLinea1Stations() {
    return [
      StationModel.fromStaticData(
        id: 'l1_01',
        nombre: 'San Isidro',
        linea: 'linea1',
        ubicacion: [9.0167, -79.5167],
      ),
      StationModel.fromStaticData(
        id: 'l1_02',
        nombre: 'El Ingenio',
        linea: 'linea1',
        ubicacion: [9.0180, -79.5100],
      ),
      StationModel.fromStaticData(
        id: 'l1_03',
        nombre: 'Los Andes',
        linea: 'linea1',
        ubicacion: [9.0190, -79.5050],
      ),
      StationModel.fromStaticData(
        id: 'l1_04',
        nombre: 'San Miguelito',
        linea: 'linea1',
        ubicacion: [9.0333, -79.5000],
      ),
      StationModel.fromStaticData(
        id: 'l1_05',
        nombre: 'Pedregal',
        linea: 'linea1',
        ubicacion: [9.0350, -79.4950],
      ),
      StationModel.fromStaticData(
        id: 'l1_06',
        nombre: 'Cincuentenario',
        linea: 'linea1',
        ubicacion: [9.0370, -79.4900],
      ),
      StationModel.fromStaticData(
        id: 'l1_07',
        nombre: 'Fernando de Lesseps',
        linea: 'linea1',
        ubicacion: [9.0390, -79.4850],
      ),
      StationModel.fromStaticData(
        id: 'l1_08',
        nombre: 'Vía Argentina',
        linea: 'linea1',
        ubicacion: [9.0410, -79.4800],
      ),
      StationModel.fromStaticData(
        id: 'l1_09',
        nombre: 'Iglesia del Carmen',
        linea: 'linea1',
        ubicacion: [9.0430, -79.4750],
      ),
      StationModel.fromStaticData(
        id: 'l1_10',
        nombre: '5 de Mayo',
        linea: 'linea1',
        ubicacion: [9.0450, -79.4700],
      ),
      StationModel.fromStaticData(
        id: 'l1_11',
        nombre: 'Lotería',
        linea: 'linea1',
        ubicacion: [9.0470, -79.4650],
      ),
      StationModel.fromStaticData(
        id: 'l1_12',
        nombre: 'Santo Tomás',
        linea: 'linea1',
        ubicacion: [9.0490, -79.4600],
      ),
      StationModel.fromStaticData(
        id: 'l1_13',
        nombre: 'Albrook',
        linea: 'linea1',
        ubicacion: [9.0510, -79.4550],
      ),
    ];
  }

  static List<StationModel> getLinea2Stations() {
    return [
      StationModel.fromStaticData(
        id: 'l2_01',
        nombre: 'San Miguelito',
        linea: 'linea2',
        ubicacion: [9.0333, -79.5000],
      ),
      StationModel.fromStaticData(
        id: 'l2_02',
        nombre: 'Pedregal',
        linea: 'linea2',
        ubicacion: [9.0350, -79.4950],
      ),
      StationModel.fromStaticData(
        id: 'l2_03',
        nombre: 'Cincuentenario',
        linea: 'linea2',
        ubicacion: [9.0370, -79.4900],
      ),
      StationModel.fromStaticData(
        id: 'l2_04',
        nombre: 'Fernando de Lesseps',
        linea: 'linea2',
        ubicacion: [9.0390, -79.4850],
      ),
      StationModel.fromStaticData(
        id: 'l2_05',
        nombre: 'Vía Argentina',
        linea: 'linea2',
        ubicacion: [9.0410, -79.4800],
      ),
      StationModel.fromStaticData(
        id: 'l2_06',
        nombre: 'Iglesia del Carmen',
        linea: 'linea2',
        ubicacion: [9.0430, -79.4750],
      ),
      StationModel.fromStaticData(
        id: 'l2_07',
        nombre: '5 de Mayo',
        linea: 'linea2',
        ubicacion: [9.0450, -79.4700],
      ),
      StationModel.fromStaticData(
        id: 'l2_08',
        nombre: 'Lotería',
        linea: 'linea2',
        ubicacion: [9.0470, -79.4650],
      ),
      StationModel.fromStaticData(
        id: 'l2_09',
        nombre: 'Santo Tomás',
        linea: 'linea2',
        ubicacion: [9.0490, -79.4600],
      ),
      StationModel.fromStaticData(
        id: 'l2_10',
        nombre: 'Albrook',
        linea: 'linea2',
        ubicacion: [9.0510, -79.4550],
      ),
    ];
  }

  static List<StationModel> getAllStations() {
    return [
      ...getLinea1Stations(),
      ...getLinea2Stations(),
    ];
  }
}

