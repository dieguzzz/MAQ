import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankingsScreen extends StatefulWidget {
  final String? lineaFiltro;

  const RankingsScreen({super.key, this.lineaFiltro});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Rankings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Línea 1'),
            Tab(text: 'Línea 2'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRankingList(null),
          _buildRankingList('linea1'),
          _buildRankingList('linea2'),
        ],
      ),
    );
  }

  Widget _buildRankingList(String? linea) {
    Query query = _firestore.collection('users');

    if (linea != null) {
      // Ordenar por puntos de la línea específica
      // Nota: Esto requiere una estructura de datos diferente
      // Por ahora ordenamos por puntos globales
      query = query.orderBy('gamification.puntos', descending: true);
    } else {
      query = query.orderBy('gamification.puntos', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final gamification = userData['gamification'] as Map<String, dynamic>?;
            final puntos = gamification?['puntos'] ?? 0;
            final ranking = index + 1;

            return _buildRankingItem(
              ranking,
              userData['nombre'] ?? 'Usuario',
              puntos,
              userData['foto_url'],
            );
          },
        );
      },
    );
  }

  Widget _buildRankingItem(int ranking, String nombre, int puntos, String? fotoUrl) {
    IconData medalIcon;
    Color medalColor;

    if (ranking == 1) {
      medalIcon = Icons.emoji_events;
      medalColor = Colors.amber;
    } else if (ranking == 2) {
      medalIcon = Icons.emoji_events;
      medalColor = Colors.grey[400]!;
    } else if (ranking == 3) {
      medalIcon = Icons.emoji_events;
      medalColor = Colors.brown[300]!;
    } else {
      medalIcon = Icons.circle;
      medalColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: medalColor,
        child: ranking <= 3
            ? Icon(medalIcon, color: Colors.white)
            : Text(
                '$ranking',
                style: const TextStyle(color: Colors.white),
              ),
      ),
      title: Text(nombre),
      subtitle: Text('$puntos puntos'),
      trailing: fotoUrl != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(fotoUrl),
              radius: 20,
            )
          : null,
    );
  }
}

