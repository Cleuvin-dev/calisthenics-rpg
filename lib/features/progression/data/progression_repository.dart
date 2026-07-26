import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../assessment/data/capability_estimate_repository.dart';
import '../../assessment/domain/fundamental_pattern_anchors.dart';
import '../../assessment/domain/push_horizontal_anchor.dart';
import '../../training_plan/domain/exercise_catalog.dart';
import '../../workout_session/domain/workout_session.dart';
import '../domain/mastery_evaluator.dart';
import '../domain/mastery_rules.dart';

/// `reason_code` gravado em `capability_estimate_records` quando a
/// promoção vem de confirmação de domínio, não de autorrelato.
const masteryConfirmedReasonCode = 'masteryConfirmed';

/// Nomes de nível por padrão, reaproveitando as escadas já definidas na
/// avaliação (`push_horizontal_anchor.dart` + `fundamental_pattern_anchors.dart`).
/// A extensão de cada escala (0-7 ou 0-5) é o maior nível presente aqui —
/// sem constante fixa separada para não arriscar dessincronizar as duas.
final Map<String, Map<int, String>> levelNamesByPattern = {
  'push_horizontal': pushHorizontalLevelNames,
  for (final ladder in fundamentalPatternLadders)
    ladder.pattern: ladder.levelNames,
};

class ProgressionRepository {
  ProgressionRepository(this._db, this._capabilityEstimateRepository);

  final AppDatabase _db;
  final CapabilityEstimateRepository _capabilityEstimateRepository;

  /// Avalia se as sessões concluídas desde a colocação atual confirmam
  /// domínio da variação de [pattern] em treino e, se sim, grava a
  /// promoção como uma nova estimativa de capacidade
  /// (PROGRESSION_RULES.md §3 — menor incremento possível).
  ///
  /// Retorna `null` quando o nível já está fora da escala coberta pelo
  /// catálogo deste padrão ou não há regra cadastrada para a variação
  /// atual.
  Future<MasteryEvaluationResult?> evaluateAndPromote({
    required String pattern,
    required int currentLevel,
    required DateTime placementComputedAt,
    required DateTime now,
  }) async {
    final levelNames = levelNamesByPattern[pattern];
    if (levelNames == null) return null;
    final maxLevel = levelNames.keys.reduce((a, b) => a > b ? a : b);
    if (currentLevel >= maxLevel) return null;

    final exerciseSlug = exerciseForPatternAndLevel(pattern, currentLevel);
    if (exerciseSlug == null) return null;

    final rule = masteryRulesByPattern[pattern]?[exerciseSlug];
    if (rule == null) return null;

    final sessions = await _fetchSessionEvidence(
      exerciseSlug: exerciseSlug,
      after: placementComputedAt,
    );

    const evaluator = MasteryEvaluator();
    final result = evaluator.evaluate(rule: rule, sessions: sessions);

    if (!result.promoted) return result;

    final newLevel = currentLevel + 1;
    await _capabilityEstimateRepository.saveEstimate(
      pattern: pattern,
      level: newLevel,
      levelName: levelNames[newLevel] ?? 'Nível $newLevel',
      // Confiança maior que a colocação por autorrelato: baseada em
      // séries realmente executadas e confirmadas.
      confidence: 'medium',
      ruleVersion: masteryRuleVersion,
      reasonCode: masteryConfirmedReasonCode,
      computedAt: now,
      validUntil: now.add(const Duration(days: 30)),
    );

    return MasteryEvaluationResult(
      qualifyingConfirmations: result.qualifyingConfirmations,
      confirmationsRequired: result.confirmationsRequired,
      promoted: true,
      newLevel: newLevel,
    );
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

      evidence.add(
        SessionEvidence(
          completedAt: session.completedAt!,
          sets: logs
              .map(
                (l) => SetLog(
                  exerciseSlug: l.exerciseSlug,
                  pattern: l.pattern,
                  setNumber: l.setNumber,
                  repsCompleted: l.repsCompleted,
                  perceivedEffort: PerceivedEffort.values.byName(
                    l.perceivedEffort,
                  ),
                  completedAt: l.completedAt,
                  activeDurationMs: l.activeDurationMs,
                ),
              )
              .toList(),
        ),
      );
    }
    return evidence;
  }
}
