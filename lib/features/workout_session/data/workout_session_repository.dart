import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/workout_session.dart';

class WorkoutSessionRepository {
  WorkoutSessionRepository(this._db);

  final AppDatabase _db;

  Future<int> startSession({
    required String dayLabel,
    required List<WorkoutSessionItem> items,
    required String planRuleVersion,
    required String catalogVersion,
    required DateTime now,
  }) {
    return _db.into(_db.workoutSessionRecords).insert(
          WorkoutSessionRecordsCompanion.insert(
            dayLabel: dayLabel,
            status: WorkoutSessionStatus.inProgress.name,
            planRuleVersion: planRuleVersion,
            catalogVersion: catalogVersion,
            itemsJson: jsonEncode(items.map((e) => e.toJson()).toList()),
            startedAt: now,
          ),
        );
  }

  /// Idempotente por `clientEventId` determinístico: repetir a mesma
  /// combinação sessão/exercício/série (toque duplo em "Concluir", ou
  /// reabrir o app antes de a UI atualizar) não duplica o log
  /// (TEST_STRATEGY.md §3/§5/§11, VISUAL_ARCHITECTURE...md §24.2).
  /// Retorna `true` se um log novo foi gravado, `false` se já existia.
  Future<bool> logSet({
    required int workoutSessionId,
    required String exerciseSlug,
    required String pattern,
    required int setNumber,
    required int repsCompleted,
    int? targetReps,
    required PerceivedEffort perceivedEffort,
    required DateTime now,
  }) async {
    final clientEventId = _setClientEventId(
      workoutSessionId: workoutSessionId,
      exerciseSlug: exerciseSlug,
      setNumber: setNumber,
    );
    final existing = await (_db.select(_db.setLogRecords)
          ..where((t) => t.clientEventId.equals(clientEventId)))
        .getSingleOrNull();
    if (existing != null) return false;

    await _db.into(_db.setLogRecords).insert(
          SetLogRecordsCompanion.insert(
            workoutSessionId: workoutSessionId,
            exerciseSlug: exerciseSlug,
            pattern: pattern,
            setNumber: setNumber,
            repsCompleted: repsCompleted,
            targetReps: Value(targetReps),
            perceivedEffort: perceivedEffort.name,
            completedAt: now,
            clientEventId: Value(clientEventId),
          ),
        );
    return true;
  }

  String _setClientEventId({
    required int workoutSessionId,
    required String exerciseSlug,
    required int setNumber,
  }) => '$workoutSessionId:$exerciseSlug:$setNumber';

  /// Cria (ou substitui, se já houver uma órfã da mesma sessão) o estado
  /// persistido de uma série por tempo em andamento. Só uma por sessão —
  /// a sessão toca um exercício de cada vez.
  Future<void> startTimedSet({
    required int workoutSessionId,
    required String exerciseSlug,
    required String pattern,
    required int setNumber,
    required int targetSeconds,
    required DateTime now,
  }) {
    return _db.into(_db.activeTimedSetRecords).insertOnConflictUpdate(
          ActiveTimedSetRecordsCompanion.insert(
            workoutSessionId: Value(workoutSessionId),
            exerciseSlug: exerciseSlug,
            pattern: pattern,
            setNumber: setNumber,
            targetSeconds: targetSeconds,
            activeElapsedMs: 0,
            status: 'running',
            startedAtUtc: now,
            lastPersistedAtUtc: now,
          ),
        );
  }

  /// Persiste o progresso do timer (chamado periodicamente enquanto roda
  /// e sempre que o app vai para segundo plano/pausa) — é o que permite
  /// recuperar depois de fechar o app ou bloquear a tela.
  Future<void> updateTimedSetProgress({
    required int workoutSessionId,
    required int activeElapsedMs,
    required bool running,
    required DateTime now,
  }) {
    final update = _db.update(_db.activeTimedSetRecords)
      ..where((t) => t.workoutSessionId.equals(workoutSessionId));
    return update.write(
      ActiveTimedSetRecordsCompanion(
        activeElapsedMs: Value(activeElapsedMs),
        status: Value(running ? 'running' : 'paused'),
        lastPersistedAtUtc: Value(now),
      ),
    );
  }

  Future<ActiveTimedSetRecord?> activeTimedSetFor(int workoutSessionId) {
    final query = _db.select(_db.activeTimedSetRecords)
      ..where((t) => t.workoutSessionId.equals(workoutSessionId));
    return query.getSingleOrNull();
  }

  /// Encerra a série por tempo (alvo atingido, interrupção ou dor):
  /// grava o `SetLogRecords` e remove o estado ativo numa única
  /// transação — nunca fica um timer "órfão" nem um log sem o timer
  /// correspondente removido. Idempotente pelo mesmo `clientEventId`
  /// determinístico do player por repetições.
  Future<bool> finalizeTimedSet({
    required int workoutSessionId,
    required String exerciseSlug,
    required String pattern,
    required int setNumber,
    required int targetSeconds,
    required int activeDurationMs,
    required TimedSetCompletionReason completionReason,
    required PerceivedEffort perceivedEffort,
    required DateTime now,
  }) {
    final clientEventId = _setClientEventId(
      workoutSessionId: workoutSessionId,
      exerciseSlug: exerciseSlug,
      setNumber: setNumber,
    );

    return _db.transaction(() async {
      final existing = await (_db.select(_db.setLogRecords)
            ..where((t) => t.clientEventId.equals(clientEventId)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.setLogRecords).insert(
              SetLogRecordsCompanion.insert(
                workoutSessionId: workoutSessionId,
                exerciseSlug: exerciseSlug,
                pattern: pattern,
                setNumber: setNumber,
                repsCompleted: 0,
                targetSeconds: Value(targetSeconds),
                activeDurationMs: Value(activeDurationMs),
                completionReason: Value(completionReason.name),
                perceivedEffort: perceivedEffort.name,
                completedAt: now,
                clientEventId: Value(clientEventId),
              ),
            );
      }

      final delete = _db.delete(_db.activeTimedSetRecords)
        ..where((t) => t.workoutSessionId.equals(workoutSessionId));
      await delete.go();

      return existing == null;
    });
  }

