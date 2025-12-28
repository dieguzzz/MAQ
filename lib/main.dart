import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/metro_data_provider.dart';
import 'providers/report_provider.dart';
import 'services/metro_simulator_service.dart';
import 'services/station_position_editor_service.dart';
import 'services/station_edit_mode_service.dart';
import 'services/notification_service.dart';
import 'utils/navigation_helper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/routes/route_planner.dart';
import 'screens/leaderboards/leaderboard_screen.dart';
import 'services/station_update_service.dart';
import 'theme/metro_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/ad_service.dart';
import 'services/ad_session_service.dart';
import 'widgets/dev/floating_dev_window.dart';
import 'services/dev_service.dart';
import 'widgets/points_reward_listener.dart';
import 'services/simplified_report_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _ensureFirebaseInitialized();
  print('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase PRIMERO (con timeout para no bloquear demasiado)
  try {
    print('🔥 Inicializando Firebase...');
    await _ensureFirebaseInitialized().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('⚠️ Firebase initialization timeout');
        throw TimeoutException('Firebase initialization timeout');
      },
    );
    print('✅ Firebase inicializado');
  } catch (e, stackTrace) {
    print('❌ Error inicializando Firebase: $e');
    print('📍 Stack trace: $stackTrace');
    // Continuar de todas formas, pero los servicios que dependen de Firebase fallarán
  }
  
  // Inicializar NotificationService DESPUÉS de Firebase (de forma asíncrona)
  final notificationService = NotificationService();
  notificationService.onNotificationTapped = NavigationHelper.handleNotificationNavigation;
  notificationService.initialize().catchError((e) {
    print('❌ Error inicializando NotificationService (no crítico): $e');
  });
  print('🔔 Inicialización de NotificationService iniciada (asíncrona)');
  
  // Inicializar AdMob de forma asíncrona para no bloquear el arranque
  AdService.instance.initialize().catchError((e) {
    print('❌ Error inicializando AdService (no crítico): $e');
  });
  print('📢 Inicialización de AdService iniciada (asíncrona)');
  
  // Inicializar Ad Session Service de forma asíncrona
  AdSessionService.instance.initializeSession().catchError((e) {
    print('❌ Error inicializando AdSessionService (no crítico): $e');
  });
  print('📊 Inicialización de AdSessionService iniciada (asíncrona)');
  
  // Inicializar limpieza automática de reportes
  try {
    final reportService = SimplifiedReportService();
    reportService.startAutoCleanup();
    print('🧹 Limpieza automática de reportes iniciada');
  } catch (e) {
    print('❌ Error iniciando limpieza automática (no crítico): $e');
  }
  
  try {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Background message handler configurado');
  } catch (e, stackTrace) {
    print('❌ Error configurando background message handler: $e');
    print('📍 Stack trace: $stackTrace');
    // Continuar de todas formas
  }
  
  try {
    // Initialize static stations in Firestore (solo si no existen)
    // Hacer esto de forma asíncrona para no bloquear el arranque
    _initializeStations().catchError((e) {
      print('❌ Error inicializando estaciones (no crítico): $e');
    });
    print('✅ Inicialización de estaciones iniciada (asíncrona)');
  } catch (e, stackTrace) {
    print('❌ Error iniciando inicialización de estaciones: $e');
    print('📍 Stack trace: $stackTrace');
    // Continuar de todas formas
  }
  
  print('🚀 Iniciando app...');
  runApp(const MetroPTYApp());
}

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> _initializeStations() async {
  try {
    print('🚀 Iniciando inicialización/actualización de estaciones...');
    final stationUpdateService = StationUpdateService();
    
    // Usar el servicio de actualización que maneja todo
    final results = await stationUpdateService.updateAllStations();
    
    print('✅ Actualización completada:');
    print('   - Actualizadas: ${results['updated']} estaciones');
    print('   - Creadas: ${results['created']} estaciones');
    print('   - Eliminadas: ${results['deleted']} estaciones duplicadas');
    
    if ((results['errors'] as List).isNotEmpty) {
      print('⚠️  Errores encontrados:');
      for (final error in results['errors'] as List) {
        print('   - $error');
      }
    }
  } catch (e, stackTrace) {
    print('❌ Error inicializando/actualizando estaciones: $e');
    print('📍 Stack trace: $stackTrace');
  }
}

