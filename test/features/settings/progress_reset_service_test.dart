import 'dart:convert';

import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/settings/data/progress_reset_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seed(db);
  });

  tearDown(() => db.close());

  test('apaga progresso e preserva triagem e preferências', () async {
    final result = await ProgressResetService(db).reset();

    expect(result.deletedRows, greaterThan(0));
    await _expectProgressEmpty(db);
    expect(await db.select(db.safetyScreenings).get(), hasLength(1));
    expect(await db.select(db.trainingPreferenceRecords).get(), hasLength(1));
    expect(
      (await db.select(db.trainingPreferenceRecords).get()).single.heightCm,
      175,
      reason: 'altura é perfil, não progresso — sobrevive ao reset',
    );
    expect(await db.select(db.bodyMetricRecords).get(), isEmpty);
    expect(
      await db.select(db.favoriteRecords).get(),
      hasLength(1),
      reason:
          'favorito é preferência pessoal, não progresso — sobrevive ao reset',
    );
  });

  test('é idempotente quando executado repetidamente', () async {
    final service = ProgressResetService(db);
    await service.reset();
    final second = await service.reset();

    expect(second.deletedRows, 0);
    await _expectProgressEmpty(db);
    expect(await db.select(db.trainingPreferenceRecords).get(), hasLength(1));
  });

  test('falha força rollback e não deixa apagamento parcial', () async {
    final service = ProgressResetService(
      db,
      beforeCommitForTesting: () async => throw StateError('falha simulada'),
    );

    await expectLater(service.reset(), throwsStateError);

    expect(await db.select(db.capabilityEstimateRecords).get(), hasLength(1));
    expect(await db.select(db.trainingPlanRecords).get(), hasLength(1));
    expect(await db.select(db.workoutSessionRecords).get(), hasLength(1));
    expect(await db.select(db.setLogRecords).get(), hasLength(1));
    expect(await db.select(db.activeTimedSetRecords).get(), hasLength(1));
    expect(await db.select(db.xpLedgerRecords).get(), hasLength(1));
    expect(await db.select(db.outboxEvents).get(), hasLength(1));
    expect(await db.select(db.bodyMetricRecords).get(), hasLength(1));
  });
}

Future<void> _seed(AppDatabase db) async {
  final now = DateTime(2026, 7, 27, 9);
  await db
      .into(db.safetyScreenings)
      .insert(
        SafetyScreeningsCompanion.insert(
          hasCardiovascularCondition: false,
          chestPainAtRestOrExertion: false,
          faintingOrSevereDizziness: false,
          boneJointNeurologicalOrRecentSurgery: false,
          medicationsAffectingExercise: false,
          pregnantOrPostpartum: false,
          hasCurrentPain: false,
          priorMedicalAdviceToLimitActivity: false,
          consentAccepted: true,
          result: 'cleared',
          completedAt: now,
        ),
      );
  await db
      .into(db.trainingPreferenceRecords)
      .insert(
        TrainingPreferenceRecordsCompanion.insert(
          daysPerWeek: 3,
          minutesPerSession: 30,
          location: 'home',
          equipmentJson: '[]',
          updatedAt: now,
          heightCm: const Value(175),
        ),
      );
  await db
      .into(db.bodyMetricRecords)
      .insert(
        BodyMetricRecordsCompanion.insert(
          recordedAt: now,
          weightKg: 80,
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db
      .into(db.favoriteRecords)
      .insert(
        FavoriteRecordsCompanion.insert(
          itemType: 'exercise',
          itemSlug: 'push_up_incline',
          createdAt: now,
        ),
      );
  await db
      .into(db.capabilityEstimateRecords)
      .insert(
        CapabilityEstimateRecordsCompanion.insert(
          pattern: 'push_horizontal',
          level: 2,
          levelName: 'Inclinado',
          confidence: 'medium',
          ruleVersion: 'test',
          reasonCode: 'test',
          computedAt: now,
          validUntil: now.add(const Duration(days: 30)),
        ),
      );
  await db
      .into(db.trainingPlanRecords)
      .insert(
        TrainingPlanRecordsCompanion.insert(
          requestedDaysPerWeek: 3,
          actualDaysPerWeek: 3,
          minutesPerSession: 30,
          ruleVersion: 'test',
          catalogVersion: 'test',
          planJson: jsonEncode({'sessions': <Object>[]}),
          generatedAt: now,
          validUntil: now.add(const Duration(days: 7)),
        ),
      );
  final sessionId = await db
      .into(db.workoutSessionRecords)
      .insert(
        WorkoutSessionRecordsCompanion.insert(
          dayLabel: 'Dia A',
          status: 'paused',
          planRuleVersion: 'test',
          catalogVersion: 'test',
          itemsJson: '[]',
          startedAt: now,
        ),
      );
  await db
      .into(db.setLogRecords)
      .insert(
        SetLogRecordsCompanion.insert(
          workoutSessionId: sessionId,
          exerciseSlug: 'push_up_wall',
          pattern: 'push_horizontal',
          setNumber: 1,
          repsCompleted: 8,
          perceivedEffort: 'adequate',
          completedAt: now,
          clientEventId: const Value('event-1'),
        ),
      );
  await db
      .into(db.activeTimedSetRecords)
      .insert(
        ActiveTimedSetRecordsCompanion.insert(
          workoutSessionId: Value(sessionId),
          exerciseSlug: 'plank',
          pattern: 'core_anti_extension',
          setNumber: 1,
          targetSeconds: 30,
          activeElapsedMs: 1000,
          status: 'paused',
          startedAtUtc: now,
          lastPersistedAtUtc: now,
        ),
      );
  await db
      .into(db.xpLedgerRecords)
      .insert(
        XpLedgerRecordsCompanion.insert(
          amount: 25,
          eventType: 'sessionCompleted',
          sourceId: 'session-$sessionId',
          idempotencyKey: 'xp-1',
          ruleVersion: 'test',
          createdAt: now,
        ),
      );
  await db
      .into(db.outboxEvents)
      .insert(
        OutboxEventsCompanion.insert(
          eventId: 'event-1',
          clientSessionId: '$sessionId',
          eventType: 'setLogged',
          payloadJson: '{}',
          createdAt: now,
        ),
      );
}

Future<void> _expectProgressEmpty(AppDatabase db) async {
  expect(await db.select(db.capabilityEstimateRecords).get(), isEmpty);
  expect(await db.select(db.trainingPlanRecords).get(), isEmpty);
  expect(await db.select(db.workoutSessionRecords).get(), isEmpty);
  expect(await db.select(db.setLogRecords).get(), isEmpty);
  expect(await db.select(db.activeTimedSetRecords).get(), isEmpty);
  expect(await db.select(db.xpLedgerRecords).get(), isEmpty);
  expect(await db.select(db.outboxEvents).get(), isEmpty);
  expect(await db.select(db.bodyMetricRecords).get(), isEmpty);
}
