import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/error_handler_service.dart';
import '../services/app_mode_service.dart';
import '../services/debug_log_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _streamInitialized = false;
  StreamSubscription<UserModel?>? _userStreamSubscription;

  UserModel? get currentUser {
    _ensureStreamInitialized();
    return _currentUser;
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated {
    _ensureStreamInitialized();
    return _currentUser != null;
  }

  bool get isGuest => FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  AuthProvider() {
    // No inicializar streams aquí - se hará de forma lazy cuando se necesiten
  }

  /// Inicializa los streams solo cuando se necesitan (lazy initialization)
  void ensureStreamInitialized() {
    if (_streamInitialized) return;
    _streamInitialized = true;

    // Si ya hay un usuario en Firebase Auth, marcamos loading=true de forma
    // síncrona para evitar el flash de "no autenticado" en el primer frame.
    if (_firebaseService.getCurrentUser() != null) {
      _isLoading = true;
    }

    // Defer la inicialización completa para no llamar notifyListeners durante build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  // Método privado para uso interno
  void _ensureStreamInitialized() => ensureStreamInitialized();

  void _init() {
    try {
      // Verificar el estado actual de autenticación primero
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser != null) {
        _startListeningToUser(currentUser.uid);
      }

      // Luego escuchar cambios de autenticación
      _firebaseService.getAuthStateChanges().listen((User? user) async {
        // Cancelar suscripción anterior si existe
        await _userStreamSubscription?.cancel();

        if (user != null) {
          _startListeningToUser(user.uid);
        } else {
          _currentUser = null;
          _isLoading = false;
          notifyListeners();
        }
      }, onError: (error) {
        print('Error en auth state stream: $error');
        // Continuar sin el stream si hay un error
      });
    } catch (e) {
      print('Error initializing auth stream: $e');
      // Continuar sin el stream si hay un error
    }
  }

  /// Inicia la escucha de cambios en tiempo real del usuario
  void _startListeningToUser(String uid) {
    _isLoading = true;
    notifyListeners();

    // Cancelar suscripción anterior si existe
    _userStreamSubscription?.cancel();

    // Verificar si está en modo test y habilitar logs en Firestore
    _checkAndEnableDebugLogs(uid);

    // Primero verificar si el usuario existe, si no, crearlo
    _ensureUserExists(uid).then((_) {
      // Una vez que el usuario existe (o si ya existía), empezar a escuchar
      _userStreamSubscription = _firebaseService.getUserStream(uid).listen(
        (UserModel? user) {
          _currentUser = user;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('Error en user stream: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    }).catchError((error) {
      print('Error ensuring user exists: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Verifica si el usuario está en modo test y habilita logs en Firestore
  Future<void> _checkAndEnableDebugLogs(String uid) async {
    try {
      final appModeService = AppModeService();
      final isTestMode = await appModeService.isTestMode(uid);
      if (isTestMode) {
        DebugLogService().enableFirestore();
        print('✅ Modo test detectado - Logs de Firestore habilitados');
      } else {
        DebugLogService().disableFirestore();
      }
    } catch (e) {
      print('Error verificando modo test: $e');
    }
  }

  /// Asegura que el usuario existe en Firestore antes de escuchar cambios
  Future<void> _ensureUserExists(String uid) async {
    final userModel = await _firebaseService.getUser(uid);
    if (userModel != null) {
      return; // Usuario ya existe
    }

    // Si no existe, crearlo
    final firebaseUser = _firebaseService.getCurrentUser();
    if (firebaseUser == null) {
      throw Exception('Usuario de Firebase no autenticado');
    }

    final newUser = _buildUserModelFromFirebaseUser(firebaseUser);
    await _firebaseService.createUser(newUser);
  }

  Future<void> loadUser(String uid) async {
    // Este método ahora usa streams para actualización en tiempo real
    _startListeningToUser(uid);
  }

  UserModel _buildUserModelFromFirebaseUser(User firebaseUser) {
    final displayName = firebaseUser.displayName?.trim();
    final guestSuffixLength = math.min(firebaseUser.uid.length, 5);
    final generatedName = displayName != null && displayName.isNotEmpty
        ? displayName
        : firebaseUser.isAnonymous
            ? 'Invitado ${firebaseUser.uid.substring(0, guestSuffixLength).toUpperCase()}'
            : 'Viajero Metro';

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      nombre: generatedName,
      fotoUrl: firebaseUser.photoURL,
      reputacion: firebaseUser.isAnonymous ? 30 : 50,
      reportesCount: 0,
      creadoEn: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validaciones básicas
      if (email.isEmpty) {
        throw Exception('El correo electrónico es requerido');
      }
      if (password.isEmpty) {
        throw Exception('La contraseña es requerida');
      }

      final userCredential =
          await _firebaseService.signInWithEmailAndPassword(email, password);
      loadUser(userCredential.user!.uid);
      // El stream se encargará de actualizar _isLoading y _currentUser automáticamente
      return null; // Éxito
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ErrorHandlerService.getErrorMessage(e);
    }
  }

  Future<String?> signUp(String email, String password, String nombre) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validaciones básicas
      if (email.isEmpty) {
        throw Exception('El correo electrónico es requerido');
      }
      if (password.isEmpty) {
        throw Exception('La contraseña es requerida');
      }
      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }
      if (nombre.isEmpty) {
        throw Exception('El nombre es requerido');
      }

      final userCredential = await _firebaseService
          .createUserWithEmailAndPassword(email, password);

      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        nombre: nombre,
        creadoEn: DateTime.now(),
        reputacion: 50,
        reportesCount: 0,
      );

      await _firebaseService.createUser(newUser);
      loadUser(userCredential.user!.uid);
      // El stream se encargará de actualizar _isLoading y _currentUser
      return null; // Éxito
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ErrorHandlerService.getErrorMessage(e);
    }
  }

  Future<String?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _firebaseService.signInWithGoogle();
      final user = credential?.user;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return 'Se canceló el inicio de sesión con Google';
      }

      loadUser(user.uid);
      // El stream se encargará de actualizar _isLoading y _currentUser automáticamente
      return null; // Éxito
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ErrorHandlerService.getErrorMessage(e);
    }
  }

  Future<String?> signInAsGuest() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _firebaseService.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return 'Error al crear sesión de invitado';
      }

      loadUser(user.uid);
      // El stream se encargará de actualizar _isLoading y _currentUser automáticamente
      return null; // Éxito
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ErrorHandlerService.getErrorMessage(e);
    }
  }

  Future<String?> linkWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _firebaseService.linkWithGoogle();
      final user = credential?.user;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return 'Se canceló la vinculación con Google';
      }

      // Actualizar el perfil con datos de Google
      final updateData = <String, dynamic>{};
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        updateData['nombre'] = user.displayName;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        updateData['email'] = user.email;
      }
      if (user.photoURL != null) {
        updateData['foto_url'] = user.photoURL;
      }
      updateData['reputacion'] = 50; // Upgrade from guest reputation (30)

      if (updateData.isNotEmpty) {
        await _firebaseService.updateUser(user.uid, updateData);
      }

      loadUser(user.uid);
      return null; // Éxito
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ErrorHandlerService.getErrorMessage(e);
    }
  }

  Future<void> signOut() async {
    await _userStreamSubscription?.cancel();
    await _firebaseService.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Elimina la cuenta del usuario y todos sus datos
  /// Retorna true si la eliminación fue exitosa
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _currentUser!.uid;

      // 1. Eliminar imagen de perfil de Storage si existe
      if (_currentUser!.fotoUrl != null) {
        try {
          final storageService = StorageService();
          await storageService.deleteProfileImage(userId);
        } catch (e) {
          print('Error eliminando imagen de perfil: $e');
          // Continuar aunque falle la eliminación de la imagen
        }
      }

      // 2. Eliminar datos del usuario de Firestore
      await _firebaseService.deleteUserData(userId);

      // 3. Eliminar cuenta de Firebase Auth
      await _firebaseService.deleteAuthAccount();

      // 4. Limpiar estado local
      _currentUser = null;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('Error eliminando cuenta: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUserReputation(int newReputacion) async {
    if (_currentUser == null) return;

    try {
      await _firebaseService.updateUser(
        _currentUser!.uid,
        {'reputacion': newReputacion},
      );
      // No necesitamos actualizar _currentUser manualmente
      // El stream se encargará de actualizarlo automáticamente
    } catch (e) {
      print('Error updating reputation: $e');
    }
  }

  /// Actualiza el perfil del usuario
  /// Retorna true si la actualización fue exitosa
  Future<bool> updateProfile({
    String? nombre,
    String? fotoUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updateData = <String, dynamic>{};

      if (nombre != null && nombre.trim().isNotEmpty) {
        updateData['nombre'] = nombre.trim();
      }

      if (fotoUrl != null) {
        updateData['foto_url'] = fotoUrl;
      }

      if (updateData.isEmpty) {
        return true; // No hay cambios que guardar
      }

      await _firebaseService.updateUser(_currentUser!.uid, updateData);

      // No necesitamos actualizar _currentUser manualmente
      // El stream se encargará de actualizarlo automáticamente

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Dispose: cancelar suscripción cuando se destruye el provider
  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    super.dispose();
  }
}
