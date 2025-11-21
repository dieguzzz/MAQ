import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/metro_data_provider.dart';
import 'providers/report_provider.dart';
import 'services/notification_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/routes/route_planner.dart';
import 'services/firebase_service.dart';
import 'utils/metro_data.dart';
import 'models/station_model.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize static stations in Firestore (solo si no existen)
  await _initializeStations();
  
  runApp(const MetroPTYApp());
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

class MetroPTYApp extends StatelessWidget {
  const MetroPTYApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MetroDataProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'MetroPTY',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MainNavigationScreen(),
        debugShowCheckedModeBanner: false,
      ),
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

