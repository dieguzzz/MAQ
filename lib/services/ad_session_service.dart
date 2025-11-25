import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Servicio para gestionar el estado de sesión y determinar cuándo mostrar anuncios
/// Sigue las pautas de UX: nunca interrumpir acciones urgentes
class AdSessionService {
  static AdSessionService? _instance;
  static AdSessionService get instance => _instance ??= AdSessionService._();
  
  AdSessionService._();

  // Claves para SharedPreferences
  static const String _keyLastAppOpen = 'ad_last_app_open';
  static const String _keyReportsInSession = 'ad_reports_in_session';
  static const String _keyInterstitialsShownToday = 'ad_interstitials_today';
  static const String _keyLastInterstitialDate = 'ad_last_interstitial_date';
  static const String _keyCurrentLine = 'ad_current_line';
  static const String _keyLineStartTime = 'ad_line_start_time';

  // Configuración
  static const int _maxInterstitialsPerDay = 3;
  static const int _reportsForInterstitial = 3;
  static const Duration _hoursForReopenAd = Duration(hours: 4);
  static const Duration _minTimeOnLine = Duration(minutes: 2);

  /// Inicializa la sesión cuando se abre la app
  Future<void> initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Guardar tiempo de apertura
    await prefs.setString(_keyLastAppOpen, now.toIso8601String());
    
    // Resetear contador de reportes si pasó mucho tiempo (nueva sesión)
    final lastOpenStr = prefs.getString(_keyLastAppOpen);
    if (lastOpenStr != null) {
      final lastOpen = DateTime.parse(lastOpenStr);
      final timeSinceLastOpen = now.difference(lastOpen);
      
      // Si pasaron más de 4 horas, resetear contador de reportes
      if (timeSinceLastOpen > _hoursForReopenAd) {
        await prefs.setInt(_keyReportsInSession, 0);
      }
    }
    
    // Resetear contador diario de intersticiales si es un nuevo día
    final lastDateStr = prefs.getString(_keyLastInterstitialDate);
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      if (!_isSameDay(lastDate, now)) {
        await prefs.setInt(_keyInterstitialsShownToday, 0);
        await prefs.setString(_keyLastInterstitialDate, now.toIso8601String());
      }
    } else {
      await prefs.setString(_keyLastInterstitialDate, now.toIso8601String());
    }
  }

  /// Incrementa el contador de reportes en la sesión
  Future<void> incrementReportCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_keyReportsInSession) ?? 0;
    await prefs.setInt(_keyReportsInSession, currentCount + 1);
  }

  /// Obtiene el número de reportes en la sesión actual
  Future<int> getReportCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReportsInSession) ?? 0;
  }

  /// Verifica si se debe mostrar un intersticial después de un reporte
  /// Regla: Solo después del 3er reporte en la sesión
  Future<bool> shouldShowInterstitialAfterReport() async {
    final reportCount = await getReportCount();
    final interstitialsToday = await getInterstitialsShownToday();
    
    // Verificar límites
    if (interstitialsToday >= _maxInterstitialsPerDay) {
      return false;
    }
    
    // Mostrar solo después del 3er reporte
    return reportCount == _reportsForInterstitial;
  }

  /// Verifica si se debe mostrar un intersticial al reabrir la app
  /// Regla: Solo si pasaron 4+ horas desde la última apertura
  Future<bool> shouldShowInterstitialOnReopen() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenStr = prefs.getString(_keyLastAppOpen);
    
    if (lastOpenStr == null) return false;
    
    final lastOpen = DateTime.parse(lastOpenStr);
    final now = DateTime.now();
    final timeSinceLastOpen = now.difference(lastOpen);
    
    final interstitialsToday = await getInterstitialsShownToday();
    if (interstitialsToday >= _maxInterstitialsPerDay) {
      return false;
    }
    
    // Solo si pasaron 4+ horas Y no se mostró intersticial hoy por esta razón
    return timeSinceLastOpen >= _hoursForReopenAd;
  }

  /// Registra un cambio de línea
  Future<void> onLineChanged(String? newLine) async {
    final prefs = await SharedPreferences.getInstance();
    final currentLine = prefs.getString(_keyCurrentLine);
    
    // Si cambió de línea
    if (currentLine != newLine && currentLine != null) {
      final lineStartTimeStr = prefs.getString(_keyLineStartTime);
      if (lineStartTimeStr != null) {
        final lineStartTime = DateTime.parse(lineStartTimeStr);
        final timeOnLine = DateTime.now().difference(lineStartTime);
        
        // Solo si estuvo 2+ minutos en la línea anterior
        if (timeOnLine >= _minTimeOnLine) {
          // Guardar que puede mostrar intersticial en el próximo cambio
          await prefs.setBool('ad_can_show_on_line_change', true);
        }
      }
    }
    
    // Actualizar línea actual y tiempo
    if (newLine != null) {
      await prefs.setString(_keyCurrentLine, newLine);
      await prefs.setString(_keyLineStartTime, DateTime.now().toIso8601String());
    } else {
      await prefs.remove(_keyCurrentLine);
      await prefs.remove(_keyLineStartTime);
    }
  }

  /// Verifica si se debe mostrar intersticial al cambiar de línea
  Future<bool> shouldShowInterstitialOnLineChange() async {
    final prefs = await SharedPreferences.getInstance();
    final canShow = prefs.getBool('ad_can_show_on_line_change') ?? false;
    final interstitialsToday = await getInterstitialsShownToday();
    
    if (!canShow || interstitialsToday >= _maxInterstitialsPerDay) {
      return false;
    }
    
    // Resetear flag
    await prefs.setBool('ad_can_show_on_line_change', false);
    return true;
  }

  /// Incrementa el contador de intersticiales mostrados hoy
  Future<void> incrementInterstitialsShown() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyInterstitialsShownToday) ?? 0;
    await prefs.setInt(_keyInterstitialsShownToday, current + 1);
    await prefs.setString(_keyLastInterstitialDate, DateTime.now().toIso8601String());
  }

  /// Obtiene cuántos intersticiales se han mostrado hoy
  Future<int> getInterstitialsShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_keyLastInterstitialDate);
    
    if (lastDateStr == null) return 0;
    
    final lastDate = DateTime.parse(lastDateStr);
    final now = DateTime.now();
    
    // Si es un día diferente, resetear
    if (!_isSameDay(lastDate, now)) {
      await prefs.setInt(_keyInterstitialsShownToday, 0);
      return 0;
    }
    
    return prefs.getInt(_keyInterstitialsShownToday) ?? 0;
  }

  /// Resetea el contador de reportes (al cerrar la app)
  Future<void> resetSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReportsInSession, 0);
  }

  /// Verifica si dos fechas son del mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

