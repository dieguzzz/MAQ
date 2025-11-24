import '../models/train_model.dart';

class TrainSimulationConfig {
  const TrainSimulationConfig({
    required this.trainId,
    required this.initialProgress,
    required this.speedFactor,
  });

  final String trainId;
  final double initialProgress;
  final double speedFactor;
}

class TrainSimulationTable {
  static final List<TrainSimulationConfig> _records = [
    const TrainSimulationConfig(
      trainId: 'train_l1_norte_1',
      initialProgress: 0.05,
      speedFactor: 1.0,
    ),
    const TrainSimulationConfig(
      trainId: 'train_l1_sur_1',
      initialProgress: 0.55,
      speedFactor: 0.8,
    ),
    const TrainSimulationConfig(
      trainId: 'train_l1_norte_2',
      initialProgress: 0.35,
      speedFactor: 1.2,
    ),
    const TrainSimulationConfig(
      trainId: 'train_l2_este_1',
      initialProgress: 0.15,
      speedFactor: 1.1,
    ),
    const TrainSimulationConfig(
      trainId: 'train_l2_oeste_1',
      initialProgress: 0.65,
      speedFactor: 0.9,
    ),
    const TrainSimulationConfig(
      trainId: 'train_l2_este_2',
      initialProgress: 0.4,
      speedFactor: 1.0,
    ),
  ];

  static TrainSimulationConfig? getConfig(String trainId) {
    try {
      return _records.firstWhere((record) => record.trainId == trainId);
    } catch (_) {
      return null;
    }
  }

  static double getInitialProgress(String trainId) {
    return getConfig(trainId)?.initialProgress ?? 0.0;
  }

  static double getSpeedFactor(String trainId, TrainModel train) {
    return getConfig(trainId)?.speedFactor ?? (train.velocidad / 40).clamp(0.5, 2.0);
  }
}

