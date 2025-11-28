import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para manejar y traducir errores de Firebase/Firestore
class ErrorHandlerService {
  /// Convierte un error de Firebase/Firestore a un mensaje amigable en español
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      return _handleFirebaseException(error);
    } else if (error is FirebaseAuthException) {
      return _handleAuthException(error);
    } else if (error is Exception) {
      final message = error.toString();
      // Extraer mensaje de Exception
      if (message.contains('Exception: ')) {
        return message.split('Exception: ').last;
      }
      return message;
    } else if (error is String) {
      return error;
    }
    return 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
  }

  /// Maneja errores específicos de Firestore
  static String _handleFirebaseException(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permisos para realizar esta acción. Verifica tu autenticación.';
      
      case 'invalid-argument':
      case 'invalid-argument-error':
        return 'Los datos enviados no son válidos. Por favor verifica la información.';
      
      case 'not-found':
        return 'El recurso solicitado no fue encontrado.';
      
      case 'already-exists':
        return 'Este recurso ya existe.';
      
      case 'unauthenticated':
        return 'Debes iniciar sesión para realizar esta acción.';
      
      case 'unavailable':
        return 'El servicio no está disponible en este momento. Intenta más tarde.';
      
      case 'deadline-exceeded':
        return 'La operación tardó demasiado. Por favor intenta de nuevo.';
      
      case 'resource-exhausted':
        return 'Se ha alcanzado el límite de operaciones. Intenta más tarde.';
      
      case 'failed-precondition':
        return 'La operación no se puede completar en este momento.';
      
      case 'aborted':
        return 'La operación fue cancelada. Por favor intenta de nuevo.';
      
      case 'out-of-range':
        return 'Los datos están fuera del rango permitido.';
      
      case 'unimplemented':
        return 'Esta funcionalidad aún no está implementada.';
      
      case 'internal':
        return 'Error interno del servidor. Por favor intenta más tarde.';
      
      case 'cancelled':
        return 'La operación fue cancelada.';
      
      default:
        return error.message ?? 'Error desconocido: ${error.code}';
    }
  }

  /// Maneja errores específicos de Firebase Auth
  static String _handleAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      
      case 'user-not-found':
        return 'No se encontró una cuenta con este correo.';
      
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado.';
      
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      
      case 'operation-not-allowed':
        return 'Esta operación no está permitida.';
      
      case 'invalid-credential':
        return 'Las credenciales no son válidas.';
      
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo pero con otro método de autenticación.';
      
      case 'invalid-verification-code':
        return 'El código de verificación no es válido.';
      
      case 'invalid-verification-id':
        return 'El ID de verificación no es válido.';
      
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      
      default:
        return error.message ?? 'Error de autenticación: ${error.code}';
    }
  }

  /// Verifica si un error es un "bad request" (400)
  static bool isBadRequest(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'invalid-argument' || 
             error.code == 'invalid-argument-error' ||
             error.code == 'failed-precondition';
    }
    if (error is FirebaseAuthException) {
      return error.code == 'invalid-email' ||
             error.code == 'invalid-credential' ||
             error.code == 'weak-password';
    }
    return false;
  }

  /// Verifica si un error es de permisos
  static bool isPermissionDenied(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' || error.code == 'unauthenticated';
    }
    return false;
  }

  /// Verifica si un error es de red/conexión
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' || 
             error.code == 'deadline-exceeded' ||
             error.code == 'network-request-failed';
    }
    if (error is FirebaseAuthException) {
      return error.code == 'network-request-failed';
    }
    return false;
  }
}

