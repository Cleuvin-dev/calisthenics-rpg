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

  /// Alvo de repetições planejado — diferente de [repsCompleted]
  /// (DATA_MODEL.md §4: "repetições-alvo e repetições realizadas são
  /// dados diferentes"). Nulo para séries por tempo ou logs anteriores a
  /// esta coluna.
  IntColumn get targetReps => integer().nullable()();

  /// Alvo de duração planejado, em segundos — só para séries por tempo.
  IntColumn get targetSeconds => integer().nullable()();

  /// Tempo ativo realmente executado, em milissegundos (não conta pausa),
  /// medido pelo `ActiveTimer` monotônico — só para séries por tempo.
  IntColumn get activeDurationMs => integer().nullable()();

  /// `TimedSetCompletionReason.name` — só para séries por tempo.
  TextColumn get completionReason => text().nullable()();

  /// Chave de idempotência determinística
  /// (`'$workoutSessionId:$exerciseSlug:$setNumber'`). Repetir a mesma
  /// chave não duplica o log (toque duplo em "Concluir",
  /// TEST_STRATEGY.md §3/§5/§11).
  TextColumn get clientEventId => text().nullable()();
}
