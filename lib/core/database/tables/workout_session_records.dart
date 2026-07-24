import 'package:drift/drift.dart';

/// Sessão de treino executada, equivalente local a `workout_sessions`
/// (DATA_MODEL.md §2.3/§3). Os itens prescritos ficam congelados em
/// [itemsJson] no início da sessão — regenerar o plano depois não altera
/// uma sessão já iniciada (TRAINING_ENGINE.md §10).
@DataClassName('WorkoutSessionRecord')
class WorkoutSessionRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dayLabel => text()();
  TextColumn get status => text()(); // WorkoutSessionStatus.name
  TextColumn get planRuleVersion => text()();
  TextColumn get catalogVersion => text()();
  TextColumn get itemsJson => text()(); // List<WorkoutSessionItem>
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
