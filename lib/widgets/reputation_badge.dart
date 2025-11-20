import 'package:flutter/material.dart';

class ReputationBadge extends StatelessWidget {
  final int reputacion;
  final double size;

  const ReputationBadge({
    super.key,
    required this.reputacion,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (reputacion >= 501) {
      color = Colors.purple;
      icon = Icons.stars;
    } else if (reputacion >= 201) {
      color = Colors.blue;
      icon = Icons.verified;
    } else if (reputacion >= 51) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else {
      color = Colors.grey;
      icon = Icons.person;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }
}

