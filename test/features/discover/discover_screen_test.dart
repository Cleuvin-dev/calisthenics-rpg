import 'dart:convert';

import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/discover/presentation/discover_screen.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _placement = CapabilityEstimateRecord(
  id: 1,
  pattern: 'push_horizontal',
  level: 1,
  levelName: 'Parede',
  confidence: 'medium',
  ruleVersion: 'v1',
  reasonCode: 'assessment',
  computedAt: DateTime(2026, 7, 1),
  validUntil: DateTime(2026, 12, 31),
);

Future<void> _seedCompletedSession(AppDatabase db) async {
  final items = [
    {
      'pattern': 'push_horizontal',
      'exerciseSlug': 'push_up_wall',
      'namePtBr': 'Flexão na parede',
      'setsRepsGuidance': '3 séries de 8 repetições',
      'doseType': 'reps',
      'targetSets': 3,
      'targetReps': 8,
      'targetSeconds': null,
      'restSeconds': 60,
      'mediaSlug': null,
    },
  ];
  await db
      .into(db.workoutSessionRecords)
      .insert(
        WorkoutSessionRecordsCompanion.insert(
          dayLabel: 'Treino de teste',
          status: 'completed',
          planRuleVersion: 'v1',
          catalogVersion: 'v1',
          itemsJson: jsonEncode(items),
          startedAt: DateTime(2026, 7, 26, 8),
          completedAt: Value(DateTime(2026, 7, 26, 8, 30)),
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Widget wrap() => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(home: DiscoverScreen(placement: _placement)),
  );

  /// A tela tem muitos filtros + 24 exercícios; um viewport alto evita
  /// depender de rolagem (que tiraria os chips de filtro da árvore
  /// construída pelos slivers) só para localizar texto nos testes.
  void useTallTestViewport(WidgetTester tester) {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(1600, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });
  }

  testWidgets('filtro de padrão de movimento restringe exercícios exibidos', (
    tester,
  ) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 400));

    // 'Remada com elástico' é pull_horizontal; 'Squat' é o rótulo do
    // padrão squat.
    expect(find.text('Remada com elástico'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Squat'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Squat'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Resultados'), findsNothing);
    expect(find.text('Remada com elástico'), findsNothing);
  });

  testWidgets(
    'filtro "sem equipamento" esconde exercícios que exigem equipamento',
    (tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Remada com elástico'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Sem equipamento'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Remada com elástico'), findsNothing);
    },
  );

  testWidgets('chip de Favoritos aparece desabilitado, sem fingir suporte', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 400));

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Favoritos'),
    );
    expect(chip.onSelected, isNull);
  });

  testWidgets(
    'seção Recentes mostra exercícios de sessões concluídas de verdade',
    (tester) async {
      await _seedCompletedSession(db);
      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Recentes'), findsOneWidget);
      expect(find.text('Flexão na parede'), findsWidgets);
    },
  );
}
