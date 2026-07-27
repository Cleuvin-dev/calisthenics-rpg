import 'dart:convert';
import 'dart:io';

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

void main() {
  testWidgets('quatro abas preservam o estado da busca ao alternar', (
    tester,
  ) async {
    late AppDatabase db;
    late Directory directory;
    // NativeDatabase/temp dir setup does real isolate + file I/O, which never
    // resolves inside testWidgets' FakeAsync zone unless run via runAsync.
    await tester.runAsync(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      directory = await Directory.systemTemp.createTemp('shell_settings_');
    });
    addTearDown(db.close);
    addTearDown(() => directory.delete(recursive: true));
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepository(directoryProvider: () async => directory),
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
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Descobrir'), findsOneWidget);
    expect(find.text('Relatório'), findsOneWidget);
    expect(find.text('Definição'), findsOneWidget);

    await tester.tap(find.text('Descobrir'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(SearchBar), 'prancha');
    await tester.pump();
    expect(find.text('prancha'), findsOneWidget);

    await tester.tap(find.text('Relatório'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Descobrir'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('prancha'), findsOneWidget);
  });
}
