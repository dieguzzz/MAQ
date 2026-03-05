import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../models/station_model.dart';
import '../../models/route_model.dart';
import '../../services/core/firebase_service.dart';
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
    // Cálculo simplificado: asumir 2 minutos por estación
    // En producción, esto debería calcularse con Cloud Functions
    // considerando el estado actual del sistema
    return 15; // minutos estimados
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        const SizedBox(height: 8),
                        DropdownButtonFormField<StationModel>(
                          initialValue: _origen,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Selecciona estación de origen',
                          ),
                          items: stations.map((station) {
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
                        const SizedBox(height: 8),
                        DropdownButtonFormField<StationModel>(
                          initialValue: _destino,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Selecciona estación de destino',
                          ),
                          items: stations.map((station) {
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
