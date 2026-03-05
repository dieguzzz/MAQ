import 'package:get_it/get_it.dart';

// core
import '../services/core/app_mode_service.dart';
import '../services/core/dev_service.dart';
import '../services/core/error_handler_service.dart';
import '../services/core/firebase_service.dart';
import '../services/core/notification_service.dart';
import '../services/core/storage_service.dart';

// ads
import '../services/ads/ad_service.dart';
import '../services/ads/ad_session_service.dart';

// location
import '../services/location/background_location_service.dart';
import '../services/location/location_service.dart';
import '../services/location/map_service.dart';
import '../services/location/route_calculation_service.dart';

// stations
import '../services/stations/station_update_service.dart';

// gamification
import '../services/gamification/gamification_service.dart';
import '../services/gamification/level_service.dart';
import '../services/gamification/points_history_service.dart';
import '../services/gamification/points_reward_service.dart';

// premium
import '../services/premium/alert_service.dart';
import '../services/premium/subscription_service.dart';

// learning
import '../services/learning/admin_learning_service.dart';
import '../services/learning/learning_report_service.dart';
import '../services/learning/learning_storage_service.dart';
import '../services/learning/station_learning_service.dart';

// reports
import '../services/reports/accuracy_service.dart';
import '../services/reports/confidence_service.dart';
import '../services/reports/enhanced_report_service.dart';
import '../services/reports/report_progress_service.dart';
import '../services/reports/report_validation_service.dart';
import '../services/reports/simplified_report_service.dart';

// simulation
import '../services/simulation/schedule_service.dart';
import '../services/simulation/simulated_time_service.dart';
import '../services/simulation/time_estimation_service.dart';
import '../services/simulation/train_simulation_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Core
  getIt.registerLazySingleton(() => AppModeService());
  getIt.registerLazySingleton(() => DevService());
  getIt.registerLazySingleton(() => ErrorHandlerService());
  getIt.registerLazySingleton(() => FirebaseService());
  getIt.registerLazySingleton(() => NotificationService());
  getIt.registerLazySingleton(() => StorageService());

  // Ads
  getIt.registerLazySingleton(() => AdService.instance);
  getIt.registerLazySingleton(() => AdSessionService.instance);

  // Location
  getIt.registerLazySingleton(() => BackgroundLocationService());
  getIt.registerLazySingleton(() => LocationService());
  getIt.registerLazySingleton(() => MapService());
  getIt.registerLazySingleton(() => RouteCalculationService());

  // Stations
  getIt.registerLazySingleton(() => StationUpdateService());

  // Gamification
  getIt.registerLazySingleton(() => GamificationService());
  getIt.registerLazySingleton(() => LevelService());
  getIt.registerLazySingleton(() => PointsHistoryService());
  getIt.registerLazySingleton(() => PointsRewardService());

  // Premium
  getIt.registerLazySingleton(() => AlertService());
  getIt.registerLazySingleton(() => SubscriptionService());

  // Learning
  getIt.registerLazySingleton(() => AdminLearningService());
  getIt.registerLazySingleton(() => LearningReportService());
  getIt.registerLazySingleton(() => LearningStorageService());
  getIt.registerLazySingleton(() => StationLearningService());

  // Reports
  getIt.registerLazySingleton(() => AccuracyService());
  getIt.registerLazySingleton(() => ConfidenceService());
  getIt.registerLazySingleton(() => EnhancedReportService());
  getIt.registerLazySingleton(() => ReportProgressService());
  getIt.registerLazySingleton(() => ReportValidationService());
  getIt.registerLazySingleton(() => SimplifiedReportService());

  // Simulation
  getIt.registerLazySingleton(() => ScheduleService());
  getIt.registerLazySingleton(() => SimulatedTimeService());
  getIt.registerLazySingleton(() => TimeEstimationService());
  getIt.registerLazySingleton(() => TrainSimulationService());
}
