import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/logger.dart';

/// Pantalla de resumen que se muestra al volver a la app después de confirmar reportes
class ReportSummaryScreen extends StatefulWidget {
  final String? reportId; // ID del reporte que se confirmó (opcional)

  const ReportSummaryScreen({
    super.key,
    this.reportId,
  });

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen> {
  int _reportsToday = 0;
  int _totalPoints = 0;
  int _level = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtener datos del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final gamification = userData['gamification'] ?? {};

        setState(() {
          _totalPoints = gamification['puntos'] ?? 0;
          _level = gamification['nivel'] ?? 1;
        });
      }

      // Contar reportes de hoy
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .get();

      setState(() {
        _reportsToday = reportsSnapshot.size;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading summary: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(Icons.celebration, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                '🎉 ¡Bienvenido de vuelta!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aquí está tu resumen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 32),

              // Resumen de reportes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Tus Reportes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('Reportes hoy', '$_reportsToday'),
                      _buildStatRow('Total puntos', '$_totalPoints'),
                      _buildStatRow('Nivel actual', '$_level'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Experiencia ganada
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.trending_up,
                          size: 48, color: Colors.green),
                      const SizedBox(height: 8),
                      const Text(
                        'Experiencia Ganada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Has ayudado a $_reportsToday personas hoy',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Próximos objetivos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯 Próximos Objetivos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildObjective(
                          'Reportar 5 estaciones', _reportsToday >= 5),
                      _buildObjective('Alcanzar nivel 5', _level >= 5),
                      _buildObjective(
                          'Racha de 7 días', false), // TODO: Implementar
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CONTINUAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjective(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              decoration: completed ? TextDecoration.lineThrough : null,
              color: completed ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
