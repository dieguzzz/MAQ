import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/error_handler_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _streamInitialized = false;

  UserModel? get currentUser {
    _ensureStreamInitialized();
    return _currentUser;
  }
  
  bool get isLoading => _isLoading;
  bool get isAuthenticated {
    _ensureStreamInitialized();
    return _currentUser != null;
  }

  AuthProvider() {
    // No inicializar streams aquí - se hará de forma lazy cuando se necesiten
  }

  /// Inicializa los streams solo cuando se necesitan (lazy initialization)
  void ensureStreamInitialized() {
    if (_streamInitialized) return;
    _streamInitialized = true;
    _init();
  }

  // Método privado para uso interno
  void _ensureStreamInitialized() => ensureStreamInitialized();

  void _init() {
    try {
      // Verificar el estado actual de autenticación primero
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser != null) {
        loadUser(currentUser.uid);
      }
      
      // Luego escuchar cambios
      _firebaseService.getAuthStateChanges().listen((User? user) async {
        if (user != null) {
          await loadUser(user.uid);
        } else {
          _currentUser = null;
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

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _loadOrCreateUser(uid);
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> _loadOrCreateUser(String uid) async {
    var userModel = await _firebaseService.getUser(uid);
    if (userModel != null) {
      return userModel;
    }

    final firebaseUser = _firebaseService.getCurrentUser();
    if (firebaseUser == null) {
      return null;
    }

    final newUser = _buildUserModelFromFirebaseUser(firebaseUser);
    await _firebaseService.createUser(newUser);
    return newUser;
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

      final userCredential = await _firebaseService.signInWithEmailAndPassword(
          email, password);
      await loadUser(userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();
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

      final userCredential =
          await _firebaseService.createUserWithEmailAndPassword(email, password);
      
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        nombre: nombre,
        creadoEn: DateTime.now(),
        reputacion: 50,
        reportesCount: 0,
      );

      await _firebaseService.createUser(newUser);
      await loadUser(userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();
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

      await loadUser(user.uid);
      _isLoading = false;
      notifyListeners();
      return _currentUser != null ? null : 'Error al cargar el perfil del usuario';
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

      await loadUser(user.uid);
      _isLoading = false;
      notifyListeners();
      return _currentUser != null ? null : 'Error al cargar el perfil del usuario';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ErrorHandlerService.getErrorMessage(e);
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _currentUser = null;
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
      _currentUser = _currentUser!.copyWith(reputacion: newReputacion);
      notifyListeners();
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
      
      // Actualizar el modelo local
      _currentUser = _currentUser!.copyWith(
        nombre: nombre ?? _currentUser!.nombre,
        fotoUrl: fotoUrl ?? _currentUser!.fotoUrl,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}

