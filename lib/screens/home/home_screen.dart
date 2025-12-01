import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_mode_service.dart';
import 'map_widget.dart';
import '../../widgets/quick_report_button.dart';
import '../../widgets/custom_metro_map.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/simulated_clock_widget.dart';
import '../../services/simulated_time_service.dart';
import '../../services/ad_service.dart';
import '../../services/ad_session_service.dart';
import '../reports/report_history_screen.dart';
import '../admin/learning_admin_panel.dart';
import '../admin/learning_demo_panel.dart';
import '../../services/station_edit_mode_service.dart';

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
    // Verificar modo test cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTestMode();
    });
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

  Future<void> _showModeDialog(BuildContext context, AppMode currentMode, String userId) async {
    final newMode = await showDialog<AppMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modo de Aplicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppMode>(
              title: const Text('Desarrollo'),
              subtitle: const Text('Versión oficial con todas las validaciones'),
              value: AppMode.development,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop(value);
                }
              },
            ),
            RadioListTile<AppMode>(
              title: const Text('Test'),
              subtitle: const Text('Permite reportar desde cualquier ubicación'),
              value: AppMode.test,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop(value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (newMode != null && newMode != currentMode && context.mounted) {
      try {
        await AppModeService().setMode(userId, newMode);
        // Actualizar MetroDataProvider con el nuevo modo
        final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
        metroProvider.setTestMode(newMode == AppMode.test);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Modo cambiado a: ${newMode == AppMode.test ? "Test" : "Desarrollo"}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cambiar modo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _checkTestMode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
      await metroProvider.checkTestMode(user.uid);
      
      // Verificar si estamos en modo test e iniciar tiempo simulado
      final appModeService = AppModeService();
      final isTestMode = await appModeService.isTestMode(user.uid);
      final simulatedTimeService = SimulatedTimeService();
      if (isTestMode) {
        simulatedTimeService.start();
      } else {
        simulatedTimeService.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('MetroPTY'),
            const SizedBox(width: 8),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                if (user == null) return const SizedBox.shrink();
                
                return StreamBuilder<AppMode>(
                  stream: AppModeService().watchMode(user.uid),
                  builder: (context, snapshot) {
                    final mode = snapshot.data ?? AppMode.development;
                    // Actualizar MetroDataProvider y tiempo simulado cuando cambie el modo
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
                      metroProvider.setTestMode(mode == AppMode.test);
                      
                      // Iniciar/detener tiempo simulado según el modo
                      final simulatedTimeService = SimulatedTimeService();
                      if (mode == AppMode.test) {
                        simulatedTimeService.start();
                      } else {
                        simulatedTimeService.stop();
                      }
                    });
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showModeDialog(context, mode, user.uid),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: mode == AppMode.test ? Colors.orange : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mode == AppMode.test ? Icons.bug_report : Icons.code,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  mode == AppMode.test ? 'TEST' : 'DEV',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (mode == AppMode.test) ...[
                          const SizedBox(width: 8),
                          const SimulatedClockWidget(),
                          const SizedBox(width: 8),
                          // Botón para activar/desactivar modo de edición de estaciones
                          Consumer<StationEditModeService>(
                            builder: (context, editModeService, child) {
                              final isEditModeActive = editModeService.isEditModeActive;
                              return GestureDetector(
                                onTap: () {
                                  editModeService.toggle();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditModeActive
                                            ? 'Modo edición desactivado'
                                            : 'Modo edición activado - Toca y arrastra estaciones',
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: isEditModeActive ? Colors.grey : Colors.blue,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isEditModeActive ? Colors.blue : Colors.grey[600],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '📍',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'EDIT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LearningAdminPanel(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '🧪',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LearningDemoPanel(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '📊',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LEARNING',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
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
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (String value) async {
                  // Registrar cambio de línea para anuncios inteligentes
                  final previousLine = metroProvider.selectedLinea;
                  
                  // Debug: verificar que se llamó
                  print('🔍 HomeScreen: onSelected llamado con value=$value, previousLine=$previousLine');
                  
                  // Asegurar que se establece el valor
                  metroProvider.setSelectedLinea(value);
                  
                  // Verificar que se actualizó
                  print('🔍 HomeScreen: Después de setSelectedLinea, selectedLinea=${metroProvider.selectedLinea}');
                  print('🔍 HomeScreen: Estaciones después del cambio: ${metroProvider.stations.length}');
                  
                  // Notificar cambio de línea al servicio de sesión
                  await AdSessionService.instance.onLineChanged(value == 'all' ? null : value);
                  
                  // Verificar si se debe mostrar intersticial (solo si cambió de línea y estuvo tiempo suficiente)
                  if (previousLine != value && previousLine != 'all') {
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
                  PopupMenuItem<String>(
                    value: 'all',
                    child: Row(
                      children: [
                        if (currentLinea == 'all')
                          const Icon(Icons.check, size: 20, color: Colors.blue)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 8),
                        const Text('Todas las líneas'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
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
                  PopupMenuItem<String>(
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

