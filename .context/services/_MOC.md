---
title: Servicios - Map of Content
type: moc
tags: [service, moc]
last-updated: 2026-02-13
---

# ⚙️ Servicios (43 en total)

## Servicios Core

| Servicio                | Archivo                                 | Descripción                                              |
| ----------------------- | --------------------------------------- | -------------------------------------------------------- |
| FirebaseService         | `firebase_service.dart` (22KB)          | CRUD central Firestore: users, stations, trains, reports |
| SimplifiedReportService | `simplified_report_service.dart` (36KB) | Sistema nuevo de reportes                                |
| GamificationService     | `gamification_service.dart` (31KB)      | Puntos, niveles, badges, rachas, rankings                |
| ReportValidationService | `report_validation_service.dart` (7KB)  | Validación pre-envío de reportes                         |
| LocationService         | `location_service.dart` (3KB)           | GPS, permisos, streams de ubicación                      |
| NotificationService     | `notification_service.dart` (6KB)       | Push notifications (FCM + local)                         |
| MapService              | `map_service.dart` (13KB)               | Control del mapa, marcadores, polylines                  |

## Servicios de Ads y Monetización

| Servicio            | Archivo                           | Descripción                           |
| ------------------- | --------------------------------- | ------------------------------------- |
| AdService           | `ad_service.dart` (7KB)           | AdMob: banner, interstitial, rewarded |
| AdSessionService    | `ad_session_service.dart` (7KB)   | Frequency capping, sesiones           |
| SubscriptionService | `subscription_service.dart` (4KB) | In-app purchases                      |

## Servicios de Trenes y Estaciones

| Servicio                  | Archivo                                  | Descripción                   |
| ------------------------- | ---------------------------------------- | ----------------------------- |
| TrainSimulationService    | `train_simulation_service.dart` (9KB)    | Simulación trenes virtuales   |
| TrainStatusAggregator     | `train_status_aggregator.dart` (7KB)     | Agrega estado de trenes       |
| StationUpdateService      | `station_update_service.dart` (12KB)     | Actualiza estado estaciones   |
| StationStatusAggregator   | `station_status_aggregator.dart` (6KB)   | Agrega estado de estaciones   |
| StationCalibrationService | `station_calibration_service.dart` (5KB) | Calibra posiciones estaciones |
| MetroSimulatorService     | `metro_simulator_service.dart` (7KB)     | Simula metro completo         |

## Servicios de Confianza y Estimación

| Servicio                          | Archivo                                            | Descripción                |
| --------------------------------- | -------------------------------------------------- | -------------------------- |
| ConfidenceService                 | `confidence_service.dart` (2KB)                    | Niveles de confianza       |
| SimplifiedReportConfidenceService | `simplified_report_confidence_service.dart` (10KB) | Confianza mejorada         |
| TimeEstimationService             | `time_estimation_service.dart` (6KB)               | ETAs estimados             |
| ETAArrivalService                 | `eta_arrival_service.dart` (3KB)                   | Tiempos de llegada         |
| ETAGroupService                   | `eta_group_service.dart` (4KB)                     | Agrupación temporal ETA    |
| TrainTimeReportService            | `train_time_report_service.dart` (10KB)            | Reportes de tiempo de tren |

## Servicios de Gamificación

| Servicio              | Archivo                              | Descripción          |
| --------------------- | ------------------------------------ | -------------------- |
| LevelService          | `level_service.dart` (5KB)           | Cálculo niveles 1-50 |
| AccuracyService       | `accuracy_service.dart` (3KB)        | Precisión usuario    |
| PointsHistoryService  | `points_history_service.dart` (3KB)  | Historial puntos     |
| PointsRewardService   | `points_reward_service.dart` (3KB)   | Rewards de puntos    |
| ReportProgressService | `report_progress_service.dart` (3KB) | Progreso reportes    |

## Servicios de Aprendizaje / ML

| Servicio               | Archivo                               | Descripción           |
| ---------------------- | ------------------------------------- | --------------------- |
| AdminLearningService   | `admin_learning_service.dart` (11KB)  | Admin panel ML        |
| LearningReportService  | `learning_report_service.dart` (10KB) | Reportes de learning  |
| LearningStorageService | `learning_storage_service.dart` (3KB) | Storage para learning |
| StationLearningService | `station_learning_service.dart` (4KB) | Learning estaciones   |

## Servicios Auxiliares

| Servicio                  | Archivo                                  | Descripción             |
| ------------------------- | ---------------------------------------- | ----------------------- |
| AppModeService            | `app_mode_service.dart` (2KB)            | Dev/Test/Prod mode      |
| DevService                | `dev_service.dart` (13KB)                | Herramientas desarrollo |
| StorageService            | `storage_service.dart` (4KB)             | SharedPreferences       |
| ErrorHandlerService       | `error_handler_service.dart` (5KB)       | Manejo errores central  |
| DebugLogService           | `debug_log_service.dart` (3KB)           | Logging debug           |
| AlertService              | `alert_service.dart` (7KB)               | Alertas del sistema     |
| ScheduleService           | `schedule_service.dart` (5KB)            | Horarios del metro      |
| RouteCalculationService   | `route_calculation_service.dart` (5KB)   | Cálculo de rutas        |
| BackgroundLocationService | `background_location_service.dart` (4KB) | Ubicación background    |
| SimulatedTimeService      | `simulated_time_service.dart` (3KB)      | Tiempo simulado dev     |

## Servicios de Editor (Dev Tools)

| Servicio                     | Archivo                                      | Descripción       |
| ---------------------------- | -------------------------------------------- | ----------------- |
| StationEditModeService       | `station_edit_mode_service.dart` (1KB)       | Modo edición      |
| StationPositionEditorService | `station_position_editor_service.dart` (3KB) | Editor posiciones |
