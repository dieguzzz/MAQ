import os

moves = {
  "firebase_service.dart":"core",
  "error_handler_service.dart":"core",
  "storage_service.dart":"core",
  "dev_service.dart":"core",
  "app_mode_service.dart":"core",
  "notification_service.dart":"core",
  "ad_service.dart":"ads",
  "ad_session_service.dart":"ads",
  "metro_simulator_service.dart":"simulation",
  "simulated_time_service.dart":"simulation",
  "train_simulation_service.dart":"simulation",
  "time_estimation_service.dart":"simulation",
  "schedule_service.dart":"simulation",
  "gamification_service.dart":"gamification",
  "level_service.dart":"gamification",
  "points_history_service.dart":"gamification",
  "points_reward_service.dart":"gamification",
  "admin_learning_service.dart":"learning",
  "learning_report_service.dart":"learning",
  "learning_storage_service.dart":"learning",
  "station_learning_service.dart":"learning",
  "enhanced_report_service.dart":"reports",
  "simplified_report_service.dart":"reports",
  "report_validation_service.dart":"reports",
  "report_progress_service.dart":"reports",
  "confidence_service.dart":"reports",
  "accuracy_service.dart":"reports",
  "station_edit_mode_service.dart":"stations",
  "station_position_editor_service.dart":"stations",
  "station_status_aggregator.dart":"stations",
  "station_update_service.dart":"stations",
  "train_status_aggregator.dart":"stations",
  "background_location_service.dart":"location",
  "location_service.dart":"location",
  "map_service.dart":"location",
  "route_calculation_service.dart":"location",
  "subscription_service.dart":"premium",
  "alert_service.dart":"premium"
}

for root, _, files in os.walk('lib'):
    for file in files:
        if not file.endswith('.dart'): continue
        path = os.path.join(root, file)
        
        with open(path, 'r') as f:
            content = f.read()
            
        original_content = content
        
        for s_file, folder in moves.items():
            # Replace absolute package imports
            old_pkg = f"package:metropty/services/{s_file}"
            new_pkg = f"package:metropty/services/{folder}/{s_file}"
            content = content.replace(old_pkg, new_pkg)
            
            # Replace relative imports containing 'services/xxx.dart'
            old_rel1 = f"services/{s_file}"
            new_rel1 = f"services/{folder}/{s_file}"
            content = content.replace(old_rel1, new_rel1)
            
            # Bare imports inside services folder itself
            if "lib/services" in root:
                old_bare = f"import '{s_file}';"
                
                # Check if it's the same folder
                target_folder = folder
                current_folder = moves.get(file)
                
                if current_folder == target_folder:
                    new_bare = f"import '{s_file}';"
                else:
                    new_bare = f"import '../{target_folder}/{s_file}';"
                
                # We need to make sure we don't double replace or mess it up
                # only replace exact bare import 
                if old_bare in content:
                    content = content.replace(old_bare, new_bare)

        # Fix the issue where files moved into subfolders still have `import '../xxx'` that needs to be `import '../../xxx'`
        if "lib/services/" in path and path.count('/') == 3: # lib/services/folder/file.dart
            # if we see `import '../` but NOT `import '../services/` and NOT `import '../core/` (etc from the above logic)
            # Actually, easiest is just to replace `import '../models` to `import '../../models` and `import '../utils` etc.
            # Assuming old service files only imported `models`, `utils`, `providers`, `widgets`, `theme`, `screens`
            for dir_up in ["models", "utils", "providers", "widgets", "theme", "screens"]:
                content = content.replace(f"import '../{dir_up}/", f"import '../../{dir_up}/")
                content = content.replace(f"import \"../{dir_up}/", f"import \"../../{dir_up}/")

        if content != original_content:
            with open(path, 'w') as f:
                f.write(content)

print("Refactoring done.")
