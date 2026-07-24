import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/workout_session/data/workout_session_repository.dart';
import 'package:calisthenics_rpg/features/workout_session/domain/workout_session.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkoutSessionRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = WorkoutSessionRepository(db);
  });

  tearDown(() => db.close());

  const items = [
    WorkoutSessionItem(
      pattern: 'push_horizontal',
      exerciseSlug: 'push_up_wall',
      namePtBr: 'Flexão na parede',
      setsRepsGuidance: '2 séries de 6-10 repetições',
    ),
    WorkoutSessionItem(
      pattern: 'squat',
      exerciseSlug: 'sit_to_stand_squat',
      namePtBr: 'Agachamento livre',
      setsRepsGuidance: '2-3 séries de 8-15 repetições',
    ),
  ];

  test('latestActive retorna null sem sessão iniciada', () async {
    expect(await repository.latestActive(), isNull);
  });

  test('startSession cria sessão em andamento com itens congelados', () async {
    final id = await repository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'weekly-plan-v1',
      catalogVersion: 'minimal-catalog-v1',
      now: DateTime(2026, 7, 24, 8),
    );

    final active = await repository.latestActive();
    expect(active, isNotNull);
    expect(active!.id, id);
    expect(active.status, WorkoutSessionStatus.inProgress.name);
    expect(active.items.length, 2);
    expect(active.items.first.exerciseSlug, 'push_up_wall');
  });

  test('logSet grava a série e mantém a ordem de gravação', () async {
    final id = await repository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'weekly-plan-v1',
      catalogVersion: 'minimal-catalog-v1',
      now: DateTime(2026, 7, 24, 8),
    );

    await repository.logSet(
      workoutSessionId: id,
      exerciseSlug: 'push_up_wall',
      pattern: 'push_horizontal',
      setNumber: 1,
      repsCompleted: 8,
      perceivedEffort: PerceivedEffort.adequate,
      now: DateTime(2026, 7, 24, 8, 5),
    );
    await repository.logSet(
      workoutSessionId: id,
      exerciseSlug: 'push_up_wall',
      pattern: 'push_horizontal',
      setNumber: 2,
      repsCompleted: 6,
      perceivedEffort: PerceivedEffort.hardCompleted,
      now: DateTime(2026, 7, 24, 8, 8),
    );

    final logs = await repository.setLogsFor(id);
    expect(logs.length, 2);
    expect(logs.first.setNumber, 1);
    expect(logs.last.perceivedEffort, PerceivedEffort.hardCompleted.name);
  });

  test('pause e resume alternam o status sem apagar sessão', () async {
    final id = await repository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: DateTime(2026, 7, 24),
    );

    await repository.pause(id);
    var active = await repository.latestActive();
    expect(active!.status, WorkoutSessionStatus.paused.name);

    await repository.resume(id);
    active = await repository.latestActive();
    expect(active!.status, WorkoutSessionStatus.inProgress.name);
  });

  test('complete encerra a sessão e ela deixa de ser "ativa"', () async {
    final id = await repository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: DateTime(2026, 7, 24),
    );

    await repository.complete(id, DateTime(2026, 7, 24, 9));

    expect(await repository.latestActive(), isNull);
  });

  test('abandon encerra a sessão e ela deixa de ser "ativa"', () async {
    final id = await repository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: DateTime(2026, 7, 24),
    );

    await repository.abandon(id, DateTime(2026, 7, 24, 9));

    expect(await repository.latestActive(), isNull);
  });

  test('latestActive prioriza a sessão ativa mais recente', () async {
    final firstId = await repository.startSession(
      dayLabel: 'Full Body A',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: DateTime(2026, 7, 1),
    );
    await repository.abandon(firstId, DateTime(2026, 7, 1, 1));

    final secondId = await repository.startSession(
      dayLabel: 'Full Body B',
      items: items,
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: DateTime(2026, 7, 24),
    );

    final active = await repository.latestActive();
    expect(active!.id, secondId);
    expect(active.dayLabel, 'Full Body B');
  });

  test(
    'completedSessions retorna só concluídas, mais recente primeiro',
    () async {
      final inProgressId = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );

      final oldId = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );
      await repository.complete(oldId, DateTime(2026, 7, 1, 9));

      final newId = await repository.startSession(
        dayLabel: 'Full Body B',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 10),
      );
      await repository.complete(newId, DateTime(2026, 7, 10, 9));

      final completed = await repository.completedSessions();

      expect(completed.map((s) => s.id), [newId, oldId]);
      expect(completed.any((s) => s.id == inProgressId), isFalse);
    },
  );

  test(
    'bestRepsByExercise ignora dor/não completei e pega o maior valor',
    () async {
      final id = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );

      await repository.logSet(
        workoutSessionId: id,
        exerciseSlug: 'push_up_wall',
        pattern: 'push_horizontal',
        setNumber: 1,
        repsCompleted: 6,
        perceivedEffort: PerceivedEffort.adequate,
        now: DateTime(2026, 7, 1),
      );
      await repository.logSet(
        workoutSessionId: id,
        exerciseSlug: 'push_up_wall',
        pattern: 'push_horizontal',
        setNumber: 2,
        repsCompleted: 9,
        perceivedEffort: PerceivedEffort.hardCompleted,
        now: DateTime(2026, 7, 1),
      );
      await repository.logSet(
        workoutSessionId: id,
        exerciseSlug: 'push_up_wall',
        pattern: 'push_horizontal',
        setNumber: 3,
        repsCompleted: 20,
        perceivedEffort: PerceivedEffort.pain,
        now: DateTime(2026, 7, 1),
      );

      final best = await repository.bestRepsByExercise();

      expect(best['push_up_wall'], 9); // ignora a série de 20 reps com dor
    },
  );

  group('idempotência (toque duplo em concluir)', () {
    test('logSet chamado duas vezes com os mesmos parâmetros grava um '
        'único log', () async {
      final id = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );

      final first = await repository.logSet(
        workoutSessionId: id,
        exerciseSlug: 'push_up_wall',
        pattern: 'push_horizontal',
        setNumber: 1,
        repsCompleted: 8,
        targetReps: 8,
        perceivedEffort: PerceivedEffort.adequate,
        now: DateTime(2026, 7, 1, 8, 0),
      );
      final second = await repository.logSet(
        workoutSessionId: id,
        exerciseSlug: 'push_up_wall',
        pattern: 'push_horizontal',
        setNumber: 1,
        repsCompleted: 8,
        targetReps: 8,
        perceivedEffort: PerceivedEffort.adequate,
        now: DateTime(2026, 7, 1, 8, 0, 2), // segundo toque, 2s depois
      );

      expect(first, isTrue);
      expect(second, isFalse);
      final logs = await repository.setLogsFor(id);
      expect(logs.length, 1);
      expect(logs.single.targetReps, 8);
    });
  });

  group('série por tempo (timer ativo persistido)', () {
    test('activeTimedSetFor retorna null sem timer iniciado', () async {
      final id = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );
      expect(await repository.activeTimedSetFor(id), isNull);
    });

    test('startTimedSet cria o estado e updateTimedSetProgress persiste '
        'o progresso', () async {
      final id = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );

      await repository.startTimedSet(
        workoutSessionId: id,
        exerciseSlug: 'forearm_plank_full',
        pattern: 'core_anti_extension',
        setNumber: 1,
        targetSeconds: 30,
        now: DateTime(2026, 7, 1, 8, 0),
      );

      var active = await repository.activeTimedSetFor(id);
      expect(active, isNotNull);
      expect(active!.status, 'running');
      expect(active.activeElapsedMs, 0);

      await repository.updateTimedSetProgress(
        workoutSessionId: id,
        activeElapsedMs: 12000,
        running: false, // usuário pausou
        now: DateTime(2026, 7, 1, 8, 0, 12),
      );

      active = await repository.activeTimedSetFor(id);
      expect(active!.status, 'paused');
      expect(active.activeElapsedMs, 12000);
    });

    test('finalizeTimedSet grava o log e remove o estado ativo numa '
        'transação', () async {
      final id = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );
      await repository.startTimedSet(
        workoutSessionId: id,
        exerciseSlug: 'forearm_plank_full',
        pattern: 'core_anti_extension',
        setNumber: 1,
        targetSeconds: 30,
        now: DateTime(2026, 7, 1, 8, 0),
      );

      final granted = await repository.finalizeTimedSet(
        workoutSessionId: id,
        exerciseSlug: 'forearm_plank_full',
        pattern: 'core_anti_extension',
        setNumber: 1,
        targetSeconds: 30,
        activeDurationMs: 30500,
        completionReason: TimedSetCompletionReason.targetReached,
        perceivedEffort: PerceivedEffort.adequate,
        now: DateTime(2026, 7, 1, 8, 0, 31),
      );

      expect(granted, isTrue);
      expect(await repository.activeTimedSetFor(id), isNull);

      final logs = await repository.setLogsFor(id);
      expect(logs.length, 1);
      expect(logs.single.targetSeconds, 30);
      expect(logs.single.activeDurationMs, 30500);
      expect(
        logs.single.completionReason,
        TimedSetCompletionReason.targetReached.name,
      );
    });

    test('finalizeTimedSet chamado duas vezes não duplica o log '
        '(processo morto e reaberto antes de terminar)', () async {
      final id = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );
      await repository.startTimedSet(
        workoutSessionId: id,
        exerciseSlug: 'forearm_plank_full',
        pattern: 'core_anti_extension',
        setNumber: 1,
        targetSeconds: 30,
        now: DateTime(2026, 7, 1, 8, 0),
      );

      Future<bool> finalize() => repository.finalizeTimedSet(
        workoutSessionId: id,
        exerciseSlug: 'forearm_plank_full',
        pattern: 'core_anti_extension',
        setNumber: 1,
        targetSeconds: 30,
        activeDurationMs: 30200,
        completionReason: TimedSetCompletionReason.targetReached,
        perceivedEffort: PerceivedEffort.adequate,
        now: DateTime(2026, 7, 1, 8, 0, 31),
      );

      expect(await finalize(), isTrue);
      expect(await finalize(), isFalse);

      final logs = await repository.setLogsFor(id);
      expect(logs.length, 1);
    });

    test('discardActiveTimedSet remove o estado sem gravar log', () async {
      final id = await repository.startSession(
        dayLabel: 'Full Body A',
        items: items,
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 1),
      );
      await repository.startTimedSet(
        workoutSessionId: id,
        exerciseSlug: 'forearm_plank_full',
        pattern: 'core_anti_extension',
        setNumber: 1,
        targetSeconds: 30,
        now: DateTime(2026, 7, 1, 8, 0),
      );

      await repository.discardActiveTimedSet(id);

      expect(await repository.activeTimedSetFor(id), isNull);
      expect(await repository.setLogsFor(id), isEmpty);
    });
  });
}
