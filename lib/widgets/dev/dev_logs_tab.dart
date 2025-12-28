import 'package:flutter/material.dart';
import '../../services/debug_log_service.dart';
import '../../services/app_mode_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Tab para ver logs de depuración en modo test
class DevLogsTab extends StatefulWidget {
  const DevLogsTab({super.key});

  @override
  State<DevLogsTab> createState() => _DevLogsTabState();
}

class _DevLogsTabState extends State<DevLogsTab> {
  final DebugLogService _logService = DebugLogService();
  String? _selectedCategory;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    return FutureBuilder<bool>(
      future: userId != null 
          ? AppModeService().isTestMode(userId)
          : Future.value(false),
      builder: (context, snapshot) {
        final isTestMode = snapshot.data ?? false;

        if (!isTestMode) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Los logs solo están disponibles en modo test',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Activa el modo test en Configuración',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Controles
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[800],
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      hint: const Text(
                        'Todas las categorías',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ReportsStream',
                          child: Text('ReportsStream'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ConfirmReports',
                          child: Text('ConfirmReports'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _autoScroll ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _autoScroll = !_autoScroll;
                      });
                    },
                    tooltip: _autoScroll ? 'Auto-scroll activado' : 'Auto-scroll desactivado',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: () {
                      _logService.clearLogs();
                      setState(() {});
                    },
                    tooltip: 'Limpiar logs',
                  ),
                ],
              ),
            ),
            // Lista de logs
            Expanded(
              child: StreamBuilder<List<DebugLogEntry>>(
                stream: Stream.periodic(const Duration(milliseconds: 500), (_) {
                  final logs = _selectedCategory == null
                      ? _logService.getLogs()
                      : _logService.getLogsByCategory(_selectedCategory!);
                  if (_autoScroll) {
                    _scrollToBottom();
                  }
                  return logs;
                }),
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? _logService.getLogs();

                  if (logs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay logs aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(4),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogItem(log);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogItem(DebugLogEntry log) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (log.level) {
      case LogLevel.info:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue[200]!;
        icon = Icons.info_outline;
        break;
      case LogLevel.success:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green[200]!;
        icon = Icons.check_circle_outline;
        break;
      case LogLevel.warning:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange[200]!;
        icon = Icons.warning_amber_rounded;
        break;
      case LogLevel.error:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red[200]!;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.formattedTime,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.category,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

