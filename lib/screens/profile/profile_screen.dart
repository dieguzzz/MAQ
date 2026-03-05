import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/level_progress_bar.dart';
import '../../widgets/profile_stats_card.dart';
import '../../widgets/profile_badges_preview.dart';
import '../settings/settings_screen.dart';
import '../reports/report_history_screen.dart';
import '../leaderboards/leaderboard_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Debes iniciar sesión'),
            );
          }

          final gamification = user.gamification;
          final puntos = gamification?.puntos ?? 0;
          final level = user.level;
          final levelName = user.levelName;
          final ranking = gamification?.ranking ?? 0;

          return CustomScrollView(
            slivers: [
              // SliverAppBar expandible
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    user.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[700]!,
                          Colors.blue[400]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: user.fotoUrl != null
                            ? NetworkImage(user.fotoUrl!)
                            : null,
                        child: user.fotoUrl == null
                            ? Text(
                                user.nombre[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Contenido
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nivel actual
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              levelName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nivel $level',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            LevelProgressBar(
                              currentPoints: puntos,
                              currentLevel: level,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Estadísticas
                    ProfileStatsCard(user: user),

                    // Badges recientes
                    ProfileBadgesPreview(
                      badges: gamification?.badges ?? [],
                    ),

                    // Ranking global
                    if (ranking > 0)
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events,
                              color: Colors.amber),
                          title: const Text('Ranking Global'),
                          subtitle: Text('Posición #$ranking'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaderboardScreen(),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events,
                              color: Colors.grey),
                          title: const Text('Ranking Global'),
                          subtitle: const Text('Aún no tienes ranking'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaderboardScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                    // Colección de Logros
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: ListTile(
                        leading:
                            const Icon(Icons.collections, color: Colors.purple),
                        title: const Text('Colección de Logros'),
                        subtitle: const Text('Explora tus logros y medallas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AchievementsScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Acciones
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Editar Perfil'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Historial de Reportes'),
                            subtitle:
                                Text('${user.reportesCount} reportes creados'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReportHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Configuración'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Botón de cerrar sesión
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () async {
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
