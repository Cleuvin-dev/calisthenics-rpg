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

  Future<void> logSet({
    required int workoutSessionId,
    required String exerciseSlug,
    required String pattern,
    required int setNumber,
    required int repsCompleted,
    required PerceivedEffort perceivedEffort,
    required DateTime now,
  }) {
    return _db.into(_db.setLogRecords).insert(
          SetLogRecordsCompanion.insert(
            workoutSessionId: workoutSessionId,
            exerciseSlug: exerciseSlug,
            pattern: pattern,
            setNumber: setNumber,
            repsCompleted: repsCompleted,
            perceivedEffort: perceivedEffort.name,
            completedAt: now,
          ),
        );
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
