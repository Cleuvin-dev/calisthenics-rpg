import 'package:drift/drift.dart';

/// Agenda, duração e equipamento informados no onboarding
/// (REQUIREMENTS.md FR-002/FR-003). Nome evita colidir com a classe de
/// domínio `TrainingPreferences`.
@DataClassName('TrainingPreferenceRecord')
class TrainingPreferenceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get daysPerWeek => integer()();
  IntColumn get minutesPerSession => integer()();
  TextColumn get location => text()(); // TrainingLocation.name
  TextColumn get equipmentJson => text()(); // json list de Equipment.name
  DateTimeColumn get updatedAt => dateTime()();
}
