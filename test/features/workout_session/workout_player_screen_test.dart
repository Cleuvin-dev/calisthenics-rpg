import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/exercise_catalog.dart'
    show DoseType;
import 'package:calisthenics_rpg/features/workout_session/data/workout_session_repository.dart';
import 'package:calisthenics_rpg/features/workout_session/domain/workout_session.dart';
import 'package:calisthenics_rpg/features/workout_session/presentation/log_set_sheet.dart';
import 'package:calisthenics_rpg/features/workout_session/presentation/workout_player_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _placement = CapabilityEstimateRecord(
  id: 1,
  pattern: 'push_horizontal',
  level: 2,
  levelName: 'nivel_2',
  confidence: 'medium',
  ruleVersion: 'v1',
  reasonCode: 'assessment',
  computedAt: DateTime(2026, 7, 1),
  validUntil: DateTime(2026, 12, 31),
);

/// SETTINGS_AND_TIMED_EXERCISES.md/TEST_STRATEGY.md: "toque duplo em
/// Concluir não pode duplicar" e o botão `Senti dor` precisa estar
/// sempre acessível no player, nunca escondido em menu.
void main() {
  late AppDatabase db;
  late WorkoutSessionRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = WorkoutSessionRepository(db);
  });

  tearDown(() => db.close());

  Future<int> seedRepsSession() {
    return repository.startSession(
      dayLabel: 'Treino de teste',
      items: const [
        WorkoutSessionItem(
          pattern: 'push_horizontal',
          exerciseSlug: 'push_up_incline',
          namePtBr: 'Flexão inclinada',
          setsRepsGuidance: '3 séries de 10 repetições',
          doseType: DoseType.reps,
          targetSets: 3,
          targetReps: 10,
          restSeconds: 60,
        ),
      ],
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: DateTime(2026, 7, 24, 8),
    );
  }

  Widget wrap(int sessionId) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: WorkoutPlayerScreen(
          workoutSessionId: sessionId,
          pushHorizontalPlacement: _placement,
        ),
      ),
    );
  }

  testWidgets('botão "Senti dor" está sempre visível no player por reps', (
    tester,
  ) async {
    final id = await seedRepsSession();
    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();

    expect(find.text('Senti dor'), findsOneWidget);
  });

  testWidgets('toque duplo em "Registrar série" não abre dois formulários nem '
      'grava duas séries', (tester) async {
    final id = await seedRepsSession();
    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();

    final registrarButton = find.text('Registrar série');
    expect(registrarButton, findsOneWidget);

    // Dois toques em sequência rápida, sem pump() entre eles: simula o
    // "toque duplo" físico que o guard em memória (_submitting) precisa
    // bloquear antes mesmo de o Flutter reconstruir a árvore.
    await tester.tap(registrarButton, warnIfMissed: false);
    await tester.tap(registrarButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Só uma folha de registro deve estar na tela, nunca duas
    // empilhadas.
    expect(find.byType(LogSetSheet), findsOneWidget);

    await tester.tap(find.text('Adequado'));
    await tester.pump();
    await tester.tap(find.text('Concluir série'));
    await tester.pumpAndSettle();

    final logs = await repository.setLogsFor(id);
    expect(logs, hasLength(1));
  });

  testWidgets('ajustar repetições no formulário começa igual ao alvo', (
    tester,
  ) async {
    final id = await seedRepsSession();
    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar série'));
    await tester.pumpAndSettle();

    expect(find.text('10 repetições'), findsOneWidget);
    // O contador de "realmente concluídas" também começa em 10 (igual ao
    // alvo) — VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §11.
    expect(find.text('10'), findsWidgets);
  });
}
