import 'package:flutter/foundation.dart';

/// Centralized logger that only outputs in debug mode.
/// Prevents sensitive data from leaking in production builds.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('[WARN] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) print('  Error: $error');
      if (stackTrace != null) print('  Stack: $stackTrace');
    }
  }
}
