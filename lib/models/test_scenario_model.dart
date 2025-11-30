/// Modelo para escenarios de prueba predefinidos
class TestScenario {
  final String id;
  final String nombre;
  final String estacionId;
  final DateTime hora;
  final int tiempoEstimadoMostrado; // minutos
  final int retrasoMinutos;
  final String aprendizajeEsperado;

  TestScenario({
    required this.id,
    required this.nombre,
    required this.estacionId,
    required this.hora,
    required this.tiempoEstimadoMostrado,
    required this.retrasoMinutos,
    required this.aprendizajeEsperado,
  });
}

/// Escenarios de prueba predefinidos
class TestScenarios {
  // Datos base de escenarios (sin DateTime para poder ser const)
  static const Map<String, Map<String, dynamic>> _scenarioData = {
    'hora_pico_con_retraso': {
      'id': 'hora_pico_con_retraso',
      'nombre': 'Hora Pico con Retraso',
      'estacionId': 'estacion_5_de_mayo', // Ajustar según IDs reales
      'hour': 8,
      'minute': 30,
      'tiempoEstimadoMostrado': 4,
      'retrasoMinutos': 8,
      'aprendizajeEsperado': 'Aprender que hora pico tiene +4 min extra',
    },
    'hora_valle_puntual': {
      'id': 'hora_valle_puntual',
      'nombre': 'Hora Valle Puntual',
      'estacionId': 'estacion_via_argentina', // Ajustar según IDs reales
      'hour': 14,
      'minute': 0,
      'tiempoEstimadoMostrado': 6,
      'retrasoMinutos': 0,
      'aprendizajeEsperado': 'Confirmar que hora valle es precisa',
    },
    'problema_cronico_estacion': {
      'id': 'problema_cronico_estacion',
      'nombre': 'Problema Crónico en Estación',
      'estacionId': 'estacion_san_miguelito', // Ajustar según IDs reales
      'hour': 17,
      'minute': 30,
      'tiempoEstimadoMostrado': 5,
      'retrasoMinutos': 15,
      'aprendizajeEsperado': 'Detectar estación problemática en hora pico',
    },
  };

  /// Obtiene un escenario por ID con hora actualizada
  static TestScenario? getScenario(String scenarioId) {
    final data = _scenarioData[scenarioId];
    if (data == null) return null;

    final now = DateTime.now();
    final hora = DateTime(
      now.year,
      now.month,
      now.day,
      data['hour'] as int,
      data['minute'] as int,
    );

    return TestScenario(
      id: data['id'] as String,
      nombre: data['nombre'] as String,
      estacionId: data['estacionId'] as String,
      hora: hora,
      tiempoEstimadoMostrado: data['tiempoEstimadoMostrado'] as int,
      retrasoMinutos: data['retrasoMinutos'] as int,
      aprendizajeEsperado: data['aprendizajeEsperado'] as String,
    );
  }

  /// Obtiene todos los escenarios disponibles
  static List<TestScenario> getAllScenarios() {
    return _scenarioData.keys
        .map((id) => getScenario(id))
        .whereType<TestScenario>()
        .toList();
  }

  /// Obtiene todos los IDs de escenarios disponibles
  static List<String> getAllScenarioIds() {
    return _scenarioData.keys.toList();
  }
}

