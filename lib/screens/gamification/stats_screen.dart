import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/gamification_model.dart';
import 'points_history_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Mis Estadísticas'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          final stats = user?.gamification;

          if (user == null) {
            return const Center(child: Text('Debes iniciar sesión'));
          }

          if (stats == null) {
            return const Center(
              child: Text('No hay estadísticas disponibles'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nivel y puntos
                _buildLevelCard(stats, context),
                const SizedBox(height: 16),

                // Streak
                _buildStreakCard(stats),
                const SizedBox(height: 16),

                // Precisión
                _buildAccuracyCard(stats),
                const SizedBox(height: 16),

                // Impacto
                _buildImpactCard(stats),
                const SizedBox(height: 16),

                // Rankings
                _buildRankingCard(stats),
                const SizedBox(height: 16),

                // Badges
                _buildBadgesCard(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelCard(GamificationStats stats, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navegar a la pantalla de historial de puntos
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PointsHistoryScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.getNivelNombre(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stats.getNivelDescripcion(),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.history,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: stats.puntos / 1000, // Ajustar según máximo
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.puntos} puntos',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    'Toca para ver historial',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(GamificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Racha Actual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('${stats.streak} días consecutivos'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard(GamificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precisión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('${(stats.precision * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats.precision,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Text('${stats.reportesVerificados} reportes confirmados'),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard(GamificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImpactItem(
                  '👥',
                  'Verificaciones',
                  '${stats.verificacionesHechas}',
                ),
                _buildImpactItem(
                  '✅',
                  'Reportes',
                  '${stats.reportesVerificados}',
                ),
                _buildImpactItem(
                  '👤',
                  'Seguidores',
                  '${stats.seguidores}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 30)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRankingCard(GamificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rankings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRankingItem('🌍', 'Global', stats.ranking),
            const SizedBox(height: 8),
            _buildRankingItem('🔵', 'Línea 1', stats.rankingLinea1),
            const SizedBox(height: 8),
            _buildRankingItem('🟢', 'Línea 2', stats.rankingLinea2),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(String emoji, String label, int ranking) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          ranking > 0 ? '#$ranking' : 'N/A',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesCard(GamificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badges Desbloqueados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (stats.badges.isEmpty)
              const Text('Aún no has desbloqueado badges')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stats.badges.map((badge) {
                  return Chip(
                    avatar: Text(badge.icono),
                    label: Text(badge.nombre),
                    onDeleted: null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