  /// Descarta uma série por tempo em andamento sem registrar log —
  /// escolha do usuário no fluxo de recuperação
  /// (SETTINGS_AND_TIMED_EXERCISES.md §13.3: "nunca marcar automaticamente
  /// como válida sem confirmação").
  Future<void> discardActiveTimedSet(int workoutSessionId) {
    final delete = _db.delete(_db.activeTimedSetRecords)
      ..where((t) => t.workoutSessionId.equals(workoutSessionId));
    return delete.go();
  }

  Future<void> pause(int workoutSessionId) =>
      _setStatus(workoutSessionId, WorkoutSessionStatus.paused);

  Future<void> resume(int workoutSessionId) =>
      _setStatus(workoutSessionId, WorkoutSessionStatus.inProgress);

  Future<void> abandon(int workoutSessionId, DateTime now) =>
      _setStatus(workoutSessionId, WorkoutSessionStatus.abandoned, now);

  Future<void> complete(int workoutSessionId, DateTime now) =>
      _setStatus(workoutSessionId, WorkoutSessionStatus.completed, now);

  Future<void> _setStatus(
    int workoutSessionId,
    WorkoutSessionStatus status, [
    DateTime? completedAt,
  ]) {
    final update = _db.update(_db.workoutSessionRecords)
      ..where((t) => t.id.equals(workoutSessionId));
    return update.write(
      WorkoutSessionRecordsCompanion(
        status: Value(status.name),
        completedAt: completedAt == null ? const Value.absent() : Value(completedAt),
      ),
    );
  }

  /// Sessão em andamento ou pausada mais recente, se houver — usada para
  /// oferecer retomada (FR-026) em vez de permitir sessões órfãs.
  Future<WorkoutSessionRecord?> latestActive() {
    final query = _db.select(_db.workoutSessionRecords)
      ..where(
        (t) => t.status.isIn([
          WorkoutSessionStatus.inProgress.name,
          WorkoutSessionStatus.paused.name,
        ]),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<SetLogRecord>> setLogsFor(int workoutSessionId) {
    final query = _db.select(_db.setLogRecords)
      ..where((t) => t.workoutSessionId.equals(workoutSessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]);
    return query.get();
  }

  /// Sessões concluídas com `completedAt` em `[start, end)` — usado por
  /// missões semanais e pela tela Jornada ("próxima sessão da semana").
  Future<List<WorkoutSessionRecord>> completedBetween(
    DateTime start,
    DateTime end,
  ) {
    final query = _db.select(_db.workoutSessionRecords)
      ..where(
        (t) =>
            t.status.equals(WorkoutSessionStatus.completed.name) &
            t.completedAt.isBetweenValues(start, end),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]);
    return query.get();
  }

  /// Séries registradas com `completedAt` em `[start, end)`, qualquer
  /// sessão — usado por missões diárias/semanais.
  Future<List<SetLogRecord>> setLogsBetween(DateTime start, DateTime end) {
    final query = _db.select(_db.setLogRecords)
      ..where((t) => t.completedAt.isBetweenValues(start, end));
    return query.get();
  }

  /// Sessões concluídas mais recentes — histórico curto da tela Evolução.
  Future<List<WorkoutSessionRecord>> completedSessions({int limit = 20}) {
    final query = _db.select(_db.workoutSessionRecords)
      ..where((t) => t.status.equals(WorkoutSessionStatus.completed.name))
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
      ..limit(limit);
    return query.get();
  }

  /// Maior número de repetições já registrado por exercício, ignorando
  /// séries com dor ou não concluídas — não é evidência de domínio
  /// (PROGRESSION_RULES.md §7-8), só um recorde pessoal informal.
  Future<Map<String, int>> bestRepsByExercise() async {
    final query = _db.select(_db.setLogRecords)
      ..where(
        (t) => t.perceivedEffort.isIn([
          PerceivedEffort.adequate.name,
          PerceivedEffort.tooEasy.name,
          PerceivedEffort.hardCompleted.name,
        ]),
      );
    final logs = await query.get();

    final best = <String, int>{};
    for (final log in logs) {
      final current = best[log.exerciseSlug];
      if (current == null || log.repsCompleted > current) {
        best[log.exerciseSlug] = log.repsCompleted;
      }
    }
    return best;
  }
}

extension WorkoutSessionRecordDecoding on WorkoutSessionRecord {
  List<WorkoutSessionItem> get items => (jsonDecode(itemsJson) as List)
      .map((e) => WorkoutSessionItem.fromJson(e as Map<String, dynamic>))
      .toList();
}
