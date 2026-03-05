import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ReputationWidget extends StatelessWidget {
  const ReputationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        final reputacion = user.reputacion;
        final nivel = user.getNivelReputacion();

        Color nivelColor;
        IconData nivelIcon;

        if (reputacion >= 501) {
          nivelColor = Colors.purple;
          nivelIcon = Icons.stars;
        } else if (reputacion >= 201) {
          nivelColor = Colors.blue;
          nivelIcon = Icons.verified;
        } else if (reputacion >= 51) {
          nivelColor = Colors.green;
          nivelIcon = Icons.check_circle;
        } else {
          nivelColor = Colors.grey;
          nivelIcon = Icons.person;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(nivelIcon, color: nivelColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nivel,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: nivelColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$reputacion puntos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: reputacion / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(nivelColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '$reputacion/100 puntos de reputación',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
