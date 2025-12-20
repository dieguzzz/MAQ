import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
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
import '../admin/learning_demo_panel.dart';
import '../../services/station_edit_mode_service.dart';
import '../../widgets/dev/secret_dev_activation.dart';
import '../../widgets/location_permission_dialog.dart';
import '../../widgets/confirm_reports_sheet.dart';
import '../../widgets/train_arrival_animation.dart';
import '../../widgets/pulsing_button.dart';
import '../../services/simplified_report_service.dart';
import '../../models/station_model.dart';
import '../../services/location_service.dart';
import '../../providers/metro_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showCustomMap = false; // Toggle entre Google Maps y mapa personalizado
  static const String _locationDialogShownKey = 'location_permission_dialog_shown';
  bool _isCheckingLocation = false;
  bool _lastGpsStatus = true;
  bool _lastPermissionStatus = true;
  final SimplifiedReportService _reportService = SimplifiedReportService();
  DateTime? _lastTrainButtonTap;
  Timer? _trainButtonTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Verificar si se debe mostrar intersticial al reabrir la app
    _checkReopenInterstitial();
    // Verificar modo test cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTestMode();
      _checkLocationPermission();
    });
  }

  @override
  void dispose() {
    _trainButtonTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Cuando la app vuelve a estar activa, verificar el estado de la ubicación
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermissionOnResume();
    }
  }

  Future<void> _checkLocationPermissionOnResume() async {
    if (_isCheckingLocation) return;
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final status = await locationProvider.checkLocationStatus();
    
    // Si el estado cambió (GPS se desactivó o permisos se revocaron), mostrar diálogo
    if ((_lastGpsStatus != status.isGpsEnabled || _lastPermissionStatus != status.hasPermission) &&
        (!status.isGpsEnabled || !status.hasPermission)) {
      if (mounted) {
        final result = await LocationPermissionDialog.show(
          context,
          isGpsEnabled: status.isGpsEnabled,
          hasPermission: status.hasPermission,
        );
        
        if (result == true && mounted) {
          await locationProvider.getCurrentLocation();
        }
      }
    }
    
    _lastGpsStatus = status.isGpsEnabled;
    _lastPermissionStatus = status.hasPermission;
  }

  Future<void> _checkLocationPermission() async {
    if (_isCheckingLocation) return;
    _isCheckingLocation = true;
    
    // Esperar un momento para que el LocationProvider se inicialice
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) {
      _isCheckingLocation = false;
      return;
    }

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final status = await locationProvider.checkLocationStatus();
    
    // Guardar estado actual
    _lastGpsStatus = status.isGpsEnabled;
    _lastPermissionStatus = status.hasPermission;
    
    final prefs = await SharedPreferences.getInstance();
    final hasShownNotification = prefs.getBool(_locationDialogShownKey) ?? false;
    
    // Solo mostrar notificación si YA rechazó los permisos permanentemente
    // NO pedir permisos aquí - eso se hace en el onboarding
    if (status.permission == LocationPermission.deniedForever && !hasShownNotification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('💡 La ubicación ayuda a mejorar los reportes'),
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: () {
                // TODO: Abrir configuración del sistema
                // Geolocator.openLocationSettings();
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        await prefs.setBool(_locationDialogShownKey, true);
      }
    }
    
    _isCheckingLocation = false;
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

  /// Maneja el botón "Ya llegó el metro"
  void _handleTrainArrival() {
    final now = DateTime.now();
    
    // Si hay un toque previo dentro de 500ms, es doble toque
    if (_lastTrainButtonTap != null && 
        now.difference(_lastTrainButtonTap!) < const Duration(milliseconds: 500)) {
      // Cancelar el timer del primer toque
      _trainButtonTimer?.cancel();
      _trainButtonTimer = null;
      _lastTrainButtonTap = null;
      
      // Doble toque: esperar medio segundo antes de enviar reporte
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _sendTrainArrivalReport(showAnimationFirst: true);
        }
      });
      return;
    }
    
    // Registrar este toque
    _lastTrainButtonTap = now;
    
    // Cancelar timer anterior si existe
    _trainButtonTimer?.cancel();
    
    // Esperar 500ms para ver si hay un segundo toque
    _trainButtonTimer = Timer(const Duration(milliseconds: 500), () {
      // Si pasó el tiempo sin segundo toque, mostrar diálogo
      _trainButtonTimer = null;
      _lastTrainButtonTap = null;
      
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para reportar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Llegó el metro?'),
          content: const SizedBox(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // No hacer nada
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _sendTrainArrivalReport(showAnimationFirst: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Sí'),
            ),
          ],
        ),
      );
    });
  }

  /// Envía el reporte de llegada del tren
  Future<void> _sendTrainArrivalReport({bool showAnimationFirst = false}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) return;

      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
      final currentPosition = locationProvider.currentPosition;

      // Obtener estación más cercana
      StationModel? nearestStation;
      if (currentPosition != null && metroProvider.stations.isNotEmpty) {
        double minDistance = double.infinity;
        for (final station in metroProvider.stations) {
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            station.ubicacion.latitude,
            station.ubicacion.longitude,
          );
          if (distance < minDistance) {
            minDistance = distance;
            nearestStation = station;
          }
        }
      }

      // Si no hay estación cercana, usar la primera disponible
      if (nearestStation == null && metroProvider.stations.isNotEmpty) {
        nearestStation = metroProvider.stations.first;
      }

      if (nearestStation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo determinar la estación'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final station = nearestStation!;
      final arrivalTime = DateTime.now();

      // Si showAnimationFirst es true, mostrar animación inmediatamente con 15 puntos
      if (showAnimationFirst && mounted) {
        TrainArrivalAnimation.show(
          context,
          points: 15, // Siempre 15 puntos
          onComplete: () {
            // Ya se cierra automáticamente
          },
        );
      }

      // Crear reporte directo de llegada (siempre 15 puntos)
      Position? position;
      try {
        final locationService = LocationService();
        final status = await locationService.checkLocationStatus();
        if (status.hasPermission) {
          position = await locationService.getCurrentPosition();
        }
      } catch (e) {
        print('No se pudo obtener ubicación: $e');
      }

      await _reportService.createDirectArrivalReport(
        stationId: station.id,
        arrivalTime: arrivalTime,
        trainLine: station.linea,
        userPosition: position,
      );

      // Si no se mostró la animación antes, mostrarla ahora
      if (!showAnimationFirst && mounted) {
        TrainArrivalAnimation.show(
          context,
          points: 15,
          onComplete: () {
            // Ya se cierra automáticamente
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                          SecretDevActivation(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bug_report,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'DEV',
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
          // Botón para confirmar reportes
          IconButton(
            icon: const Icon(Icons.verified_user),
            tooltip: 'Confirmar Reportes',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => const ConfirmReportsSheet(),
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
          // Botón de centrar mapa (más a la izquierda)
          Positioned(
            bottom: 80,
            right: 80,
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return FloatingActionButton(
                  heroTag: 'locate_fab',
                  onPressed: () async {
                    // Verificar estado antes de obtener ubicación
                    final status = await locationProvider.checkLocationStatus();
                    
                    // Si el GPS está desactivado o no hay permisos, mostrar diálogo
                    if (!status.isGpsEnabled || !status.hasPermission) {
                      if (mounted) {
                        final result = await LocationPermissionDialog.show(
                          context,
                          isGpsEnabled: status.isGpsEnabled,
                          hasPermission: status.hasPermission,
                        );
                        
                        if (result == true && mounted) {
                          await locationProvider.getCurrentLocation();
                        }
                      }
                    } else {
                      // Si todo está bien, obtener ubicación normalmente
                      await locationProvider.getCurrentLocation();
                    }
                  },
                  child: const Icon(Icons.my_location),
                );
              },
            ),
          ),
          // Medidor de velocidad y botón "Ya llegó el metro" (abajo del medidor)
          Positioned(
            bottom: 80,
            right: 8,
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                final speed = locationProvider.currentPosition?.speed ?? 0.0;
                final speedKmh = (speed * 3.6).clamp(0.0, 200.0); // Convertir m/s a km/h
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Medidor de velocidad
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${speedKmh.toStringAsFixed(0)} km/h',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón "Ya llegó el metro" (abajo del medidor) con animación de pulso
                    Consumer<MetroDataProvider>(
                      builder: (context, metroProvider, child) {
                        // Obtener estación más cercana para el pulso
                        StationModel? nearestStation;
                        final currentPosition = locationProvider.currentPosition;
                        if (currentPosition != null && metroProvider.stations.isNotEmpty) {
                          double minDistance = double.infinity;
                          for (final station in metroProvider.stations) {
                            final distance = Geolocator.distanceBetween(
                              currentPosition.latitude,
                              currentPosition.longitude,
                              station.ubicacion.latitude,
                              station.ubicacion.longitude,
                            );
                            if (distance < minDistance) {
                              minDistance = distance;
                              nearestStation = station;
                            }
                          }
                        }

                        return PulsingButton(
                          station: nearestStation,
                          backgroundColor: Colors.green,
                          heroTag: 'train_arrival_fab',
                          onPressed: _handleTrainArrival,
                          child: FloatingActionButton(
                            heroTag: 'train_arrival_fab_inner',
                            onPressed: _handleTrainArrival,
                            backgroundColor: Colors.green,
                            child: Image.asset(
                              'assets/icons/metro-station_2340498.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

