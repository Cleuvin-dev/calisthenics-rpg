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

/// A tela de execução usa uma `ListView` com cabeçalho + imagem grande
/// (~60% do viewport) antes dos controles — em telas de teste isso
/// empurra o card de métricas/timer/botões para fora do alcance de
/// pré-construção padrão (`cacheExtent`) da sliver list, então é preciso
/// rolar antes de interagir com eles (o mesmo aconteceria fisicamente,
/// só que rolando com o dedo em vez de `tester.drag`).
Future<void> _scrollControlsIntoView(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pumpAndSettle();
}

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
    await _scrollControlsIntoView(tester);

    expect(find.text('Senti dor'), findsOneWidget);
  });

  testWidgets('toque duplo em "Concluir série" não abre dois formulários nem '
      'grava duas séries', (tester) async {
    final id = await seedRepsSession();
    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();
    await _scrollControlsIntoView(tester);

    // Rótulo do botão principal é sempre maiúsculo (visual do protótipo);
    // o botão de dentro da folha de registro (abaixo) usa o texto normal.
    final concluirButton = find.text('CONCLUIR SÉRIE');
    expect(concluirButton, findsOneWidget);

    // Dois toques em sequência rápida, sem pump() entre eles: simula o
    // "toque duplo" físico que o guard em memória (_submitting) precisa
    // bloquear antes mesmo de o Flutter reconstruir a árvore.
    await tester.tap(concluirButton, warnIfMissed: false);
    await tester.tap(concluirButton, warnIfMissed: false);
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
    await _scrollControlsIntoView(tester);

    await tester.tap(find.text('CONCLUIR SÉRIE'));
    await tester.pumpAndSettle();

    expect(find.text('10 repetições'), findsOneWidget);
    // O contador de "realmente concluídas" também começa em 10 (igual ao
    // alvo) — VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §11.
    expect(find.text('10'), findsWidgets);
  });

  testWidgets(
    'card de métricas mostra série/repetições/descanso/status corretos',
    (tester) async {
      final id = await seedRepsSession();
      await tester.pumpWidget(wrap(id));
      await tester.pumpAndSettle();
      await _scrollControlsIntoView(tester);

      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('10'), findsWidgets);
      expect(find.text('60s'), findsOneWidget);
      expect(find.text('Aguardando'), findsOneWidget);
    },
  );

  testWidgets(
    'botão "Finalizar treino" fica desabilitado até todas as séries serem '
    'registradas, e habilita depois da última (sessão de 1 exercício = '
    'sempre o último)',
    (tester) async {
      final id = await seedRepsSession();
      await tester.pumpWidget(wrap(id));
      await tester.pumpAndSettle();
      await _scrollControlsIntoView(tester);

      FilledButton nextButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Finalizar treino'),
      );

      expect(nextButton().onPressed, isNull);

      for (var i = 0; i < 3; i++) {
        await _scrollControlsIntoView(tester);
        await tester.tap(find.text('CONCLUIR SÉRIE'));
        await tester.pumpAndSettle();
        // Não usar `find.text('Adequado')` aqui: a partir da 2ª
        // repetição, o histórico de séries já logadas também mostra
        // "Adequado" (subtítulo do `ListTile`), então o texto deixa de
        // ser único na tela.
        await tester.tap(find.widgetWithText(ChoiceChip, 'Adequado'));
        await tester.pump();
        await tester.tap(find.text('Concluir série'));
        await tester.pumpAndSettle();

        // Toda série que não é a última do exercício entra em descanso
        // (seção 5 do pedido) — pular para poder registrar a próxima.
        final skipRest = find.text('Pular descanso');
        if (skipRest.evaluate().isNotEmpty) {
          await tester.tap(skipRest);
          await tester.pumpAndSettle();
        }
      }

      expect(find.text('CONCLUIR EXERCÍCIO'), findsOneWidget);
      expect(nextButton().onPressed, isNotNull);
    },
  );

  testWidgets(
    'descanso aparece depois de uma série que não é a última do exercício',
    (tester) async {
      final id = await seedRepsSession();
      await tester.pumpWidget(wrap(id));
      await tester.pumpAndSettle();
      await _scrollControlsIntoView(tester);

      await tester.tap(find.text('CONCLUIR SÉRIE'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Adequado'));
      await tester.pump();
      await tester.tap(find.text('Concluir série'));
      await tester.pumpAndSettle();

      expect(find.text('Descanso'), findsOneWidget); // status no card
      expect(find.text('Pular descanso'), findsOneWidget);
      // Enquanto descansando, não há botão para registrar a próxima
      // série ainda — evita começar a 2ª série sem querer.
      expect(find.text('CONCLUIR SÉRIE'), findsNothing);

      await tester.tap(find.text('Pular descanso'));
      await tester.pumpAndSettle();

      expect(find.text('CONCLUIR SÉRIE'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
    },
  );

  testWidgets('pular série pede confirmação e registra como não concluída', (
    tester,
  ) async {
    final id = await seedRepsSession();
    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pular série'));
    await tester.pumpAndSettle();

    // Cancelar não registra nada.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await repository.setLogsFor(id), isEmpty);

    await tester.tap(find.text('Pular série'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Pular série'));
    await tester.pumpAndSettle();

    final logs = await repository.setLogsFor(id);
    expect(logs, hasLength(1));
    expect(logs.single.perceivedEffort, 'notCompleted');
    expect(logs.single.repsCompleted, 0);
  });

  testWidgets('"Anterior" volta ao exercício sem apagar séries já salvas', (
    tester,
  ) async {
    final id = await repository.startSession(
      dayLabel: 'Treino de teste',
      items: const [
        WorkoutSessionItem(
          pattern: 'push_horizontal',
          exerciseSlug: 'push_up_incline',
          namePtBr: 'Flexão inclinada',
          setsRepsGuidance: '3 séries de 10 repetições',
          doseType: DoseType.reps,
          targetSets: 1,
          targetReps: 10,
          restSeconds: 0,
        ),
        WorkoutSessionItem(
          pattern: 'push_horizontal',
          exerciseSlug: 'push_up_floor',
          namePtBr: 'Flexão tradicional',
          setsRepsGuidance: '3 séries de 5 repetições',
          doseType: DoseType.reps,
          targetSets: 1,
          targetReps: 5,
          restSeconds: 0,
        ),
      ],
      planRuleVersion: 'v1',
      catalogVersion: 'v1',
      now: DateTime(2026, 7, 24, 8),
    );

    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();
    await _scrollControlsIntoView(tester);

    await tester.tap(find.text('CONCLUIR SÉRIE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adequado'));
    await tester.pump();
    await tester.tap(find.text('Concluir série'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    // O cabeçalho (com o nome do exercício) fica acima da imagem — rolar
    // de volta ao topo para conferir, já que o `ListView` mantém a
    // posição de rolagem anterior ao trocar de exercício.
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(find.text('Flexão tradicional'), findsOneWidget);

    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();

    expect(find.text('Flexão inclinada'), findsOneWidget);
    final logs = await repository.setLogsFor(id);
    expect(
      logs.where((l) => l.exerciseSlug == 'push_up_incline'),
      hasLength(1),
      reason: 'voltar não deve apagar a série já registrada',
    );
  });
}
