import '../../../core/time/date_period.dart';
import '../../assessment/data/capability_estimate_repository.dart';
import '../../progression/data/progression_repository.dart';
import '../../rpg/data/xp_ledger_repository.dart';
import '../../rpg/domain/xp_events.dart';
import '../../training_plan/data/training_plan_repository.dart';
import '../../training_plan/domain/exercise_catalog.dart';
import '../../workout_session/data/workout_session_repository.dart';
import '../domain/mission.dart';
import '../domain/mission_evaluator.dart';

class MissionRepository {
  MissionRepository(
    this._workoutSessionRepository,
    this._trainingPlanRepository,
    this._capabilityEstimateRepository,
    this._xpLedgerRepository,
  );

  final WorkoutSessionRepository _workoutSessionRepository;
  final TrainingPlanRepository _trainingPlanRepository;
  final CapabilityEstimateRepository _capabilityEstimateRepository;
  final XpLedgerRepository _xpLedgerRepository;

  static const _evaluator = MissionEvaluator();

  Future<List<MissionEvaluationResult>> evaluateDaily(DateTime now) async {
    final start = startOfDay(now);
    final end = endOfDay(now);

    final logs = await _workoutSessionRepository.setLogsBetween(start, end);
    final completedSessions =
        await _workoutSessionRepository.completedBetween(start, end);

    final facts = DailyMissionFacts(
      loggedExerciseSlugs: logs.map((l) => l.exerciseSlug).toSet(),
      completedSessionCount: completedSessions.length,
      warmupExerciseSlug: warmupExerciseSlug,
    );
    return _evaluator.evaluateDaily(facts);
  }

  Future<List<MissionEvaluationResult>> evaluateWeekly(DateTime now) async {
    final plan = await _trainingPlanRepository.latest();
    if (plan == null) return const [];

    final start = startOfWeek(now);
    final end = endOfWeek(now);
    final weeklyPlan = plan.toDomain();

    final completedSessions =
        await _workoutSessionRepository.completedBetween(start, end);
    final logs = await _workoutSessionRepository.setLogsBetween(start, end);
    final masteryRecords = await _capabilityEstimateRepository.confirmedBetween(
      reasonCode: masteryConfirmedReasonCode,
      start: start,
      end: end,
    );

    final plannedPatterns = weeklyPlan.sessions
        .expand((session) => session.items.map((item) => item.pattern))
        .toSet();

    final facts = WeeklyMissionFacts(
      completedSessionCount: completedSessions.length,
      requiredSessionCount: (weeklyPlan.actualDaysPerWeek * 0.7).ceil(),
      plannedPatterns: plannedPatterns,
      trainedPatterns: logs.map((l) => l.pattern).toSet(),
      masteryConfirmedThisWeek: masteryRecords.isNotEmpty,
    );
    return _evaluator.evaluateWeekly(facts);
  }

  /// Avalia e concede XP para as missões diárias já cumpridas hoje.
  /// Idempotente: chamar de novo no mesmo dia não duplica crédito.
  Future<int> grantCompletedDaily(DateTime now) async {
    final results = await evaluateDaily(now);
    return _grantCompleted(results, periodKey: _dayKey(startOfDay(now)), now: now);
  }

  /// Mesma ideia para as missões semanais.
  Future<int> grantCompletedWeekly(DateTime now) async {
    final results = await evaluateWeekly(now);
    return _grantCompleted(
      results,
      periodKey: _dayKey(startOfWeek(now)),
      now: now,
    );
  }

  Future<int> _grantCompleted(
    List<MissionEvaluationResult> results, {
    required String periodKey,
    required DateTime now,
  }) async {
    var total = 0;
    for (final result in results) {
      if (!result.completed) continue;
      final granted = await _xpLedgerRepository.grant(
        XpAward(
          eventType: XpEventType.missionCompleted,
          amount: result.definition.xpReward,
          sourceId: '${result.definition.type.name}-$periodKey',
          idempotencyKey: 'mission-${result.definition.type.name}-$periodKey',
          repeatable: false,
        ),
        now: now,
      );
      if (granted) total += result.definition.xpReward;
    }
    return total;
  }

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
