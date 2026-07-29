import 'dart:convert';

import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/exercise_catalog.dart'
    show DoseType;
import 'package:calisthenics_rpg/features/training_plan/domain/training_plan.dart';
import 'package:calisthenics_rpg/features/training_plan/presentation/training_plan_screen.dart';
import 'package:calisthenics_rpg/features/workout_session/data/workout_session_repository.dart';
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

final _preferences = TrainingPreferenceRecord(
  id: 1,
  daysPerWeek: 2,
  minutesPerSession: 30,
  location: 'home',
  equipmentJson: '[]',
  updatedAt: DateTime(2026, 7, 1),
);

WeeklyPlan _twoDayPlan() {
  return WeeklyPlan(
    ruleVersion: 'v1',
    catalogVersion: 'v1',
    requestedDaysPerWeek: 2,
    actualDaysPerWeek: 2,
    minutesPerSession: 30,
    generatedAt: DateTime(2026, 7, 20),
    validUntil: DateTime(2026, 8, 20),
    sessions: const [
      PlannedSession(
        dayLabel: 'Dia A',
        targetMinutes: 30,
        items: [
          PlannedExerciseItem(
            pattern: 'push_horizontal',
            exerciseSlug: 'push_up_floor',
            namePtBr: 'Flexão tradicional (chão)',
            setsRepsGuidance: '3 séries de 5 repetições',
            reasonCode: PlanReasonCode.foundationGap,
          ),
        ],
      ),
      PlannedSession(
        dayLabel: 'Dia B',
        targetMinutes: 30,
        items: [
          PlannedExerciseItem(
            pattern: 'pull_horizontal',
            exerciseSlug: 'band_row',
            namePtBr: 'Remada com elástico',
            setsRepsGuidance: '3 séries de 8 repetições',
            reasonCode: PlanReasonCode.foundationGap,
          ),
        ],
      ),
    ],
  );
}

TrainingPlanRecord _recordFor(WeeklyPlan plan) {
  return TrainingPlanRecord(
    id: 1,
    requestedDaysPerWeek: plan.requestedDaysPerWeek,
    actualDaysPerWeek: plan.actualDaysPerWeek,
    minutesPerSession: plan.minutesPerSession,
    ruleVersion: plan.ruleVersion,
    catalogVersion: plan.catalogVersion,
    planJson: jsonEncode(plan.toJson()),
    generatedAt: plan.generatedAt,
    validUntil: plan.validUntil,
  );
}

/// Pedido explícito do usuário: por padrão a tela não pode despejar os
/// exercícios de todos os dias da semana de uma vez — só os do "treino
/// escolhido" (próxima sessão pendente) — mas sem tirar o acesso à
/// semana completa (agora numa segunda aba).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Widget wrap(TrainingPlanRecord record, {int initialTabIndex = 0}) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: TrainingPlanScreen(
          record: record,
          preferences: _preferences,
          placement: _placement,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  testWidgets(
    'aba "Próximo treino" mostra só os exercícios do primeiro dia pendente',
    (tester) async {
      final plan = _twoDayPlan();
      await tester.pumpWidget(wrap(_recordFor(plan)));
      await tester.pump();
      await tester.pump();

      expect(find.text('Flexão tradicional (chão)'), findsOneWidget);
      expect(find.text('Remada com elástico'), findsNothing);
    },
  );

  testWidgets('aba "Semana completa" mostra os exercícios de todos os dias', (
    tester,
  ) async {
    final plan = _twoDayPlan();
    await tester.pumpWidget(wrap(_recordFor(plan)));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Semana completa'));
    await tester.pumpAndSettle();

    expect(find.text('Flexão tradicional (chão)'), findsOneWidget);
    expect(find.text('Remada com elástico'), findsOneWidget);
  });

  testWidgets('initialTabIndex 1 abre direto na aba "Semana completa"', (
    tester,
  ) async {
    final plan = _twoDayPlan();
    await tester.pumpWidget(wrap(_recordFor(plan), initialTabIndex: 1));
    await tester.pump();
    await tester.pump();

    expect(find.text('Flexão tradicional (chão)'), findsOneWidget);
    expect(find.text('Remada com elástico'), findsOneWidget);
  });

  testWidgets('"Gerar novamente" volta a ficar clicável depois de terminar — '
      'regressão de `_regenerating` nunca sendo resetado, deixando o '
      'botão girando para sempre', (tester) async {
    final plan = _twoDayPlan();
    await tester.pumpWidget(wrap(_recordFor(plan)));
    await tester.pump();
    await tester.pump();

    final button = find.widgetWithText(OutlinedButton, 'Gerar novamente');
    await tester.dragUntilVisible(
      button,
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'não pode ficar girando para sempre depois de terminar',
    );
    expect(find.text('Gerar novamente'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(button).onPressed,
      isNotNull,
      reason: 'deve voltar a ficar clicável',
    );
  });

  testWidgets(
    'iniciar sessão a partir do plano preserva doseType/targetSeconds/'
    'targetSets/mediaSlug de cada exercício — regressão de `_startSession` '
    'reconstruindo `WorkoutSessionItem` só com 4 campos e descartando o '
    'resto (dose virava sempre reps/1 série/60s, sem imagem)',
    (tester) async {
      final plan = WeeklyPlan(
        ruleVersion: 'v1',
        catalogVersion: 'v1',
        requestedDaysPerWeek: 1,
        actualDaysPerWeek: 1,
        minutesPerSession: 20,
        generatedAt: DateTime(2026, 7, 20),
        validUntil: DateTime(2026, 8, 20),
        sessions: const [
          PlannedSession(
            dayLabel: 'Dia A',
            targetMinutes: 20,
            items: [
              PlannedExerciseItem(
                pattern: 'core_anti_extension',
                exerciseSlug: 'forearm_plank_full',
                namePtBr: 'Prancha completa',
                setsRepsGuidance: '3 séries de 30 segundos',
                reasonCode: PlanReasonCode.foundationGap,
                doseType: DoseType.duration,
                targetSets: 3,
                targetSeconds: 30,
                restSeconds: 45,
                mediaSlug: 'prancha_completa',
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: TrainingPlanScreen(
              record: _recordFor(plan),
              preferences: _preferences,
              placement: _placement,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Iniciar sessão'));
      await tester.pumpAndSettle();

      final repository = WorkoutSessionRepository(db);
      final active = await repository.latestActive();
      expect(active, isNotNull);

      final item = active!.items.single;
      expect(item.doseType, DoseType.duration);
      expect(item.targetSets, 3);
      expect(item.targetSeconds, 30);
      expect(item.restSeconds, 45);
      expect(item.mediaSlug, 'prancha_completa');
    },
  );
}
