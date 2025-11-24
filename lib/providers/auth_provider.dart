import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _firebaseService.getAuthStateChanges().listen((User? user) async {
      if (user != null) {
        await loadUser(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
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

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _firebaseService.signInWithEmailAndPassword(
          email, password);
      await loadUser(userCredential.user!.uid);
      return true;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String nombre) async {
    _isLoading = true;
    notifyListeners();

    try {
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
      return true;
    } catch (e) {
      print('Error signing up: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _firebaseService.signInWithGoogle();
      final user = credential?.user;
      if (user == null) {
        return false;
      }

      await loadUser(user.uid);
      return _currentUser != null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInAsGuest() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _firebaseService.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        return false;
      }

      await loadUser(user.uid);
      return _currentUser != null;
    } catch (e) {
      print('Error signing in as guest: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _currentUser = null;
    notifyListeners();
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
}

