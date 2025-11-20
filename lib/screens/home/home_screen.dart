import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import 'map_widget.dart';
import '../../widgets/quick_report_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MetroPTY'),
        actions: [
          Consumer<MetroDataProvider>(
            builder: (context, metroProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (String? value) {
                  metroProvider.setSelectedLinea(value);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: null,
                    child: Text('Todas las líneas'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'linea1',
                    child: Text('Línea 1'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'linea2',
                    child: Text('Línea 2'),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navegar a notificaciones
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const MapWidget(),
          const Positioned(
            bottom: 20,
            right: 20,
            child: QuickReportButton(),
          ),
        ],
      ),
      floatingActionButton: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return FloatingActionButton(
            onPressed: () {
              locationProvider.getCurrentLocation();
            },
            child: const Icon(Icons.my_location),
          );
        },
      ),
    );
  }
}

