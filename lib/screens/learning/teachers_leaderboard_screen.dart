import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../widgets/leaderboard_user_card.dart';
import '../../theme/metro_theme.dart';

/// Ranking de usuarios que más enseñan al algoritmo
class TeachersLeaderboardScreen extends StatelessWidget {
  const TeachersLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 Profesores del Metro'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firebaseService.getTeachersLeaderboardStream(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: MetroColors.stateCritical,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el ranking',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: MetroColors.grayMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay profesores',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sé el primero en ayudar a mejorar las predicciones',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MetroColors.grayDark,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .where((user) =>
                  (user.gamification?.teachingScore ?? 0) > 0 ||
                  (user.gamification?.teachingReportsCount ?? 0) > 0)
              .toList()
            ..sort((a, b) {
              final scoreA = a.gamification?.teachingScore ?? 0;
              final scoreB = b.gamification?.teachingScore ?? 0;
              return scoreB.compareTo(scoreA);
            });

          return Column(
            children: [
              // Header informativo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: MetroColors.blue.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: MetroColors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Los profesores ayudan a mejorar las predicciones del sistema',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: MetroColors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Lista de profesores
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final position = index + 1;
                    final isCurrentUser =
                        currentUser?.uid == user.uid;
                    final teachingScore =
                        user.gamification?.teachingScore ?? 0;
                    final teachingReportsCount =
                        user.gamification?.teachingReportsCount ?? 0;

                    return LeaderboardUserCard(
                      user: user,
                      position: position,
                      isCurrentUser: isCurrentUser,
                      displayValue:
                          '$teachingScore pts ($teachingReportsCount reportes)',
                    );
                  },
                ),
              ),
              // Badge info footer
              if (users.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: MetroColors.grayLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: MetroColors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Badge "Profesor del Metro" con 10+ reportes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MetroColors.grayDark,
                              fontWeight: FontWeight.w600,
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

