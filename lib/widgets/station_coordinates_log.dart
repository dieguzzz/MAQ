import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/station_position_editor_service.dart';
import '../theme/metro_theme.dart';

/// Widget que muestra un log de coordenadas de estaciones editadas
/// Visible solo en modo test
class StationCoordinatesLog extends StatelessWidget {
  const StationCoordinatesLog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StationPositionEditorService>(
      builder: (context, editor, child) {
        // Solo mostrar si el editor está habilitado y hay coordenadas editadas
        if (!editor.isEnabled) {
          return const SizedBox.shrink();
        }

        final editedPositions = editor.getAllPositions();
        if (editedPositions.isEmpty && editor.logs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: MetroColors.grayLight,
            border: Border(
              top: BorderSide(color: MetroColors.grayMedium, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MetroColors.blue,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.code, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Coordenadas Editadas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        final text = editor.getCoordinatesAsText();
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coordenadas copiadas al portapapeles'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                      label: const Text(
                        'Copiar',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => editor.clearLogs(),
                      child: const Text(
                        'Limpiar',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        editor.reset();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Posiciones reseteadas'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: Row(
                  children: [
                    // Panel de coordenadas
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (editedPositions.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'No hay coordenadas editadas',
                                    style: TextStyle(
                                      color: MetroColors.grayDark,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ...editedPositions.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: SelectableText(
                                      "'${entry.key}': [${entry.value.latitude.toStringAsFixed(6)}, ${entry.value.longitude.toStringAsFixed(6)}]",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      color: MetroColors.grayMedium,
                    ),
                    // Panel de logs
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: ListView.builder(
                          reverse: true,
                          itemCount: editor.logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                editor.logs[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: MetroColors.grayDark,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

