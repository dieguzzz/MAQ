import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../theme/metro_theme.dart';
import '../../widgets/leaderboard_user_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedLeaderboard = 'global';
  final FirebaseService _firebaseService = FirebaseService();

  static const Map<String, String> leaderboardTypes = {
    'global': '🏆 Ranking Global',
    'linea1': '🔵 Línea 1 - Top Contribuidores',
    'linea2': '🟢 Línea 2 - Top Contribuidores',
    'accuracy': '🎯 Más Precisos',
    'streak': '🔥 Rachas Activas',
    'helpers': '🤝 Más Reportes Verificados',
  };

  Stream<QuerySnapshot> _getLeaderboardStream() {
    switch (_selectedLeaderboard) {
      case 'global':
        return _firebaseService.getGlobalLeaderboardStream();
      case 'linea1':
      case 'linea2':
        final linea = _selectedLeaderboard == 'linea1' ? 'Línea 1' : 'Línea 2';
        return _firebaseService.getLineaLeaderboardStream(linea);
      case 'accuracy':
        return _firebaseService.getAccuracyLeaderboardStream();
      case 'streak':
        return _firebaseService.getStreakLeaderboardStream();
      case 'helpers':
        return _firebaseService.getHelpersLeaderboardStream();
      default:
        return _firebaseService.getGlobalLeaderboardStream();
    }
  }

  List<UserModel> _filterUsersByLinea(List<UserModel> users, String linea) {
    if (_selectedLeaderboard != 'linea1' && _selectedLeaderboard != 'linea2') {
      return users;
    }

    return users.where((user) {
      final puntosPorLinea = user.gamification?.puntosPorLinea ?? {};
      return puntosPorLinea.containsKey(linea) &&
          (puntosPorLinea[linea] ?? 0) > 0;
    }).toList()
      ..sort((a, b) {
        final puntosA = a.gamification?.puntosPorLinea[linea] ?? 0;
        final puntosB = b.gamification?.puntosPorLinea[linea] ?? 0;
        return puntosB.compareTo(puntosA);
      });
  }

  String _getUserDisplayValue(UserModel user) {
    switch (_selectedLeaderboard) {
      case 'accuracy':
        return '${user.precision.toStringAsFixed(1)}%';
      case 'streak':
        return '${user.gamification?.streak ?? 0} días';
      case 'helpers':
        return '${user.gamification?.verificacionesHechas ?? 0} verificaciones';
      case 'linea1':
      case 'linea2':
        final linea = _selectedLeaderboard == 'linea1' ? 'Línea 1' : 'Línea 2';
        final puntos = user.gamification?.puntosPorLinea[linea] ?? 0;
        return '$puntos pts';
      default:
        return '${user.gamification?.puntos ?? 0} pts';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return PopScope(
      canPop: true, // Permitir pop normal para pantallas secundarias
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🏆 Rankings'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Selector de leaderboards
            _buildLeaderboardSelector(),

            // Contenido del leaderboard
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getLeaderboardStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: MetroColors.stateCritical),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events,
                              size: 64, color: MetroColors.grayMedium),
                          const SizedBox(height: 16),
                          Text(
                            'No hay usuarios en el ranking aún',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  MetroColors.grayDark.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var users = snapshot.data!.docs
                      .map((doc) => UserModel.fromFirestore(doc))
                      .toList();

                  // Filtrar por línea si es necesario
                  if (_selectedLeaderboard == 'linea1' ||
                      _selectedLeaderboard == 'linea2') {
                    final linea = _selectedLeaderboard == 'linea1'
                        ? 'Línea 1'
                        : 'Línea 2';
                    users = _filterUsersByLinea(users, linea);
                  }

                  // Limitar a top 50 para leaderboards especializados
                  if (_selectedLeaderboard != 'global') {
                    users = users.take(50).toList();
                  }

                  // Encontrar posición del usuario actual
                  int? currentUserPosition;
                  if (currentUser != null) {
                    for (int i = 0; i < users.length; i++) {
                      if (users[i].uid == currentUser.uid) {
                        currentUserPosition = i + 1;
                        break;
                      }
                    }
                  }

                  return Column(
                    children: [
                      // Header con top 3 (solo para global)
                      if (_selectedLeaderboard == 'global' && users.length >= 3)
                        _buildTopThreeHeader(users),

                      // Lista de usuarios
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final position = index + 1;
                            final isCurrentUser = currentUser != null &&
                                user.uid == currentUser.uid;

                            return LeaderboardUserCard(
                              user: user,
                              position: position,
                              isCurrentUser: isCurrentUser,
                              displayValue: _getUserDisplayValue(user),
                            );
                          },
                        ),
                      ),

                      // Indicador de posición del usuario actual
                      if (currentUserPosition != null &&
                          currentUserPosition > 3)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: MetroColors.blue.withValues(alpha: 0.08),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline,
                                  color: MetroColors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Tu posición: #$currentUserPosition',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: MetroColors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: leaderboardTypes.entries.map((entry) {
          final isSelected = _selectedLeaderboard == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedLeaderboard = entry.key;
                  });
                }
              },
              selectedColor: MetroColors.blue.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                color: isSelected ? MetroColors.white : MetroColors.grayDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopThreeHeader(List<UserModel> users) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MetroColors.blue.withValues(alpha: 0.08),
            MetroColors.blue.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Segundo lugar
          if (users.length >= 2)
            _buildTopThreeCard(users[1], 2, MetroColors.grayMedium),

          // Primer lugar (más grande)
          if (users.isNotEmpty)
            _buildTopThreeCard(users[0], 1, MetroColors.energyOrange,
                isFirst: true),

          // Tercer lugar
          if (users.length >= 3)
            _buildTopThreeCard(users[2], 3, MetroColors.blue),
        ],
      ),
    );
  }

  Widget _buildTopThreeCard(UserModel user, int position, Color color,
      {bool isFirst = false}) {
    final size = isFirst ? 80.0 : 60.0;
    final level = user.level;
    final displayValue = _getUserDisplayValue(user);

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: MetroColors.white, width: 3),
          ),
          child: Center(
            child: user.fotoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.fotoUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    user.nombre[0].toUpperCase(),
                    style: TextStyle(
                      color: MetroColors.white,
                      fontSize: isFirst ? 32 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.nombre,
          style: TextStyle(
            fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
            fontSize: isFirst ? 14 : 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Nivel $level',
          style: TextStyle(
            fontSize: isFirst ? 12 : 10,
            color: MetroColors.grayDark.withValues(alpha: 0.7),
          ),
        ),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: isFirst ? 12 : 10,
            color: MetroColors.grayDark.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
