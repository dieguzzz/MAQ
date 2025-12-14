import 'package:flutter/material.dart';
import '../screens/reports/eta_validation_screen.dart';

/// Helper para navegación global desde notificaciones
class NavigationHelper {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static void handleNotificationNavigation(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    
    final type = data['type'];
    
    switch (type) {
      case 'eta_validation':
        final reportId = data['reportId'] as String?;
        final stationName = data['stationName'] as String? ?? 'la estación';
        
        if (reportId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => ETAValidationScreen(
                reportId: reportId,
                stationName: stationName,
              ),
            ),
          );
        }
        break;
      default:
        print('Tipo de notificación no manejado: $type');
    }
  }
}
