import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import 'map_widget.dart';
import '../../widgets/quick_report_button.dart';
import '../../widgets/custom_metro_map.dart';
import '../../widgets/ad_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCustomMap = false; // Toggle entre Google Maps y mapa personalizado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MetroPTY'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.orange[100],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Aplicación NO oficial del Metro de Panamá',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Botón para cambiar entre mapas
          IconButton(
            icon: Icon(_showCustomMap ? Icons.map : Icons.train),
            onPressed: () {
              setState(() {
                _showCustomMap = !_showCustomMap;
              });
            },
            tooltip: _showCustomMap ? 'Ver Google Maps' : 'Ver Mapa del Metro',
          ),
          Consumer<MetroDataProvider>(
            builder: (context, metroProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (String? value) {
                  metroProvider.setSelectedLinea(value);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: null,
                    child: Text('Todas las líneas'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'linea1',
                    child: Text('Línea 1'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'linea2',
                    child: Text('Línea 2'),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navegar a notificaciones
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _showCustomMap
              ? Consumer<MetroDataProvider>(
                  builder: (context, metroProvider, child) {
                    return metroProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomMetroMap(
                            stations: metroProvider.stations,
                            trains: metroProvider.trains,
                            onStationTap: (station) {
                              // Mostrar detalles de estación
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Estación: ${station.nombre}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                  },
                )
              : const MapWidget(),
              ),
              // Banner de publicidad
              const SafeArea(
                child: AdBanner(),
              ),
            ],
          ),
          const Positioned(
            bottom: 80,
            left: 20,
            child: QuickReportButton(),
          ),
          Positioned(
            bottom: 80,
            right: 8,
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return FloatingActionButton(
                  heroTag: 'locate_fab',
                  onPressed: () {
                    locationProvider.getCurrentLocation();
                  },
                  child: const Icon(Icons.my_location),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