class MetroPTYApp extends StatefulWidget {
  const MetroPTYApp({super.key});

  @override
  State<MetroPTYApp> createState() => _MetroPTYAppState();
}

class _MetroPTYAppState extends State<MetroPTYApp> {
  static const String _onboardingKey = 'has_completed_onboarding';
  late Future<bool> _onboardingFuture;
  
  // Crear providers una vez y reutilizarlos
  late final AuthProvider _authProvider;
  late final LocationProvider _locationProvider;
  late final MetroDataProvider _metroDataProvider;
  late final ReportProvider _reportProvider;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = _loadOnboardingStatus();
    
    // Crear providers una vez en initState
    _authProvider = AuthProvider();
    _locationProvider = LocationProvider();
    _metroDataProvider = MetroDataProvider();
    _reportProvider = ReportProvider();
    
    // Inicializar AuthProvider después de que Firebase esté listo
    // Usar un pequeño delay para asegurar que Firebase esté completamente inicializado
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _authProvider.ensureStreamInitialized();
      }
    });
  }

  Future<bool> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    setState(() {
      _onboardingFuture = Future.value(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _locationProvider),
        ChangeNotifierProvider.value(value: _metroDataProvider),
        ChangeNotifierProvider.value(value: _reportProvider),
        ChangeNotifierProvider.value(value: MetroSimulatorService()),
        ChangeNotifierProvider.value(value: StationPositionEditorService()),
        ChangeNotifierProvider.value(value: StationEditModeService()),
      ],
      child: FutureBuilder<bool>(
        future: _onboardingFuture,
        builder: (context, snapshot) {
          final bool isReady = snapshot.connectionState == ConnectionState.done;
          final bool hasCompleted = snapshot.data ?? false;

          return PointsRewardListener(
            child: MaterialApp(
              navigatorKey: NavigationHelper.navigatorKey,
              title: 'MetroPTY',
              theme: MetroTheme.light(),
              themeMode: ThemeMode.light,
              home: !isReady
                  ? const _SplashScaffold()
                  : hasCompleted
                    ? const AuthGate()
                    : OnboardingScreen(onFinished: _completeOnboarding),
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}

class _SplashScaffold extends StatelessWidget {
  const _SplashScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MetroColors.grayLight,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasCheckedSummary = false;

  @override
  void initState() {
    super.initState();
    _checkForSummary();
  }

  Future<void> _checkForSummary() async {
    // Verificar si hay reportes confirmados mientras la app estaba cerrada
    // y mostrar pantalla de resumen
    final prefs = await SharedPreferences.getInstance();
    final lastSummaryShown = prefs.getString('last_summary_date');
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Si no se ha mostrado resumen hoy, verificar si hay actividad reciente
    if (lastSummaryShown != today) {
      // TODO: Verificar si hay reportes confirmados recientes
      // Por ahora, solo marcamos que ya verificamos
      setState(() => _hasCheckedSummary = true);
    } else {
      setState(() => _hasCheckedSummary = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading || !_hasCheckedSummary) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isAuthenticated) {
          // TODO: Mostrar ReportSummaryScreen si hay actividad reciente
          // Por ahora, ir directo al mapa
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RoutePlanner(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de MetroPTY'),
        content: const Text('¿Estás seguro de que quieres salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevenir cierre automático
      onPopInvoked: (bool didPop) async {
        if (didPop) return; // Ya se manejó el pop
        
        // Verificar si hay pantallas en la pila de navegación
        final navigator = Navigator.of(context);
        final canPop = navigator.canPop();
        
        if (canPop) {
          // Hay pantallas secundarias, hacer pop normal
          navigator.pop();
        } else {
          // Estamos en la pantalla principal, mostrar confirmación antes de salir
          final shouldExit = await _showExitDialog(context);
          if (shouldExit && context.mounted) {
            // Cerrar la app solo si el usuario confirma
            // En Android, esto requiere SystemNavigator.pop()
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _screens[_currentIndex],
            // Ventana flotante de desarrollador
            ValueListenableBuilder<bool>(
              valueListenable: DevService.devModeNotifier,
              builder: (context, devModeEnabled, child) {
                return devModeEnabled ? const FloatingDevWindow() : const SizedBox.shrink();
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.route),
              label: 'Rutas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

