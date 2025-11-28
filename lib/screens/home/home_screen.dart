import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import 'map_widget.dart';
import '../../widgets/quick_report_button.dart';
import '../../widgets/custom_metro_map.dart';
import '../../widgets/ad_banner.dart';
import '../../services/ad_service.dart';
import '../../services/ad_session_service.dart';
import '../reports/report_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCustomMap = false; // Toggle entre Google Maps y mapa personalizado

  @override
  void initState() {
    super.initState();
    // Verificar si se debe mostrar intersticial al reabrir la app
    _checkReopenInterstitial();
  }

  Future<void> _checkReopenInterstitial() async {
    // Esperar un momento para que la UI se cargue
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final shouldShow = await AdSessionService.instance.shouldShowInterstitialOnReopen();
    if (shouldShow) {
      await AdService.instance.showInterstitialIfAppropriate(
        onAdDismissed: () {
          // Continuar normalmente
        },
      );
    }
  }

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
              final currentLinea = metroProvider.selectedLinea;
              return PopupMenuButton<String?>(
                icon: const Icon(Icons.filter_list),
                onSelected: (String? value) async {
                  // Registrar cambio de línea para anuncios inteligentes
                  final previousLine = metroProvider.selectedLinea;
                  
                  // Debug: verificar que se llamó
                  print('🔍 HomeScreen: onSelected llamado con value=$value, previousLine=$previousLine');
                  
                  // Asegurar que se establece el valor (incluso si es null)
                  metroProvider.setSelectedLinea(value);
                  
                  // Verificar que se actualizó
                  print('🔍 HomeScreen: Después de setSelectedLinea, selectedLinea=${metroProvider.selectedLinea}');
                  print('🔍 HomeScreen: Estaciones después del cambio: ${metroProvider.stations.length}');
                  
                  // Notificar cambio de línea al servicio de sesión
                  await AdSessionService.instance.onLineChanged(value);
                  
                  // Verificar si se debe mostrar intersticial (solo si cambió de línea y estuvo tiempo suficiente)
                  if (previousLine != value && previousLine != null) {
                    final shouldShow = await AdSessionService.instance.shouldShowInterstitialOnLineChange();
                    if (shouldShow && context.mounted) {
                      await AdService.instance.showInterstitialIfAppropriate(
                        onAdDismissed: () {
                          // Continuar normalmente después del anuncio
                        },
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        if (currentLinea == null)
                          const Icon(Icons.check, size: 20, color: Colors.blue)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 8),
                        const Text('Todas las líneas'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String?>(
                    value: 'linea1',
                    child: Row(
                      children: [
                        if (currentLinea == 'linea1')
                          const Icon(Icons.check, size: 20, color: Colors.blue)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 8),
                        const Text('Línea 1'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String?>(
                    value: 'linea2',
                    child: Row(
                      children: [
                        if (currentLinea == 'linea2')
                          const Icon(Icons.check, size: 20, color: Colors.blue)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 8),
                        const Text('Línea 2'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Icono de Mis Reportes
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mis Reportes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportHistoryScreen(),
                ),
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

