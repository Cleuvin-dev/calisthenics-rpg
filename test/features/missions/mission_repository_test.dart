import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/assessment/data/capability_estimate_repository.dart';
import 'package:calisthenics_rpg/features/missions/data/mission_repository.dart';
import 'package:calisthenics_rpg/features/missions/domain/mission.dart';
import 'package:calisthenics_rpg/features/progression/data/progression_repository.dart';
import 'package:calisthenics_rpg/features/rpg/data/xp_ledger_repository.dart';
import 'package:calisthenics_rpg/features/training_plan/data/training_plan_repository.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/training_plan.dart';
import 'package:calisthenics_rpg/features/workout_session/data/workout_session_repository.dart';
import 'package:calisthenics_rpg/features/workout_session/domain/workout_session.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkoutSessionRepository sessionRepository;
  late TrainingPlanRepository planRepository;
  late CapabilityEstimateRepository capabilityRepository;
  late XpLedgerRepository xpRepository;
  late MissionRepository missionRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessionRepository = WorkoutSessionRepository(db);
    planRepository = TrainingPlanRepository(db);
    capabilityRepository = CapabilityEstimateRepository(db);
    xpRepository = XpLedgerRepository(db);
    missionRepository = MissionRepository(
      sessionRepository,
      planRepository,
      capabilityRepository,
      xpRepository,
    );
  });

  tearDown(() => db.close());

  const items = [
    WorkoutSessionItem(
      pattern: 'mobility_specific',
      exerciseSlug: 'warmup_joint_mobility',
      namePtBr: 'Aquecimento',
      setsRepsGuidance: '3-5 min',
    ),
    WorkoutSessionItem(
      pattern: 'push_horizontal',
      exerciseSlug: 'push_up_wall',
      namePtBr: 'Flexão na parede',
      setsRepsGuidance: '2 séries de 6-10 repetições',
    ),
  ];

  group('missões diárias', () {
    test('sem atividade, nenhuma missão diária é concedida', () async {
      final now = DateTime(2026, 7, 20, 10);
      final results = await missionRepository.evaluateDaily(now);
      expect(results.every((r) => !r.completed), isTrue);

      final granted = await missionRepository.grantCompletedDaily(now);
      expect(granted, 0);
      expect(await xpRepository.totalXp(), 0);
    });

    test('logar o aquecimento conclui as missões correspondentes e '
        'concede XP uma única vez', () async {
      final now = DateTime(2026, 7, 20, 10);
      final id = await sessionRepository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: now,
      );
      await sessionRepository.logSet(
        workoutSessionId: id,
        exerciseSlug: 'warmup_joint_mobility',
        pattern: 'mobility_specific',
        setNumber: 1,
        repsCompleted: 1,
        perceivedEffort: PerceivedEffort.adequate,
        now: now,
      );

      final results = await missionRepository.evaluateDaily(now);
      expect(
        results
            .firstWhere((r) => r.definition.type == MissionType.completeWarmup)
            .completed,
        isTrue,
      );

      final granted = await missionRepository.grantCompletedDaily(now);
      expect(granted, 20); // aquecimento + registrar série
      expect(await xpRepository.totalXp(), 20);

      // Chamar de novo no mesmo dia não duplica.
      final grantedAgain = await missionRepository.grantCompletedDaily(now);
      expect(grantedAgain, 0);
      expect(await xpRepository.totalXp(), 20);
    });
  });

  group('missões semanais', () {
    test('sem plano salvo, retorna lista vazia', () async {
      final results = await missionRepository.evaluateWeekly(DateTime(2026, 7, 20));
      expect(results, isEmpty);
    });

    test('frequência e cobertura de padrões cumpridas concedem XP', () async {
      final weekMonday = DateTime(2026, 7, 20); // segunda-feira
      final plan = WeeklyPlan(
        ruleVersion: 'v1',
        catalogVersion: 'v1',
        requestedDaysPerWeek: 2,
        actualDaysPerWeek: 2,
        minutesPerSession: 30,
        sessions: const [
          PlannedSession(dayLabel: 'A', targetMinutes: 30, items: [
            PlannedExerciseItem(
              pattern: 'push_horizontal',
              exerciseSlug: 'push_up_wall',
              namePtBr: 'Flexão na parede',
              setsRepsGuidance: '2x8',
              reasonCode: PlanReasonCode.foundationGap,
            ),
          ]),
          PlannedSession(dayLabel: 'B', targetMinutes: 30, items: [
            PlannedExerciseItem(
              pattern: 'squat',
              exerciseSlug: 'sit_to_stand_squat',
              namePtBr: 'Agachamento livre',
              setsRepsGuidance: '2x10',
              reasonCode: PlanReasonCode.foundationGap,
            ),
          ]),
        ],
        generatedAt: weekMonday,
        validUntil: weekMonday.add(const Duration(days: 14)),
      );
      await planRepository.save(plan);

      Future<void> completeSession(String dayLabel, String pattern, String slug, DateTime at) async {
        final id = await sessionRepository.startSession(
          dayLabel: dayLabel,
          items: [
            WorkoutSessionItem(
              pattern: pattern,
              exerciseSlug: slug,
              namePtBr: slug,
              setsRepsGuidance: '2x8',
            ),
          ],
          planRuleVersion: 'v1',
          catalogVersion: 'v1',
          now: at,
        );
        await sessionRepository.logSet(
          workoutSessionId: id,
          exerciseSlug: slug,
          pattern: pattern,
          setNumber: 1,
          repsCompleted: 8,
          perceivedEffort: PerceivedEffort.adequate,
          now: at,
        );
        await sessionRepository.complete(id, at);
      }

      await completeSession('A', 'push_horizontal', 'push_up_wall', weekMonday.add(const Duration(days: 1)));
      await completeSession('B', 'squat', 'sit_to_stand_squat', weekMonday.add(const Duration(days: 2)));

      final checkAt = weekMonday.add(const Duration(days: 3));
      final results = await missionRepository.evaluateWeekly(checkAt);

      final frequency = results.firstWhere(
        (r) => r.definition.type == MissionType.weeklyFrequency,
      );
      expect(frequency.completed, isTrue);

      final coverage = results.firstWhere(
        (r) => r.definition.type == MissionType.trainAllPatterns,
      );
      expect(coverage.completed, isTrue);

      final mastery = results.firstWhere(
        (r) => r.definition.type == MissionType.confirmMastery,
      );
      expect(mastery.completed, isFalse);

      final granted = await missionRepository.grantCompletedWeekly(checkAt);
      expect(granted, 150); // duas missões semanais concluídas (75 cada)

      final grantedAgain = await missionRepository.grantCompletedWeekly(checkAt);
      expect(grantedAgain, 0);
    });

    test('domínio confirmado na semana marca a missão correspondente',
        () async {
      final weekMonday = DateTime(2026, 7, 20);
      final plan = WeeklyPlan(
        ruleVersion: 'v1',
        catalogVersion: 'v1',
        requestedDaysPerWeek: 2,
        actualDaysPerWeek: 2,
        minutesPerSession: 30,
        sessions: const [
          PlannedSession(dayLabel: 'A', targetMinutes: 30, items: []),
        ],
        generatedAt: weekMonday,
        validUntil: weekMonday.add(const Duration(days: 14)),
      );
      await planRepository.save(plan);

      await capabilityRepository.saveEstimate(
        pattern: 'push_horizontal',
        level: 1,
        levelName: 'Flexão na parede',
        confidence: 'medium',
        ruleVersion: 'mastery-push-horizontal-v1',
        reasonCode: masteryConfirmedReasonCode,
        computedAt: weekMonday.add(const Duration(days: 2)),
        validUntil: weekMonday.add(const Duration(days: 30)),
      );

      final results = await missionRepository.evaluateWeekly(
        weekMonday.add(const Duration(days: 3)),
      );
      expect(
        results
            .firstWhere((r) => r.definition.type == MissionType.confirmMastery)
            .completed,
        isTrue,
      );
    });
  });
}
