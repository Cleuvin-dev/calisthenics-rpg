import 'dart:convert';

import 'package:calisthenics_rpg/app/main_shell.dart';
import 'package:calisthenics_rpg/app/theme.dart';
import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_providers.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_repository.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/training_plan.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend em memória, sem I/O real — ver o mesmo motivo documentado em
/// settings_screen_weekdays_test.dart.
class _InMemorySettingsRepository extends SettingsRepository {
  UserSettings _current = const UserSettings();

  @override
  Future<UserSettings> load() async => _current;

  @override
  Future<void> save(UserSettings settings) async {
    _current = settings;
  }
}

/// Validação visual/responsiva (pendência #11 do handoff e
/// APP_RPG_CALISTENIA_REDESENHO...md §3.2/§11/§12): as quatro abas não
/// podem estourar layout em telas pequenas/grandes nem com escala de
/// fonte ampliada — verificado automatizando o que seria feito
/// manualmente com screenshots, já que não há emulador móvel disponível
/// neste ambiente (só desktop/Chrome/Edge).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Widget buildShell() {
    final now = DateTime(2026, 7, 27);
    final plan = WeeklyPlan(
      ruleVersion: 'test',
      catalogVersion: 'test',
      requestedDaysPerWeek: 2,
      actualDaysPerWeek: 2,
      minutesPerSession: 20,
      sessions: const [],
      generatedAt: now,
      validUntil: now.add(const Duration(days: 7)),
    );
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(
          _InMemorySettingsRepository(),
        ),
      ],
      child: MaterialApp(
        theme: buildCalisthenicsRpgTheme(),
        home: MainShell(
          record: TrainingPlanRecord(
            id: 1,
            requestedDaysPerWeek: 2,
            actualDaysPerWeek: 2,
            minutesPerSession: 20,
            ruleVersion: 'test',
            catalogVersion: 'test',
            planJson: jsonEncode(plan.toJson()),
            generatedAt: now,
            validUntil: now.add(const Duration(days: 7)),
          ),
          preferences: TrainingPreferenceRecord(
            id: 1,
            daysPerWeek: 2,
            minutesPerSession: 20,
            location: 'home',
            equipmentJson: '[]',
            updatedAt: now,
          ),
          placement: CapabilityEstimateRecord(
            id: 1,
            pattern: 'push_horizontal',
            level: 1,
            levelName: 'Parede',
            confidence: 'medium',
            ruleVersion: 'test',
            reasonCode: 'test',
            computedAt: now,
            validUntil: now.add(const Duration(days: 30)),
          ),
        ),
      ),
    );
  }

  Future<void> visitAllTabsAndAssertNoOverflow(WidgetTester tester) async {
    for (final tab in ['Descobrir', 'Relatório', 'Definição', 'Treino']) {
      // Escopado à NavigationBar: o rótulo pode colidir com o título de
      // AppBar da própria aba (ambas as telas ficam montadas ao mesmo
      // tempo no IndexedStack) ou com um duplicado transitório da
      // animação de seleção do NavigationBar do Material 3.
      final destination = find
          .descendant(of: find.byType(NavigationBar), matching: find.text(tab))
          .first;
      await tester.tap(destination);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow ou exceção ao abrir a aba "$tab"',
      );
      // Uma rolagem expõe conteúdo além do viewport inicial (os slivers
      // só constroem o que está perto da tela), sem depender de
      // pumpAndSettle — animações contínuas do placeholder de exercício
      // nunca "assentam".
      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow ou exceção ao rolar a aba "$tab"',
      );
    }
  }

  final scenarios = <(String, Size, double)>[
    ('celular pequeno, fonte 1.0x', Size(360, 690), 1.0),
    ('celular pequeno, fonte 1.4x (limite do slider de acessibilidade)', Size(360, 690), 1.4),
    ('celular pequeno, fonte 2.0x (escala máxima do sistema)', Size(360, 690), 2.0),
    ('tablet grande, fonte 1.0x', Size(1024, 1366), 1.0),
  ];

  for (final (description, size, textScale) in scenarios) {
    testWidgets('sem overflow em $description', (tester) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildShell());
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);

      await visitAllTabsAndAssertNoOverflow(tester);
    });
  }

  testWidgets('sem overflow com alto contraste ativado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(
            _InMemorySettingsRepository(),
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            theme: buildCalisthenicsRpgTheme(highContrast: true),
            home: MainShell(
              record: TrainingPlanRecord(
                id: 1,
                requestedDaysPerWeek: 2,
                actualDaysPerWeek: 2,
                minutesPerSession: 20,
                ruleVersion: 'test',
                catalogVersion: 'test',
                planJson: jsonEncode(
                  WeeklyPlan(
                    ruleVersion: 'test',
                    catalogVersion: 'test',
                    requestedDaysPerWeek: 2,
                    actualDaysPerWeek: 2,
                    minutesPerSession: 20,
                    sessions: const [],
                    generatedAt: DateTime(2026, 7, 27),
                    validUntil: DateTime(2026, 8, 3),
                  ).toJson(),
                ),
                generatedAt: DateTime(2026, 7, 27),
                validUntil: DateTime(2026, 8, 3),
              ),
              preferences: TrainingPreferenceRecord(
                id: 1,
                daysPerWeek: 2,
                minutesPerSession: 20,
                location: 'home',
                equipmentJson: '[]',
                updatedAt: DateTime(2026, 7, 27),
              ),
              placement: CapabilityEstimateRecord(
                id: 1,
                pattern: 'push_horizontal',
                level: 1,
                levelName: 'Parede',
                confidence: 'medium',
                ruleVersion: 'test',
                reasonCode: 'test',
                computedAt: DateTime(2026, 7, 27),
                validUntil: DateTime(2026, 8, 26),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await visitAllTabsAndAssertNoOverflow(tester);
  });
}
