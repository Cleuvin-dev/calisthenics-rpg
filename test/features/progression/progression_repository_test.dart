import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/assessment/data/capability_estimate_repository.dart';
import 'package:calisthenics_rpg/features/progression/data/progression_repository.dart';
import 'package:calisthenics_rpg/features/progression/domain/mastery_rules.dart';
import 'package:calisthenics_rpg/features/workout_session/data/workout_session_repository.dart';
import 'package:calisthenics_rpg/features/workout_session/domain/workout_session.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkoutSessionRepository sessionRepository;
  late CapabilityEstimateRepository capabilityRepository;
  late ProgressionRepository progressionRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessionRepository = WorkoutSessionRepository(db);
    capabilityRepository = CapabilityEstimateRepository(db);
    progressionRepository = ProgressionRepository(db, capabilityRepository);
  });

  tearDown(() => db.close());

  const items = [
    WorkoutSessionItem(
      pattern: 'push_horizontal',
      exerciseSlug: 'push_up_wall',
      namePtBr: 'Flexão na parede',
      setsRepsGuidance: '2 séries de 6-10 repetições',
    ),
  ];

  Future<void> completeQualifyingSession(
    DateTime completedAt, {
    String exerciseSlug = 'push_up_wall',
    String pattern = 'push_horizontal',
    int repsCompleted = 8,
  }) async {
    final id = await sessionRepository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: completedAt,
    );
    for (var setNumber = 1; setNumber <= 2; setNumber++) {
      await sessionRepository.logSet(
        workoutSessionId: id,
        exerciseSlug: exerciseSlug,
        pattern: pattern,
        setNumber: setNumber,
        repsCompleted: repsCompleted,
        perceivedEffort: PerceivedEffort.adequate,
        now: completedAt,
      );
    }
    await sessionRepository.complete(id, completedAt);
  }

  Future<void> completeQualifyingTimedSession(
    DateTime completedAt, {
    required String exerciseSlug,
    required String pattern,
    int activeDurationMs = 32000,
  }) async {
    final id = await sessionRepository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: completedAt,
    );
    for (var setNumber = 1; setNumber <= 2; setNumber++) {
      await sessionRepository.finalizeTimedSet(
        workoutSessionId: id,
        exerciseSlug: exerciseSlug,
        pattern: pattern,
        setNumber: setNumber,
        targetSeconds: 30,
        activeDurationMs: activeDurationMs,
        completionReason: TimedSetCompletionReason.targetReached,
        perceivedEffort: PerceivedEffort.adequate,
        now: completedAt,
      );
    }
    await sessionRepository.complete(id, completedAt);
  }

  test('sem sessões concluídas, não promove', () async {
    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'push_horizontal',
      currentLevel: 0,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 10),
    );

    expect(result!.promoted, isFalse);
    expect(await capabilityRepository.latestFor('push_horizontal'), isNull);
  });

  test('nível máximo da escala do padrão não é avaliado', () async {
    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'push_horizontal',
      currentLevel: 7,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 10),
    );

    expect(result, isNull);
  });

  test('padrão desconhecido não é avaliado', () async {
    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'nao_existe',
      currentLevel: 0,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 10),
    );

    expect(result, isNull);
  });

  test('duas sessões qualificadas promovem e gravam nova colocação', () async {
    await completeQualifyingSession(DateTime(2026, 1, 2, 8));
    await completeQualifyingSession(DateTime(2026, 1, 4, 8)); // 48h depois

    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'push_horizontal',
      currentLevel: 0,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 4, 9),
    );

    expect(result!.promoted, isTrue);

    final latest = await capabilityRepository.latestFor('push_horizontal');
    expect(latest, isNotNull);
    expect(latest!.level, 1);
    expect(latest.ruleVersion, masteryRuleVersion);
    expect(latest.reasonCode, masteryConfirmedReasonCode);
    expect(latest.confidence, 'medium');
  });

  test('sessões concluídas antes da colocação atual não contam como '
      'evidência', () async {
    await completeQualifyingSession(DateTime(2026, 1, 2, 8));
    await completeQualifyingSession(DateTime(2026, 1, 4, 8));

    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'push_horizontal',
      currentLevel: 0,
      // Colocação feita depois das duas sessões acima: elas não contam.
      placementComputedAt: DateTime(2026, 1, 5),
      now: DateTime(2026, 1, 10),
    );

    expect(result!.promoted, isFalse);
    expect(await capabilityRepository.latestFor('push_horizontal'), isNull);
  });

  test('apenas uma sessão qualificada não promove', () async {
    await completeQualifyingSession(DateTime(2026, 1, 2, 8));

    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'push_horizontal',
      currentLevel: 0,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 3),
    );

    expect(result!.promoted, isFalse);
    expect(result.hasPartialProgress, isTrue);
    expect(await capabilityRepository.latestFor('push_horizontal'), isNull);
  });

  test('promove um padrão além de push_horizontal (squat)', () async {
    await completeQualifyingSession(
      DateTime(2026, 1, 2, 8),
      exerciseSlug: 'medium_bench_sit_to_stand',
      pattern: 'squat',
      repsCompleted: 10,
    );
    await completeQualifyingSession(
      DateTime(2026, 1, 4, 8),
      exerciseSlug: 'medium_bench_sit_to_stand',
      pattern: 'squat',
      repsCompleted: 10,
    );

    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'squat',
      currentLevel: 0,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 4, 9),
    );

    expect(result!.promoted, isTrue);
    final latest = await capabilityRepository.latestFor('squat');
    expect(latest!.level, 1);
  });

  test('promove por duração (core_anti_extension, prancha completa)', () async {
    await completeQualifyingTimedSession(
      DateTime(2026, 1, 2, 8),
      exerciseSlug: 'forearm_plank_full',
      pattern: 'core_anti_extension',
    );
    await completeQualifyingTimedSession(
      DateTime(2026, 1, 4, 8),
      exerciseSlug: 'forearm_plank_full',
      pattern: 'core_anti_extension',
    );

    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'core_anti_extension',
      currentLevel: 5,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 4, 9),
    );

    expect(result!.promoted, isTrue);
    final latest = await capabilityRepository.latestFor('core_anti_extension');
    expect(latest!.level, 6);
  });

  test('duração abaixo do limiar não conta como evidência', () async {
    await completeQualifyingTimedSession(
      DateTime(2026, 1, 2, 8),
      exerciseSlug: 'forearm_plank_full',
      pattern: 'core_anti_extension',
      activeDurationMs: 10000, // 10s, abaixo dos 30s exigidos
    );
    await completeQualifyingTimedSession(
      DateTime(2026, 1, 4, 8),
      exerciseSlug: 'forearm_plank_full',
      pattern: 'core_anti_extension',
      activeDurationMs: 10000,
    );

    final result = await progressionRepository.evaluateAndPromote(
      pattern: 'core_anti_extension',
      currentLevel: 5,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 4, 9),
    );

    expect(result!.promoted, isFalse);
  });
}
