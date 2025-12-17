import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/metro_simulator_service.dart';
import '../../services/admin_learning_service.dart';
import '../../services/firebase_service.dart';
import '../../services/time_estimation_service.dart';
import '../../services/simulated_time_service.dart';
import '../../models/simulator_state_model.dart';
import '../../models/station_model.dart';
import '../../models/train_model.dart';
import '../../theme/metro_theme.dart';
import '../../utils/metro_data.dart';

/// Panel de administración completo: Simulador de Estación de Metro
/// Permite simular todos los aspectos de una estación para testing
class LearningAdminPanel extends StatefulWidget {
  const LearningAdminPanel({super.key});

  @override
  State<LearningAdminPanel> createState() => _LearningAdminPanelState();
}

class _LearningAdminPanelState extends State<LearningAdminPanel> {
  final MetroSimulatorService _simulator = MetroSimulatorService();
  final FirebaseService _firebaseService = FirebaseService();

  List<StationModel> _allStations = [];
  final TextEditingController _nextTrainController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  @override
  void dispose() {
    _nextTrainController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    final stations = await _firebaseService.getStations();
    setState(() {
      _allStations = stations.isEmpty ? MetroData.getAllStations() : stations;
      if (_allStations.isNotEmpty && _simulator.state.stationId == null) {
        _simulator.setStation(_allStations.first.id);
      }
    });
  }

  List<StationModel> get _filteredStations {
    final selectedLinea = _simulator.state.selectedLinea;
    if (selectedLinea == null) return _allStations;
    return _allStations.where((s) => s.linea == selectedLinea).toList();
  }

