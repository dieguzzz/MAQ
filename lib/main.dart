import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/metro_data_provider.dart';
import 'providers/report_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/routes/route_planner.dart';
import 'services/firebase_service.dart';
import 'utils/metro_data.dart';
import 'models/station_model.dart';
import 'theme/metro_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_screen.dart';
import 'services/ad_service.dart';
import 'services/ad_session_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _ensureFirebaseInitialized();
  print('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await _ensureFirebaseInitialized();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize AdMob
  await AdService.instance.initialize();
  
  // Initialize Ad Session Service
  await AdSessionService.instance.initializeSession();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize static stations in Firestore (solo si no existen)
  await _initializeStations();
  
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
    print('🚀 Iniciando inicialización de estaciones...');
    final firebaseService = FirebaseService();
    
    // Intentar leer estaciones existentes
    List<StationModel> existingStations = [];
    try {
      existingStations = await firebaseService.getStations();
      print('✅ Estaciones leídas: ${existingStations.length}');
    } catch (readError) {
      print('⚠️ Error leyendo estaciones (esto es normal si no existen): $readError');
      // Si falla la lectura, continuamos para intentar crear
    }
    
    // Solo inicializar si no hay estaciones
    if (existingStations.isEmpty) {
      print('📝 No hay estaciones, creando estaciones...');
      final allStations = MetroData.getAllStations();
      print('📦 Total de estaciones a crear: ${allStations.length}');
      
      final batch = firebaseService.firestore.batch();
      
      for (var station in allStations) {
        final docRef = firebaseService.firestore
            .collection('stations')
            .doc(station.id);
        // Usar set() sin merge para crear el documento (equivalente a create)
        // Como ya verificamos que no hay estaciones, esto creará nuevos documentos
        batch.set(docRef, station.toFirestore());
      }
      
      print('💾 Guardando estaciones en Firestore...');
      await batch.commit();
      print('✅ ¡Estaciones inicializadas en Firestore! Total: ${allStations.length}');
    } else {
      print('✅ Ya existen ${existingStations.length} estaciones en Firestore');
    }
  } catch (e, stackTrace) {
    print('❌ Error inicializando estaciones: $e');
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

  @override
  void initState() {
    super.initState();
    _onboardingFuture = _loadOnboardingStatus();
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MetroDataProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: FutureBuilder<bool>(
        future: _onboardingFuture,
        builder: (context, snapshot) {
          final bool isReady = snapshot.connectionState == ConnectionState.done;
          final bool hasCompleted = snapshot.data ?? false;

          return MaterialApp(
            title: 'MetroPTY',
            theme: MetroTheme.light(),
            themeMode: ThemeMode.light,
            home: !isReady
                ? const _SplashScaffold()
                : hasCompleted
                    ? const AuthGate()
                    : OnboardingScreen(onFinished: _completeOnboarding),
            debugShowCheckedModeBanner: false,
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isAuthenticated) {
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
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

