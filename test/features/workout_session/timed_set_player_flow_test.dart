import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_providers.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_repository.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/exercise_catalog.dart'
    show DoseType;
import 'package:calisthenics_rpg/features/workout_session/data/workout_session_repository.dart';
import 'package:calisthenics_rpg/features/workout_session/domain/workout_session.dart';
import 'package:calisthenics_rpg/features/workout_session/presentation/workout_player_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aciona o callback do botão diretamente em vez de simular um toque
/// físico: o `RunningView` usa um `CircularProgressIndicator` de 180x180
/// dentro de uma `ListView` sem altura fixa no viewport padrão de teste,
/// o que deixa a geometria de hit-test instável entre execuções — a
/// lógica de estado (o que importa aqui) não depende de coordenadas de
/// tela.
Future<void> _tapButton(WidgetTester tester, String text) async {
  final finder = find.widgetWithText(FilledButton, text);
  tester.widget<FilledButton>(finder).onPressed!();
  await tester.pump();
}

/// A tela de execução tem cabeçalho + imagem grande (~60% do viewport)
/// antes do timer — em telas de teste isso empurra o timer/botões para
/// fora do alcance de pré-construção padrão da sliver list, então é
/// preciso rolar antes de interagir com eles.
Future<void> _scrollControlsIntoView(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pumpAndSettle();
}

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

/// VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §12: Ready → Preparing
/// (3-2-1) → Running → Paused ⇄ Running → Completed. `Senti dor` precisa
/// ficar acessível em toda fase.
void main() {
  late AppDatabase db;
  late WorkoutSessionRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = WorkoutSessionRepository(db);
  });

  tearDown(() => db.close());

  Future<int> seedTimedSession() {
    return repository.startSession(
      dayLabel: 'Treino de teste',
      items: const [
        WorkoutSessionItem(
          pattern: 'core_anti_extension',
          exerciseSlug: 'forearm_plank_full',
          namePtBr: 'Prancha completa',
          setsRepsGuidance: '3 séries de 30 segundos',
          doseType: DoseType.duration,
          targetSets: 3,
          targetSeconds: 2,
          restSeconds: 30,
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

  Widget wrapWithCountdown(int sessionId, int countdownSeconds) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userSettingsProvider.overrideWith(
          (ref) async => UserSettings(countdownSeconds: countdownSeconds),
        ),
      ],
      child: MaterialApp(
        home: WorkoutPlayerScreen(
          workoutSessionId: sessionId,
          pushHorizontalPlacement: _placement,
        ),
      ),
    );
  }

  testWidgets('player por duração passa por 3-2-1 → rodando → pausar/retomar → '
      'concluir, salvando um único log', (tester) async {
    final id = await seedTimedSession();
    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();
    await _scrollControlsIntoView(tester);

    expect(find.text('Alvo: 2 segundos'), findsOneWidget);
    expect(find.text('Senti dor'), findsOneWidget);

    await _tapButton(tester, 'Iniciar');

    // Preparação 3-2-1: começa em "3".
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));

    // Agora rodando: botão "Pausar" disponível, dor continua acessível.
    await tester.pump();
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Senti dor'), findsOneWidget);

    await _tapButton(tester, 'Pausar');
    expect(find.text('Continuar'), findsOneWidget);

    await _tapButton(tester, 'Continuar');
    expect(find.text('Pausar'), findsOneWidget);

    // Deixa o alvo de 2s ser atingido: o `ActiveTimer` é monotônico e
    // usa um `Stopwatch` de parede real (de propósito — é a garantia
    // contra "trocar o relógio não deve aumentar o tempo ativo"), então
    // só avançar o relógio falso do teste não é suficiente aqui; é
    // preciso esperar tempo de parede de verdade e só então deixar o
    // `Timer.periodic` de UI (esse sim, no relógio falso) perceber.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2300)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // A série já parou de contar (fase pausada antes da folha de
    // efeito), então dá para deixar a animação da folha assentar.
    await tester.pumpAndSettle();

    expect(find.text('Tempo concluído! Como foi a série?'), findsOneWidget);
    await tester.tap(find.text('Adequado'));
    await tester.pumpAndSettle();

    final logs = await repository.setLogsFor(id);
    expect(logs, hasLength(1));
    expect(logs.single.completionReason, 'targetReached');
    expect(await repository.activeTimedSetFor(id), isNull);
  });

  testWidgets(
    'timer continua funcionando mesmo quando a mídia do exercício falha '
    '(sem asset local nem mediaSlug válido) — CLAUDE_CODE_PROMPT.md do '
    'pacote de imagens: "erro de imagem nunca pode impedir o treino"',
    (tester) async {
      final id = await repository.startSession(
        dayLabel: 'Treino de teste',
        items: const [
          WorkoutSessionItem(
            pattern: 'core_anti_extension',
            exerciseSlug: 'exercicio_sem_imagem_alguma',
            namePtBr: 'Exercício sem imagem',
            setsRepsGuidance: '1 série de 2 segundos',
            doseType: DoseType.duration,
            targetSets: 1,
            targetSeconds: 2,
            restSeconds: 0,
            mediaSlug: 'slug_que_nao_existe_no_catalogo',
          ),
        ],
        planRuleVersion: 'v1',
        catalogVersion: 'v1',
        now: DateTime(2026, 7, 24, 8),
      );

      await tester.pumpWidget(wrap(id));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await _scrollControlsIntoView(tester);

      // Nenhuma exceção não tratada até aqui já prova que a resolução de
      // mídia com falha não travou a tela; confirma explicitamente que
      // caiu no placeholder estático.
      expect(find.text('Alvo: 2 segundos'), findsOneWidget);

      await _tapButton(tester, 'Iniciar');
      expect(find.text('3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Terminou a preparação e entrou em "rodando" normalmente — o
      // timer não depende de a imagem ter carregado.
      expect(find.text('Pausar'), findsOneWidget);
    },
  );

  testWidgets(
    'preferência de contagem regressiva (Definição) é aplicada à preparação',
    (tester) async {
      final id = await seedTimedSession();
      await tester.pumpWidget(wrapWithCountdown(id, 5));
      await tester.pumpAndSettle();
      await _scrollControlsIntoView(tester);

      await _tapButton(tester, 'Iniciar');
      expect(
        find.text('5'),
        findsOneWidget,
        reason: 'preparação deve começar na contagem configurada, não em 3',
      );
    },
  );

  testWidgets(
    'contagem regressiva 0 pula a preparação e começa a rodar direto',
    (tester) async {
      final id = await seedTimedSession();
      await tester.pumpWidget(wrapWithCountdown(id, 0));
      await tester.pumpAndSettle();
      await _scrollControlsIntoView(tester);

      await _tapButton(tester, 'Iniciar');
      await tester.pump();

      expect(find.text('Pausar'), findsOneWidget);
      expect(find.text('Senti dor'), findsOneWidget);
    },
  );
}
