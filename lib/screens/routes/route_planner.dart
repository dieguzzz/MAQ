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
  late PageController _pageController;
  int _currentStep = 0;
  String? _selectedOrigenLinea;
  String? _selectedDestinoLinea;
  StationModel? _origen;
  StationModel? _destino;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectOrigenLinea(String linea) {
    setState(() {
      _selectedOrigenLinea = linea;
      _origen = null; // Resetear estación cuando cambia la línea
    });
    _nextStep();
  }

  void _selectDestinoLinea(String linea) {
    setState(() {
      _selectedDestinoLinea = linea;
      _destino = null; // Resetear estación cuando cambia la línea
    });
    _nextStep();
  }

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
      final firebaseService = FirebaseService();
      RouteModel? route = await firebaseService.getRoute(
        _origen!.id,
        _destino!.id,
      );

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
    final metroProvider =
        Provider.of<MetroDataProvider>(context, listen: false);
    final routeStations = RouteCalculationService.calculateRoute(
      origen,
      destino,
      metroProvider.stations,
    );

    int tiempoBase =
        RouteCalculationService.calculateEstimatedTime(routeStations);

    if (origen.linea != destino.linea) {
      tiempoBase += 3;
    }

    return tiempoBase;
  }

  List<StationModel> _getOrderedLinea1Stations(List<StationModel> allStations) {
    final staticStations = MetroData.getLinea1Stations();
    final orderMap = <String, int>{};
    for (int i = 0; i < staticStations.length; i++) {
      orderMap[staticStations[i].id] = i;
    }

    final linea1Stations =
        allStations.where((s) => s.linea == 'linea1').toList();
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

    final linea2Stations =
        allStations.where((s) => s.linea == 'linea2').toList();

    final mainLineStations = <StationModel>[];
    final airportBranchStations = <StationModel>[];

    for (var station in linea2Stations) {
      if (station.id == 'l2_itse' || station.id == 'l2_aeropuerto') {
        airportBranchStations.add(station);
      } else {
        mainLineStations.add(station);
      }
    }

    mainLineStations.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    airportBranchStations.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    final corredorSurIndex =
        mainLineStations.indexWhere((s) => s.id == 'l2_corredor_sur');

    if (corredorSurIndex != -1 && airportBranchStations.isNotEmpty) {
      mainLineStations.insertAll(corredorSurIndex + 1, airportBranchStations);
    } else {
      mainLineStations.addAll(airportBranchStations);
    }

    return mainLineStations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MetroDataProvider>(
        builder: (context, metroProvider, child) {
          final stations = metroProvider.stations;
          final linea1Stations = _getOrderedLinea1Stations(stations);
          final linea2Stations = _getOrderedLinea2Stations(stations);

          return Column(
            children: [
              // Título y descripción centrados
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  children: [
                    Text(
                      'Planificador de Rutas',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: MetroColors.grayDark,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona tu estación de origen y destino para calcular la mejor ruta y tiempo estimado de viaje.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MetroColors.grayDark.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),

              // PageView con pasos del formulario
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Deshabilitar swipe
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    // Paso 0: Seleccionar línea de origen
                    _buildLineSelectionStep(
                      title: 'Selecciona la línea de origen',
                      onLineSelected: _selectOrigenLinea,
                    ),

                    // Paso 1: Seleccionar estación de origen
                    _buildStationSelectionStep(
                      title: 'Selecciona la estación de origen',
                      selectedLinea: _selectedOrigenLinea,
                      selectedStation: _origen,
                      onStationSelected: (station) {
                        setState(() {
                          _origen = station;
                        });
                      },
                      linea1Stations: linea1Stations,
                      linea2Stations: linea2Stations,
                      showOrigen: true,
                      showDestino: false,
                    ),

                    // Paso 2: Seleccionar línea de destino
                    _buildLineSelectionStep(
                      title: 'Selecciona la línea de destino',
                      onLineSelected: _selectDestinoLinea,
                    ),

                    // Paso 3: Seleccionar estación de destino
                    _buildStationSelectionStep(
                      title: 'Selecciona la estación de destino',
                      selectedLinea: _selectedDestinoLinea,
                      selectedStation: _destino,
                      onStationSelected: (station) {
                        setState(() {
                          _destino = station;
                        });
                      },
                      linea1Stations: linea1Stations,
                      linea2Stations: linea2Stations,
                      showOrigen: true,
                      showDestino: true,
                    ),
                  ],
                ),
              ),

              // Botones de navegación
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Atrás'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: _currentStep > 0 ? 1 : 1,
                      child: _currentStep == 3
                          ? ElevatedButton(
                              onPressed: (_destino == null || _isCalculating)
                                  ? null
                                  : _calculateRoute,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isCalculating
                                  ? const CircularProgressIndicator()
                                  : const Text('Calcular Ruta'),
                            )
                          : ElevatedButton(
                              onPressed: (_currentStep == 1 &&
                                          _origen == null) ||
                                      (_currentStep == 3 && _destino == null)
                                  ? null
                                  : _nextStep,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Siguiente'),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLineSelectionStep({
    required String title,
    required Function(String) onLineSelected,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Botón Línea 1
          Card(
            child: InkWell(
              onTap: () => onLineSelected('linea1'),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: MetroColors.linea1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: MetroColors.linea1,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.train,
                        color: MetroColors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Línea 1',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: MetroColors.linea1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Albrook → Villa Zaita',
                            style: TextStyle(
                              fontSize: 14,
                              color: MetroColors.linea1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: MetroColors.linea1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón Línea 2
          Card(
            child: InkWell(
              onTap: () => onLineSelected('linea2'),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: MetroColors.linea2.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: MetroColors.linea2,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.train,
                        color: MetroColors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Línea 2',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: MetroColors.linea2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'San Miguelito → Nuevo Tocumen',
                            style: TextStyle(
                              fontSize: 14,
                              color: MetroColors.linea2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: MetroColors.linea2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSelectionStep({
    required String title,
    required String? selectedLinea,
    required StationModel? selectedStation,
    required Function(StationModel) onStationSelected,
    required List<StationModel> linea1Stations,
    required List<StationModel> linea2Stations,
    required bool showOrigen,
    required bool showDestino,
  }) {
    final stations =
        selectedLinea == 'linea1' ? linea1Stations : linea2Stations;
    final lineColor =
        selectedLinea == 'linea1' ? MetroColors.linea1 : MetroColors.linea2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Resumen lado a lado (origen y destino)
          Row(
            children: [
              // Origen (izquierda)
              Expanded(
                child: Card(
                  color: showOrigen
                      ? lineColor.withValues(alpha: 0.08)
                      : MetroColors.grayLight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.radio_button_checked,
                              color: showOrigen
                                  ? lineColor
                                  : MetroColors.grayMedium,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Origen',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: showOrigen
                                    ? lineColor
                                    : MetroColors.grayMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedOrigenLinea != null) ...[
                          Text(
                            _selectedOrigenLinea == 'linea1'
                                ? 'Línea 1'
                                : 'Línea 2',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: showOrigen
                                  ? lineColor
                                  : MetroColors.grayMedium,
                            ),
                          ),
                          if (_origen != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _origen!.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: showOrigen
                                    ? MetroColors.grayDark
                                    : MetroColors.grayMedium,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              'No seleccionada',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    MetroColors.grayDark.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            'No seleccionada',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  MetroColors.grayDark.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Destino (derecha)
              Expanded(
                child: Card(
                  color: showDestino
                      ? lineColor.withValues(alpha: 0.08)
                      : MetroColors.grayLight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.place,
                              color: showDestino
                                  ? lineColor
                                  : MetroColors.grayMedium,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Destino',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: showDestino
                                    ? lineColor
                                    : MetroColors.grayMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedDestinoLinea != null) ...[
                          Text(
                            _selectedDestinoLinea == 'linea1'
                                ? 'Línea 1'
                                : 'Línea 2',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: showDestino
                                  ? lineColor
                                  : MetroColors.grayMedium,
                            ),
                          ),
                          if (_destino != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _destino!.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: showDestino
                                    ? MetroColors.grayDark
                                    : MetroColors.grayMedium,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              'No seleccionada',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    MetroColors.grayDark.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            'No seleccionada',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  MetroColors.grayDark.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Selector de estación
          if (selectedLinea != null) ...[
            Card(
              color: lineColor.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.train, color: lineColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          selectedLinea == 'linea1' ? 'Línea 1' : 'Línea 2',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: lineColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<StationModel>(
                      initialValue: selectedStation,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Selecciona una estación',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        filled: true,
                        fillColor: MetroColors.white,
                      ),
                      isExpanded: true,
                      items: stations.map((station) {
                        return DropdownMenuItem<StationModel>(
                          value: station,
                          child: Text(station.nombre),
                        );
                      }).toList(),
                      onChanged: (StationModel? value) {
                        if (value != null) {
                          onStationSelected(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
