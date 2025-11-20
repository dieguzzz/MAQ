class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String stationsCollection = 'stations';
  static const String trainsCollection = 'trains';
  static const String reportsCollection = 'reports';
  static const String routesCollection = 'routes';

  // Reputation System
  static const int puntosPorReporteVerificado = 10;
  static const int puntosPorConfirmarReporte = 5;
  static const int puntosPorUsoConsistente = 2;
  static const int penalizacionReporteFalso = -20;

  // Location
  static const double defaultRadiusKm = 1.0; // Radio por defecto para búsquedas

  // Map
  static const double defaultZoom = 12.0;
  static const double stationZoom = 15.0;

  // Colors
  static const int primaryColorValue = 0xFF2196F3; // Azul
  static const int secondaryColorValue = 0xFFFF9800; // Naranja

  // Metro Lines
  static const String linea1 = 'linea1';
  static const String linea2 = 'linea2';
}

