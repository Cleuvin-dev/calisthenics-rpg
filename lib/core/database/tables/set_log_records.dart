import 'package:drift/drift.dart';

/// Registro de uma série executada, equivalente local a `set_logs`
/// (DATA_MODEL.md §2.3/§3). Append-only: cada série é um evento gravado
/// imediatamente, sem depender de a sessão terminar (NFR-005 — registro
/// local sem depender de conexão).
@DataClassName('SetLogRecord')
class SetLogRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutSessionId => integer()();
  TextColumn get exerciseSlug => text()();
  TextColumn get pattern => text()();
  IntColumn get setNumber => integer()();
  IntColumn get repsCompleted => integer()();
  TextColumn get perceivedEffort => text()(); // PerceivedEffort.name
  DateTimeColumn get completedAt => dateTime()();
}
