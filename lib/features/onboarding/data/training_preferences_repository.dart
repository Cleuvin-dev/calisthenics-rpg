import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/training_preferences.dart';

class TrainingPreferencesRepository {
  TrainingPreferencesRepository(this._db);

  final AppDatabase _db;

  Future<void> save(TrainingPreferences preferences) {
    return _db.into(_db.trainingPreferenceRecords).insert(
          TrainingPreferenceRecordsCompanion.insert(
            daysPerWeek: preferences.daysPerWeek,
            minutesPerSession: preferences.minutesPerSession,
            location: preferences.location.name,
            equipmentJson: jsonEncode(
              preferences.equipment.map((e) => e.name).toList(),
            ),
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// Última preferência registrada, se houver.
  Future<TrainingPreferenceRecord?> latest() {
    final query = _db.select(_db.trainingPreferenceRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }
}
