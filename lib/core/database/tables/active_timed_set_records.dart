import 'package:drift/drift.dart';

/// Estado persistido de uma série por tempo em andamento — permite
/// recuperar após fechar o app, matar o processo ou bloquear a tela
/// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §20,
/// SETTINGS_AND_TIMED_EXERCISES.md §13.2-13.3). No máximo uma linha por
/// sessão (`workoutSessionId` é a chave primária): a sessão só toca um
/// exercício por vez.
///
/// Só existe enquanto a série está `running`/`paused`. Ao concluir,
/// interromper ou descartar, a linha é removida na mesma transação que
/// grava o `SetLogRecords` correspondente (ver
/// `WorkoutSessionRepository.finalizeTimedSet`) — nunca fica órfã.
@DataClassName('ActiveTimedSetRecord')
class ActiveTimedSetRecords extends Table {
  IntColumn get workoutSessionId => integer()();
  TextColumn get exerciseSlug => text()();
  TextColumn get pattern => text()();
  IntColumn get setNumber => integer()();
  IntColumn get targetSeconds => integer()();

  /// Tempo ativo acumulado até a última persistência, em milissegundos.
  /// Autoridade para recuperação — nunca o relógio de parede sozinho.
  IntColumn get activeElapsedMs => integer()();

  /// `running` ou `paused`.
  TextColumn get status => text()();
  DateTimeColumn get startedAtUtc => dateTime()();
  DateTimeColumn get lastPersistedAtUtc => dateTime()();

  @override
  Set<Column> get primaryKey => {workoutSessionId};
}
