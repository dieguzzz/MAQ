---
title: Modelos de Datos - Map of Content
type: moc
tags: [model, moc]
last-updated: 2026-02-13
---

# 📦 Modelos de Datos

## 15 modelos en `lib/models/`

### Modelos Core

| Modelo                      | Archivo                        | Colección Firestore       |
| --------------------------- | ------------------------------ | ------------------------- |
| [[user-model]]              | `user_model.dart`              | `users/{uid}`             |
| [[station-model]]           | `station_model.dart`           | `stations/{stationId}`    |
| [[train-model]]             | `train_model.dart`             | `trains/{trainId}`        |
| [[report-model]]            | `report_model.dart`            | `reports/{reportId}`      |
| [[simplified-report-model]] | `simplified_report_model.dart` | `simplified_reports/{id}` |

### Modelos de Gamificación

| Modelo              | Archivo                         |
| ------------------- | ------------------------------- |
| `GamificationStats` | `gamification_model.dart`       |
| `Badge`             | `badge_model.dart`              |
| `PointsTransaction` | `points_transaction_model.dart` |

### Modelos de Simulación y ML

| Modelo                  | Archivo                        |
| ----------------------- | ------------------------------ |
| `SimulatorStateModel`   | `simulator_state_model.dart`   |
| `TestScenarioModel`     | `test_scenario_model.dart`     |
| `LearningReportModel`   | `learning_report_model.dart`   |
| `LearningDataModel`     | `learning_data_model.dart`     |
| `StationKnowledgeModel` | `station_knowledge_model.dart` |

### Otros

| Modelo          | Archivo                |
| --------------- | ---------------------- |
| `RouteModel`    | `route_model.dart`     |
| `ETAGroupModel` | `eta_group_model.dart` |

## Patrón común de modelos

Todos siguen: `factory fromFirestore(DocumentSnapshot)` + `toFirestore()` → `Map<String, dynamic>`
