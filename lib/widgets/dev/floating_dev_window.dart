import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/dev_service.dart';
import 'dev_simulation_tab.dart';
import 'dev_metrics_tab.dart';
import 'dev_settings_tab.dart';
import 'dev_stations_tab.dart';
import 'dev_logs_tab.dart';

/// Ventana flotante draggable para modo desarrollador
class FloatingDevWindow extends StatefulWidget {
  const FloatingDevWindow({super.key});

  @override
  State<FloatingDevWindow> createState() => _FloatingDevWindowState();
}

class _FloatingDevWindowState extends State<FloatingDevWindow> {
  Offset _position = const Offset(50, 50);
  final double _width = 300;
  final double _height = 400;
  bool _isMinimized = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble('dev_window_x');
      final savedY = prefs.getDouble('dev_window_y');
      final savedMinimized = prefs.getBool('dev_window_minimized') ?? false;

      if (savedX != null && savedY != null) {
        setState(() {
          _position = Offset(savedX, savedY);
          _isMinimized = savedMinimized;
        });
      }
    } catch (e) {
      print('Error cargando posición: $e');
    }
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('dev_window_x', _position.dx);
      await prefs.setDouble('dev_window_y', _position.dy);
      await prefs.setBool('dev_window_minimized', _isMinimized);
    } catch (e) {
      print('Error guardando posición: $e');
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      // Mantener dentro de los límites de la pantalla
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      _position = Offset(
        _position.dx.clamp(0.0, screenWidth - (_isMinimized ? 60 : _width)),
        _position.dy.clamp(0.0, screenHeight - (_isMinimized ? 60 : _height)),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _savePosition();
    setState(() => _isDragging = false);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
    _savePosition();
  }

  void _closeWindow() {
    DevService.toggleDevMode();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DevService.devModeNotifier,
      builder: (context, devModeEnabled, child) {
        if (!devModeEnabled) {
          return const SizedBox.shrink();
        }

        if (_isMinimized) {
          return Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onTap: _toggleMinimize,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanStart: _onPanStart,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[800],
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bug_report,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          );
        }

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanStart: _onPanStart,
            child: Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header con controles
                  _buildHeader(),

                  // Contenido con tabs
                  const Expanded(
                    child: DefaultTabController(
                      length: 5,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            tabs: [
                              Tab(
                                icon: Icon(Icons.play_arrow),
                                text: 'Simular',
                              ),
                              Tab(
                                icon: Icon(Icons.analytics),
                                text: 'Métricas',
                              ),
                              Tab(
                                icon: Icon(Icons.tune),
                                text: 'Ajustes',
                              ),
                              Tab(
                                icon: Icon(Icons.train),
                                text: 'Estaciones',
                              ),
                              Tab(
                                icon: Icon(Icons.bug_report),
                                text: 'Logs',
                              ),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                DevSimulationTab(),
                                DevMetricsTab(),
                                DevSettingsTab(),
                                DevStationsTab(),
                                DevLogsTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bug_report,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Modo Desarrollador',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isMinimized ? Icons.open_in_full : Icons.minimize,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _toggleMinimize,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _closeWindow,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
