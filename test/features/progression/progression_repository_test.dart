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

  Future<void> completeQualifyingSession(DateTime completedAt) async {
    final id = await sessionRepository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: completedAt,
    );
    await sessionRepository.logSet(
      workoutSessionId: id,
      exerciseSlug: 'push_up_wall',
      pattern: 'push_horizontal',
      setNumber: 1,
      repsCompleted: 8,
      perceivedEffort: PerceivedEffort.adequate,
      now: completedAt,
    );
    await sessionRepository.logSet(
      workoutSessionId: id,
      exerciseSlug: 'push_up_wall',
      pattern: 'push_horizontal',
      setNumber: 2,
      repsCompleted: 7,
      perceivedEffort: PerceivedEffort.adequate,
      now: completedAt,
    );
    await sessionRepository.complete(id, completedAt);
  }

  test('sem sessões concluídas, não promove', () async {
    final result = await progressionRepository.evaluateAndPromotePushHorizontal(
      currentLevel: 0,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 10),
    );

    expect(result!.promoted, isFalse);
    expect(await capabilityRepository.latestFor('push_horizontal'), isNull);
  });

  test('nível 7 (máximo da escala do MVP) não é avaliado', () async {
    final result = await progressionRepository.evaluateAndPromotePushHorizontal(
      currentLevel: 7,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 10),
    );

    expect(result, isNull);
  });

  test('duas sessões qualificadas promovem e gravam nova colocação',
      () async {
    await completeQualifyingSession(DateTime(2026, 1, 2, 8));
    await completeQualifyingSession(DateTime(2026, 1, 4, 8)); // 48h depois

    final result = await progressionRepository.evaluateAndPromotePushHorizontal(
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

    final result = await progressionRepository.evaluateAndPromotePushHorizontal(
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

    final result = await progressionRepository.evaluateAndPromotePushHorizontal(
      currentLevel: 0,
      placementComputedAt: DateTime(2026, 1, 1),
      now: DateTime(2026, 1, 3),
    );

    expect(result!.promoted, isFalse);
    expect(result.hasPartialProgress, isTrue);
    expect(await capabilityRepository.latestFor('push_horizontal'), isNull);
  });
}
