import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../assessment/data/capability_estimate_repository.dart';
import '../../assessment/domain/push_horizontal_anchor.dart';
import '../../training_plan/domain/exercise_catalog.dart';
import '../../workout_session/domain/workout_session.dart';
import '../domain/mastery_evaluator.dart';
import '../domain/mastery_rules.dart';

/// `reason_code` gravado em `capability_estimate_records` quando a
/// promoção vem de confirmação de domínio, não de autorrelato.
const masteryConfirmedReasonCode = 'masteryConfirmed';

class ProgressionRepository {
  ProgressionRepository(this._db, this._capabilityEstimateRepository);

  final AppDatabase _db;
  final CapabilityEstimateRepository _capabilityEstimateRepository;

  /// Avalia se as sessões concluídas desde a colocação atual confirmam
  /// domínio da variação de push_horizontal em treino e, se sim, grava a
  /// promoção como uma nova estimativa de capacidade
  /// (PROGRESSION_RULES.md §3 — menor incremento possível).
  ///
  /// Retorna `null` quando o nível já está fora da escala coberta por
  /// este MVP (0-7, pushHorizontalLevelNames) ou não há regra cadastrada.
  Future<MasteryEvaluationResult?> evaluateAndPromotePushHorizontal({
    required int currentLevel,
    required DateTime placementComputedAt,
    required DateTime now,
  }) async {
    if (currentLevel >= 7) return null;

    final exerciseSlug = pushHorizontalExerciseForLevel(currentLevel);
    if (exerciseSlug == null) return null;

    final rule = pushHorizontalMasteryRules[exerciseSlug];
    if (rule == null) return null;

    final sessions = await _fetchSessionEvidence(
      exerciseSlug: exerciseSlug,
      after: placementComputedAt,
    );

    const evaluator = MasteryEvaluator();
    final result = evaluator.evaluate(rule: rule, sessions: sessions);

    if (result.promoted) {
      final newLevel = currentLevel + 1;
      await _capabilityEstimateRepository.saveEstimate(
        pattern: 'push_horizontal',
        level: newLevel,
        levelName: pushHorizontalLevelNames[newLevel] ?? 'Nível $newLevel',
        // Confiança maior que a colocação por autorrelato: baseada em
        // séries realmente executadas e confirmadas.
        confidence: 'medium',
        ruleVersion: masteryRuleVersion,
        reasonCode: masteryConfirmedReasonCode,
        computedAt: now,
        validUntil: now.add(const Duration(days: 30)),
      );
    }

    return result;
  }

  Future<List<SessionEvidence>> _fetchSessionEvidence({
    required String exerciseSlug,
    required DateTime after,
  }) async {
    final sessionsQuery = _db.select(_db.workoutSessionRecords)
      ..where(
        (t) =>
            t.status.equals(WorkoutSessionStatus.completed.name) &
            t.completedAt.isBiggerThanValue(after),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]);
    final sessions = await sessionsQuery.get();

    final evidence = <SessionEvidence>[];
    for (final session in sessions) {
      final logsQuery = _db.select(_db.setLogRecords)
        ..where(
          (t) =>
              t.workoutSessionId.equals(session.id) &
              t.exerciseSlug.equals(exerciseSlug),
        );
      final logs = await logsQuery.get();
      if (logs.isEmpty) continue;

      evidence.add(SessionEvidence(
        completedAt: session.completedAt!,
        sets: logs
            .map((l) => SetLog(
                  exerciseSlug: l.exerciseSlug,
                  pattern: l.pattern,
                  setNumber: l.setNumber,
                  repsCompleted: l.repsCompleted,
                  perceivedEffort: PerceivedEffort.values.byName(
                    l.perceivedEffort,
                  ),
                  completedAt: l.completedAt,
                ))
            .toList(),
      ));
    }
    return evidence;
  }
}
