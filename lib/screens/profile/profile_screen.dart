import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/metro_theme.dart';
import '../../widgets/level_progress_bar.dart';
import '../../widgets/profile_stats_card.dart';
import '../../widgets/profile_badges_preview.dart';
import '../settings/settings_screen.dart';
import '../reports/report_history_screen.dart';
import '../leaderboards/leaderboard_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/achievements_screen.dart';
import '../../widgets/guest_upgrade_dialog.dart';
import '../../widgets/google_logo.dart';

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

          final isGuest = authProvider.isGuest;
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
                      color: MetroColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MetroColors.blue,
                          MetroColors.blue.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: MetroColors.white,
                        backgroundImage: user.fotoUrl != null
                            ? NetworkImage(user.fotoUrl!)
                            : null,
                        child: user.fotoUrl == null
                            ? Text(
                                user.nombre[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: MetroColors.blue,
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
                    // CTA para invitados
                    if (isGuest)
                      Card(
                        margin: const EdgeInsets.all(16),
                        color: MetroColors.blue.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: MetroColors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.lock_open, size: 48, color: MetroColors.blue),
                              const SizedBox(height: 12),
                              const Text(
                                'Desbloquea todo el potencial',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vincula tu cuenta de Google para acceder a reportes, rutas, logros y más.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: MetroColors.grayDark.withValues(alpha: 0.7)),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => GuestUpgradeDialog.show(context, feature: 'todas las funciones'),
                                  icon: const GoogleLogo(size: 20),
                                  label: const Text('Vincular con Google'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MetroColors.blue,
                                    foregroundColor: MetroColors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Nivel actual
                    _buildMaybeLockedSection(
                      context,
                      isGuest: isGuest,
                      feature: 'logros',
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                isGuest ? 'Pasajero Novato' : levelName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isGuest ? 'Nivel 1' : 'Nivel $level',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      MetroColors.grayDark.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              LevelProgressBar(
                                currentPoints: isGuest ? 0 : puntos,
                                currentLevel: isGuest ? 1 : level,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Estadísticas
                    _buildMaybeLockedSection(
                      context,
                      isGuest: isGuest,
                      feature: 'logros',
                      child: ProfileStatsCard(user: user),
                    ),

                    // Badges recientes
                    _buildMaybeLockedSection(
                      context,
                      isGuest: isGuest,
                      feature: 'logros',
                      child: ProfileBadgesPreview(
                        badges: gamification?.badges ?? [],
                      ),
                    ),

                    if (!isGuest) ...[
                    // Ranking global
                    if (ranking > 0)
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events,
                              color: MetroColors.red),
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
                              color: MetroColors.grayMedium),
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
                        leading: const Icon(Icons.collections,
                            color: MetroColors.blue),
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
                    ], // end !isGuest

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
                          backgroundColor: MetroColors.stateCritical,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: MetroColors.white),
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

  Widget _buildMaybeLockedSection(
    BuildContext context, {
    required bool isGuest,
    required String feature,
    required Widget child,
  }) {
    if (!isGuest) return child;
    return GestureDetector(
      onTap: () => GuestUpgradeDialog.show(context, feature: feature),
      child: Stack(
        children: [
          Opacity(opacity: 0.3, child: IgnorePointer(child: child)),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MetroColors.grayDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, size: 28, color: MetroColors.grayDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
