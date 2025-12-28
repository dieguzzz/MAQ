import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../models/station_model.dart';
import '../../models/route_model.dart';
import '../../services/firebase_service.dart';
import '../../services/route_calculation_service.dart';
import '../../utils/metro_data.dart';
import '../../theme/metro_theme.dart';
import 'route_results.dart';

class RoutePlanner extends StatefulWidget {
  const RoutePlanner({super.key});

  @override
  State<RoutePlanner> createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner> {
  StationModel? _origen;
  StationModel? _destino;
  bool _isCalculating = false;

  Future<void> _calculateRoute() async {
    if (_origen == null || _destino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona origen y destino'),
        ),
      );
      return;
    }

    if (_origen!.id == _destino!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El origen y destino deben ser diferentes'),
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      // Calcular ruta (simplificado - en producción usar Cloud Functions)
      final firebaseService = FirebaseService();
      RouteModel? route = await firebaseService.getRoute(
        _origen!.id,
        _destino!.id,
      );

      // Si no existe, calcular tiempo estimado básico
      if (route == null) {
        final tiempoEstimado = _calculateEstimatedTime(_origen!, _destino!);
        route = RouteModel(
          origen: _origen!.id,
          destino: _destino!.id,
          tiempoEstimado: tiempoEstimado,
          estadoRuta: EstadoRuta.optima,
          actualizadoEn: DateTime.now(),
        );
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RouteResults(
              route: route!,
              origen: _origen!,
              destino: _destino!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al calcular ruta: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }

  int _calculateEstimatedTime(StationModel origen, StationModel destino) {
    final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
    final routeStations = RouteCalculationService.calculateRoute(
      origen,
      destino,
      metroProvider.stations,
    );
    
    int tiempoBase = RouteCalculationService.calculateEstimatedTime(routeStations);
    
    // Agregar tiempo de transbordo si hay cambio de línea
    if (origen.linea != destino.linea) {
      tiempoBase += 3; // 3 minutos adicionales por transbordo
    }
    
    return tiempoBase;
  }

  // Métodos auxiliares para ordenar estaciones
  List<StationModel> _getOrderedLinea1Stations(List<StationModel> allStations) {
    final staticStations = MetroData.getLinea1Stations();
    final orderMap = <String, int>{};
    for (int i = 0; i < staticStations.length; i++) {
      orderMap[staticStations[i].id] = i;
    }
    
    final linea1Stations = allStations.where((s) => s.linea == 'linea1').toList();
    linea1Stations.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });
    
    return linea1Stations;
  }

  List<StationModel> _getOrderedLinea2Stations(List<StationModel> allStations) {
    final staticStations = MetroData.getLinea2Stations();
    final orderMap = <String, int>{};
    for (int i = 0; i < staticStations.length; i++) {
      orderMap[staticStations[i].id] = i;
    }
    
    final linea2Stations = allStations.where((s) => s.linea == 'linea2').toList();
    
    // Separar estaciones principales de la rama del aeropuerto
    final mainLineStations = <StationModel>[];
    final airportBranchStations = <StationModel>[];
    
    for (var station in linea2Stations) {
      if (station.id == 'l2_itse' || station.id == 'l2_aeropuerto') {
        airportBranchStations.add(station);
      } else {
        mainLineStations.add(station);
      }
    }
    
    // Ordenar línea principal
    mainLineStations.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });
    
    // Ordenar rama del aeropuerto
    airportBranchStations.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });
    
    // Encontrar índice de Corredor Sur
    final corredorSurIndex = mainLineStations.indexWhere((s) => s.id == 'l2_corredor_sur');
    
    // Insertar ITSE y Aeropuerto después de Corredor Sur
    if (corredorSurIndex != -1 && airportBranchStations.isNotEmpty) {
      mainLineStations.insertAll(corredorSurIndex + 1, airportBranchStations);
    } else {
      // Si no se encuentra Corredor Sur, agregar al final
      mainLineStations.addAll(airportBranchStations);
    }
    
    return mainLineStations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificador de Rutas'),
      ),
      body: Consumer<MetroDataProvider>(
        builder: (context, metroProvider, child) {
          final stations = metroProvider.stations;
          final linea1Stations = _getOrderedLinea1Stations(stations);
          final linea2Stations = _getOrderedLinea2Stations(stations);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                Text(
                  'Planificador de Rutas',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MetroColors.grayDark,
                  ),
                ),
                const SizedBox(height: 8),
                // Descripción
                Text(
                  'Selecciona tu estación de origen y destino para calcular la mejor ruta y tiempo estimado de viaje.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MetroColors.grayDark.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Selector de origen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Origen',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Línea 1
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.train, color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Línea 1',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<StationModel>(
                                  value: _origen?.linea == 'linea1' ? _origen : null,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Selecciona estación de Línea 1',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: linea1Stations.map((station) {
                                    return DropdownMenuItem<StationModel>(
                                      value: station,
                                      child: Text(station.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (StationModel? value) {
                                    setState(() {
                                      _origen = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Línea 2
                        Card(
                          color: Colors.orange[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.train, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Línea 2',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<StationModel>(
                                  value: _origen?.linea == 'linea2' ? _origen : null,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Selecciona estación de Línea 2',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: linea2Stations.map((station) {
                                    return DropdownMenuItem<StationModel>(
                                      value: station,
                                      child: Text(station.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (StationModel? value) {
                                    setState(() {
                                      _origen = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de destino
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destino',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Línea 1
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.train, color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Línea 1',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<StationModel>(
                                  value: _destino?.linea == 'linea1' ? _destino : null,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Selecciona estación de Línea 1',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: linea1Stations.map((station) {
                                    return DropdownMenuItem<StationModel>(
                                      value: station,
                                      child: Text(station.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (StationModel? value) {
                                    setState(() {
                                      _destino = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Línea 2
                        Card(
                          color: Colors.orange[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.train, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Línea 2',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<StationModel>(
                                  value: _destino?.linea == 'linea2' ? _destino : null,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Selecciona estación de Línea 2',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: linea2Stations.map((station) {
                                    return DropdownMenuItem<StationModel>(
                                      value: station,
                                      child: Text(station.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (StationModel? value) {
                                    setState(() {
                                      _destino = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón de calcular
                ElevatedButton(
                  onPressed: _isCalculating ? null : _calculateRoute,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isCalculating
                      ? const CircularProgressIndicator()
                      : const Text('Calcular Ruta'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

