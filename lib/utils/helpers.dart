// Note: intl package is optional for date formatting
// Using basic DateTime formatting instead

class Helpers {
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static String formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours h';
      }
      return '$hours h $mins min';
    }
  }

  static String getEstadoEstacionText(String estado) {
    switch (estado) {
      case 'normal':
        return 'Normal';
      case 'congestionado':
        return 'Congestionado';
      case 'cerrado':
        return 'Cerrado';
      default:
        return 'Desconocido';
    }
  }

  static String getEstadoTrenText(String estado) {
    switch (estado) {
      case 'normal':
        return 'Normal';
      case 'retrasado':
        return 'Retrasado';
      case 'detenido':
        return 'Detenido';
      default:
        return 'Desconocido';
    }
  }
}

