import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/metro_theme.dart';
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
import '../../services/simulated_time_service.dart';
import '../../services/ad_service.dart';
import '../../services/ad_session_service.dart';
import '../../widgets/location_permission_dialog.dart';
import '../../widgets/confirm_reports_sheet.dart';
import '../../widgets/pulsing_button.dart';
import '../../widgets/train_time_report_flow_widget.dart';
import '../../models/station_model.dart';
import '../../widgets/nearest_station_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showCustomMap = false; // Toggle entre Google Maps y mapa personalizado
  static const String _locationDialogShownKey =
      'location_permission_dialog_shown';
  bool _isCheckingLocation = false;
  bool _lastGpsStatus = true;
  bool _lastPermissionStatus = true;
  final GlobalKey<MapWidgetState> _mapWidgetKey = GlobalKey<MapWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Verificar permisos de ubicación al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
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

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final status = await locationProvider.checkLocationStatus();

    // Si el estado cambió (GPS se desactivó o permisos se revocaron), mostrar diálogo
    if ((_lastGpsStatus != status.isGpsEnabled ||
            _lastPermissionStatus != status.hasPermission) &&
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

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final status = await locationProvider.checkLocationStatus();

    // Guardar estado actual
    _lastGpsStatus = status.isGpsEnabled;
    _lastPermissionStatus = status.hasPermission;

    // Si el GPS está desactivado, mostrar diálogo para activarlo
    if (!status.isGpsEnabled) {
      if (mounted) {
        await LocationPermissionDialog.show(
          context,
          isGpsEnabled: status.isGpsEnabled,
          hasPermission: status.hasPermission,
        );

        // Después de que el usuario cierre el diálogo, verificar de nuevo
        if (mounted) {
          final newStatus = await locationProvider.checkLocationStatus();
          if (newStatus.isGpsEnabled) {
            // Si ahora el GPS está activado, intentar obtener permisos
            if (!newStatus.hasPermission) {
              await locationProvider.getCurrentLocation();
            }
            // Si tiene permisos, obtener ubicación y activar tracking
            if (locationProvider.hasPermission) {
              await locationProvider.getCurrentLocation();
              locationProvider.startTracking();
            }
          }
        }
      }
      _isCheckingLocation = false;
      return;
    }

    // Si tiene permisos, obtener ubicación y activar tracking
    if (status.hasPermission && status.isGpsEnabled) {
      await locationProvider.getCurrentLocation();
      // Iniciar tracking para actualización continua
      locationProvider.startTracking();
    } else if (!status.hasPermission && status.isGpsEnabled) {
      // Si el GPS está activado pero no hay permisos, mostrar diálogo
      if (mounted) {
        final result = await LocationPermissionDialog.show(
          context,
          isGpsEnabled: status.isGpsEnabled,
          hasPermission: status.hasPermission,
        );

        if (result == true && mounted) {
          await locationProvider.getCurrentLocation();
          if (locationProvider.hasPermission) {
            locationProvider.startTracking();
          }
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final hasShownNotification =
        prefs.getBool(_locationDialogShownKey) ?? false;

    // Solo mostrar notificación si YA rechazó los permisos permanentemente
    if (status.permission == LocationPermission.deniedForever &&
        !hasShownNotification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('💡 La ubicación ayuda a mejorar los reportes'),
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: () async {
                await Geolocator.openLocationSettings();
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

    final shouldShow =
        await AdSessionService.instance.shouldShowInterstitialOnReopen();
    if (shouldShow) {
      await AdService.instance.showInterstitialIfAppropriate(
        onAdDismissed: () {
          // Continuar normalmente
        },
      );
    }
  }

  Future<void> _showModeDialog(
      BuildContext context, AppMode currentMode, String userId) async {
    final newMode = await showDialog<AppMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modo de Aplicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppMode>(
              title: const Text('Desarrollo'),
              subtitle:
                  const Text('Versión oficial con todas las validaciones'),
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
              subtitle:
                  const Text('Permite reportar desde cualquier ubicación'),
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
        final metroProvider =
            Provider.of<MetroDataProvider>(context, listen: false);
        metroProvider.setTestMode(newMode == AppMode.test);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Modo cambiado a: ${newMode == AppMode.test ? "Test" : "Desarrollo"}'),
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
      final metroProvider =
          Provider.of<MetroDataProvider>(context, listen: false);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MetroPTY',
              style: TextStyle(
                color: MetroColors.blue,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                if (user == null) return const SizedBox.shrink();

                return StreamBuilder<AppMode>(
                  stream: AppModeService().watchMode(user.uid),
                  builder: (context, snapshot) {
                    final mode = snapshot.data ?? AppMode.development;
                    if (mode == AppMode.development)
                      return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () => _showModeDialog(context, mode, user.uid),
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bug_report,
                                size: 10, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'MODO TEST',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200],
            height: 1.0,
          ),
        ),
        actions: [
          // Botón para cambiar entre mapas
          IconButton(
            icon: Icon(
                _showCustomMap ? Icons.map_outlined : Icons.train_outlined,
                color: MetroColors.grayDark),
            onPressed: () {
              HapticFeedback.lightImpact();
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
                icon: Icon(Icons.tune_rounded, color: MetroColors.grayDark),
                onSelected: (String value) async {
                  HapticFeedback.selectionClick();
                  // Registrar cambio de línea para anuncios inteligentes
                  final previousLine = metroProvider.selectedLinea;
                  metroProvider.setSelectedLinea(value);
                  await AdSessionService.instance
                      .onLineChanged(value == 'all' ? null : value);

                  if (previousLine != value && previousLine != 'all') {
                    final shouldShow = await AdSessionService.instance
                        .shouldShowInterstitialOnLineChange();
                    if (shouldShow && context.mounted) {
                      await AdService.instance.showInterstitialIfAppropriate(
                        onAdDismissed: () {},
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 20,
                          color: currentLinea == 'all'
                              ? MetroColors.blue
                              : MetroColors.grayMedium,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Todas las líneas',
                          style: TextStyle(
                            fontWeight: currentLinea == 'all'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: currentLinea == 'all'
                                ? MetroColors.blue
                                : MetroColors.grayDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'linea1',
                    child: Row(
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 20,
                          color: currentLinea == 'linea1'
                              ? MetroColors.blue
                              : MetroColors.blue.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Línea 1',
                          style: TextStyle(
                            fontWeight: currentLinea == 'linea1'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: currentLinea == 'linea1'
                                ? MetroColors.blue
                                : MetroColors.grayDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'linea2',
                    child: Row(
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 20,
                          color: currentLinea == 'linea2'
                              ? MetroColors.green
                              : MetroColors.green.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Línea 2',
                          style: TextStyle(
                            fontWeight: currentLinea == 'linea2'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: currentLinea == 'linea2'
                                ? MetroColors.green
                                : MetroColors.grayDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon:
                Icon(Icons.verified_user_outlined, color: MetroColors.grayDark),
            tooltip: 'Confirmar Reportes',
            onPressed: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => const ConfirmReportsSheet(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded,
                color: MetroColors.grayDark),
            onPressed: () {
              HapticFeedback.lightImpact();
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
                                        content:
                                            Text('Estación: ${station.nombre}'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                );
                        },
                      )
                    : MapWidget(
                        key: _mapWidgetKey,
                      ),
              ),
              // Banner de publicidad
              const SafeArea(
                child: AdBanner(),
              ),
            ],
          ),
          // Widget de estación más cercana - parte superior central
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: const NearestStationWidget(),
              ),
            ),
          ),
          // Panel de acciones flotantes (Barra inferior personalizada)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Columna izquierda: Reportes
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const QuickReportButton(),
                    const SizedBox(height: 12),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        return Consumer<MetroDataProvider>(
                          builder: (context, metroProvider, child) {
                            return FloatingActionButton(
                              heroTag: 'report_train_time',
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                Position? userPosition =
                                    locationProvider.currentPosition;
                                if (userPosition == null &&
                                    locationProvider.hasPermission) {
                                  try {
                                    await locationProvider
                                        .getCurrentLocation()
                                        .timeout(
                                          const Duration(milliseconds: 800),
                                        );
                                    userPosition =
                                        locationProvider.currentPosition;
                                  } catch (e) {
                                    userPosition =
                                        locationProvider.currentPosition;
                                  }
                                }

                                StationModel? selectedStation;
                                final stations = metroProvider.stations;
                                if (stations.isEmpty) return;

                                if (userPosition != null) {
                                  double minDistance = double.infinity;
                                  for (final station in stations) {
                                    final distance = Geolocator.distanceBetween(
                                      userPosition.latitude,
                                      userPosition.longitude,
                                      station.ubicacion.latitude,
                                      station.ubicacion.longitude,
                                    );
                                    if (distance < minDistance) {
                                      minDistance = distance;
                                      selectedStation = station;
                                    }
                                  }
                                }

                                if (selectedStation == null) {
                                  selectedStation = stations.firstWhere(
                                    (s) =>
                                        s.linea == 'linea1' || s.linea == 'L1',
                                    orElse: () => stations.first,
                                  );
                                }

                                if (context.mounted) {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (sheetContext) =>
                                        DraggableScrollableSheet(
                                      expand: false,
                                      initialChildSize: 0.85,
                                      minChildSize: 0.5,
                                      maxChildSize: 0.95,
                                      builder: (context, scrollController) =>
                                          Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(32)),
                                        ),
                                        child: TrainTimeReportFlowWidget(
                                          station: selectedStation!,
                                          scrollController: scrollController,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              backgroundColor: Colors.white,
                              foregroundColor: MetroColors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: Colors.grey[200]!, width: 2),
                              ),
                              child:
                                  const Icon(Icons.schedule_rounded, size: 28),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                // Columna derecha: Ubicación, Velocidad y Llegada
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        return FloatingActionButton(
                          heroTag: 'locate_fab',
                          mini: true,
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final status =
                                await locationProvider.checkLocationStatus();
                            if (!status.hasPermission && status.isGpsEnabled) {
                              await locationProvider.getCurrentLocation();
                            } else if (!status.isGpsEnabled ||
                                !status.hasPermission) {
                              if (mounted) {
                                await LocationPermissionDialog.show(context,
                                    isGpsEnabled: status.isGpsEnabled,
                                    hasPermission: status.hasPermission);
                              }
                            } else {
                              await locationProvider.getCurrentLocation();
                            }
                            await Future.delayed(
                                const Duration(milliseconds: 300));
                            if (_mapWidgetKey.currentState != null) {
                              await _mapWidgetKey.currentState!
                                  .centerOnUserLocation();
                            }
                          },
                          backgroundColor: Colors.white,
                          foregroundColor: MetroColors.grayDark,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.grey[200]!, width: 1.5),
                          ),
                          child:
                              const Icon(Icons.my_location_rounded, size: 20),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        final speed =
                            locationProvider.currentPosition?.speed ?? 0.0;
                        final speedKmh = (speed * 3.6).clamp(0.0, 200.0);

                        return Consumer<MetroDataProvider>(
                          builder: (context, metroProvider, child) {
                            StationModel? nearestStation;
                            final currentPosition =
                                locationProvider.currentPosition;
                            if (currentPosition != null &&
                                metroProvider.stations.isNotEmpty) {
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

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (speedKmh > 5)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: MetroColors.grayDark,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.speed,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${speedKmh.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                PulsingButton(
                                  station: nearestStation,
                                  backgroundColor: Colors.white,
                                  heroTag: 'train_arrival_fab',
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.green
                                              .withValues(alpha: 0.5),
                                          width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/icons/metro-station_2340498.png',
                                        width: 32,
                                        height: 32,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