  StationModel? get _selectedStation {
    final stationId = _simulator.state.stationId;
    if (stationId == null) return null;
    try {
      return _allStations.firstWhere((s) => s.id == stationId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Simulador de Estación'),
        centerTitle: true,
      ),
      body: Consumer<MetroSimulatorService>(
        builder: (context, simulator, child) {
          return Column(
            children: [
              // Contenido principal scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStationSelection(simulator.state),
                      const SizedBox(height: 16),
                      _buildStationStatus(simulator.state),
                      const SizedBox(height: 16),
                      _buildTrainStatus(simulator.state),
                      const SizedBox(height: 16),
                      _buildPassengerLoad(simulator.state),
                      const SizedBox(height: 16),
                      _buildIncidents(simulator.state),
                      const SizedBox(height: 16),
                      _buildSimulatedLocation(simulator.state),
                      const SizedBox(height: 16),
                      _buildSpecialControls(simulator.state),
                    ],
                  ),
                ),
              ),
              // Log panel (colapsable)
              _buildLogPanel(simulator),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStationSelection(SimulatorState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1️⃣ Configuración de Estación',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Selector de línea
            Text(
              'Línea',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: state.selectedLinea == null,
                  onSelected: (selected) {
                    if (selected) {
                      _simulator.updateState(
                        state.copyWith(selectedLinea: null),
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Línea 1'),
                  selected: state.selectedLinea == 'linea1',
                  onSelected: (selected) {
                    if (selected) {
                      _simulator.updateState(
                        state.copyWith(selectedLinea: 'linea1'),
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Línea 2'),
                  selected: state.selectedLinea == 'linea2',
                  onSelected: (selected) {
                    if (selected) {
                      _simulator.updateState(
                        state.copyWith(selectedLinea: 'linea2'),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Selector de estación origen
            Text(
              'Estación Origen',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: state.stationId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.train),
              ),
              items: _filteredStations.map((station) {
                return DropdownMenuItem(
                  value: station.id,
                  child: Text(station.nombre),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _simulator.setStation(value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Selector de estación destino (opcional)
            Text(
              'Estación Destino (opcional)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: state.destinationStationId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
                hintText: 'Seleccione destino',
              ),
              items: _filteredStations
                  .where((s) => s.id != state.stationId)
                  .map((station) {
                return DropdownMenuItem(
                  value: station.id,
                  child: Text(station.nombre),
                );
              }).toList(),
              onChanged: (value) {
                _simulator.updateState(
                  state.copyWith(destinationStationId: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationStatus(SimulatorState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2️⃣ Estado de la Estación',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Estado de la estación
            Text(
              'Estado',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(
                  'Operativa',
                  state.stationStatus == SimulatorStationStatus.operativa,
                  MetroColors.green,
                  () => _simulator.setStationStatus(
                    SimulatorStationStatus.operativa,
                  ),
                ),
                _buildStatusChip(
                  'Cerrada',
                  state.stationStatus == SimulatorStationStatus.cerrada,
                  MetroColors.stateCritical,
                  () => _simulator.setStationStatus(
                    SimulatorStationStatus.cerrada,
                  ),
                ),
                _buildStatusChip(
                  'Acceso Parcial',
                  state.stationStatus == SimulatorStationStatus.accesoParcial,
                  MetroColors.energyOrange,
                  () => _simulator.setStationStatus(
                    SimulatorStationStatus.accesoParcial,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Aforo
            Text(
              'Aforo',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Slider(
              value: state.aglomeracion.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _getAforoLabel(state.aglomeracion),
              onChanged: (value) {
                _simulator.updateState(
                  state.copyWith(aglomeracion: value.round()),
                );
              },
            ),
            Text(
              _getAforoLabel(state.aglomeracion),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainStatus(SimulatorState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3️⃣ Estado del Tren',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Botones grandes de estado
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBigButton(
                  '🚇 Tren Llegando',
                  state.trainStatus == SimulatorTrainStatus.llegando,
                  MetroColors.blue,
                  () => _simulator.setTrainStatus(
                    SimulatorTrainStatus.llegando,
                  ),
                ),
                _buildBigButton(
                  '⏸️ Tren en Estación',
                  state.trainStatus == SimulatorTrainStatus.enEstacion,
                  MetroColors.green,
                  () => _simulator.setTrainStatus(
                    SimulatorTrainStatus.enEstacion,
                  ),
                ),
                _buildBigButton(
                  '🚇 Tren Saliendo',
                  state.trainStatus == SimulatorTrainStatus.saliendo,
                  MetroColors.energyOrange,
                  () => _simulator.setTrainStatus(
                    SimulatorTrainStatus.saliendo,
                  ),
                ),
                _buildBigButton(
                  '❌ Sin Tren',
                  state.trainStatus == SimulatorTrainStatus.sinTren,
                  MetroColors.grayMedium,
                  () => _simulator.setTrainStatus(
                    SimulatorTrainStatus.sinTren,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tiempo hasta próximo tren
            Text(
              'Próximo tren en (segundos)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nextTrainController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej: 30',
                      suffixText: 'seg',
                    ),
                    onChanged: (value) {
                      final seconds = int.tryParse(value);
                      _simulator.setNextTrainInSeconds(seconds);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _nextTrainController.clear();
                    _simulator.setNextTrainInSeconds(null);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerLoad(SimulatorState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '4️⃣ Carga de Pasajeros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLoadChip(
                  'Baja',
                  state.passengerLoad == SimulatorPassengerLoad.baja,
                  MetroColors.green,
                  () => _simulator.setPassengerLoad(
                    SimulatorPassengerLoad.baja,
                  ),
                ),
                _buildLoadChip(
                  'Media',
                  state.passengerLoad == SimulatorPassengerLoad.media,
                  MetroColors.energyOrange,
                  () => _simulator.setPassengerLoad(
                    SimulatorPassengerLoad.media,
                  ),
                ),
                _buildLoadChip(
                  'Alta',
                  state.passengerLoad == SimulatorPassengerLoad.alta,
                  MetroColors.stateModerate,
                  () => _simulator.setPassengerLoad(
                    SimulatorPassengerLoad.alta,
                  ),
                ),
                _buildLoadChip(
                  'Completa',
                  state.passengerLoad == SimulatorPassengerLoad.completa,
                  MetroColors.stateCritical,
                  () => _simulator.setPassengerLoad(
                    SimulatorPassengerLoad.completa,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidents(SimulatorState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5️⃣ Simulación de Incidentes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SimulatorIncidentType>(
              value: state.incidentType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
              ),
              items: SimulatorIncidentType.values.map((incident) {
                return DropdownMenuItem(
                  value: incident,
                  child: Text(_getIncidentLabel(incident)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _simulator.setIncident(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatedLocation(SimulatorState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '6️⃣ Ubicación Falsa (GPS)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLocationButton(
                  '📍 En la Estación',
                  state.simulatedLocation == SimulatorLocationType.enEstacion,
                  MetroColors.green,
                  () => _simulator.setSimulatedLocation(
                    SimulatorLocationType.enEstacion,
                  ),
                ),
                _buildLocationButton(
                  '🚶 Acercándose',
                  state.simulatedLocation == SimulatorLocationType.acercandose,
                  MetroColors.energyOrange,
                  () => _simulator.setSimulatedLocation(
                    SimulatorLocationType.acercandose,
                  ),
                ),
                _buildLocationButton(
                  '🚗 Fuera',
                  state.simulatedLocation == SimulatorLocationType.fuera,
                  MetroColors.grayMedium,
                  () => _simulator.setSimulatedLocation(
                    SimulatorLocationType.fuera,
                  ),
                ),
                _buildLocationButton(
                  '❌ Sin Simular',
                  state.simulatedLocation == null,
                  MetroColors.grayLight,
                  () => _simulator.setSimulatedLocation(null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialControls(SimulatorState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '7️⃣ Controles Especiales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Modo automático
            SwitchListTile(
              title: const Text('Modo Automático'),
              subtitle: const Text(
                'Ciclo automático: tren llegando → en estación → saliendo',
              ),
              value: state.isAutoMode,
              onChanged: (value) {
                _simulator.setAutoMode(value);
              },
            ),
            const SizedBox(height: 8),
            // Botón Reset
            ElevatedButton.icon(
              onPressed: () {
                _simulator.reset();
                _nextTrainController.clear();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MetroColors.grayMedium,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogPanel(MetroSimulatorService simulator) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: MetroColors.grayLight,
        border: Border(
          top: BorderSide(color: MetroColors.grayMedium, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header del log
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: MetroColors.grayMedium,
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Log',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => simulator.clearLogs(),
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Contenido del log
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: simulator.logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    simulator.logs[index],
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widgets auxiliares
  Widget _buildStatusChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : MetroColors.grayDark,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBigButton(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? color : color.withOpacity(0.3),
          foregroundColor: selected ? Colors.white : color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: color,
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        radius: 12,
        child: Icon(
          _getLoadIcon(label),
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLocationButton(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? color : MetroColors.grayDark,
        side: BorderSide(
          color: selected ? color : MetroColors.grayMedium,
          width: selected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }

  String _getAforoLabel(int value) {
    switch (value) {
      case 1:
        return 'Normal';
      case 2:
        return 'Moderado';
      case 3:
        return 'Alto';
      case 4:
        return 'Muy Alto';
      case 5:
        return 'Completo';
      default:
        return 'Normal';
    }
  }

  IconData _getLoadIcon(String label) {
    switch (label) {
      case 'Baja':
        return Icons.people_outline;
      case 'Media':
        return Icons.people;
      case 'Alta':
        return Icons.people_alt;
      case 'Completa':
        return Icons.people_alt_outlined;
      default:
        return Icons.people;
    }
  }

  String _getIncidentLabel(SimulatorIncidentType incident) {
    switch (incident) {
      case SimulatorIncidentType.ninguno:
        return 'Ninguno';
      case SimulatorIncidentType.averiaTren:
        return 'Avería en Tren';
      case SimulatorIncidentType.averiaVias:
        return 'Avería en Vías';
      case SimulatorIncidentType.retraso:
        return 'Retraso';
      case SimulatorIncidentType.personaEnVias:
        return 'Persona en Vías';
      case SimulatorIncidentType.emergencia:
        return 'Emergencia';
    }
  }
}
