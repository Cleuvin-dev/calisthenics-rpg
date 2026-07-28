import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/training_preferences.dart';

class TrainingPreferencesRepository {
  TrainingPreferencesRepository(this._db);

  final AppDatabase _db;

  Future<void> save(TrainingPreferences preferences) {
    return _db
        .into(_db.trainingPreferenceRecords)
        .insert(
          TrainingPreferenceRecordsCompanion.insert(
            daysPerWeek: preferences.daysPerWeek,
            minutesPerSession: preferences.minutesPerSession,
            location: preferences.location.name,
            equipmentJson: jsonEncode(
              preferences.equipment.map((e) => e.name).toList(),
            ),
            updatedAt: DateTime.now(),
            preferredWeekdaysJson: Value(
              jsonEncode(preferences.preferredWeekdays.toList()..sort()),
            ),
            heightCm: Value(preferences.heightCm),
            objective: Value(preferences.objective.name),
          ),
        );
  }

  /// Última preferência registrada, se houver. Desempate por `id`
  /// (autoincrement, estritamente crescente) além de `updatedAt`: edições
  /// em sequência rápida (ex.: usuário salvando altura e depois objetivo
  /// logo em seguida, ou testes automatizados) podem cair no mesmo
  /// milissegundo de relógio, e sem o desempate `ORDER BY updatedAt DESC`
  /// sozinho não garante devolver a gravação mais recente.
  Future<TrainingPreferenceRecord?> latest() {
    final query = _db.select(_db.trainingPreferenceRecords)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }
}

extension TrainingPreferenceRecordDecoding on TrainingPreferenceRecord {
  TrainingPreferences toDomain() {
    final equipmentNames = (jsonDecode(equipmentJson) as List).cast<String>();
    final weekdaysJson = preferredWeekdaysJson;
    final preferredWeekdays = weekdaysJson == null
        ? const <int>{}
        : (jsonDecode(weekdaysJson) as List).cast<int>().toSet();
    final objectiveName = objective;
    final resolvedObjective = objectiveName == null
        ? TrainingObjective.strength
        : TrainingObjective.values.byName(objectiveName);
    return TrainingPreferences(
      daysPerWeek: daysPerWeek,
      minutesPerSession: minutesPerSession,
      location: TrainingLocation.values.byName(location),
      equipment: equipmentNames.map(Equipment.values.byName).toSet(),
      preferredWeekdays: preferredWeekdays,
      heightCm: heightCm,
      objective: resolvedObjective,
    );
  }
}
