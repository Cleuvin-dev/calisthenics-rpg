import 'dart:convert';

import 'package:calisthenics_rpg/app/theme.dart';
import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/report/presentation/report_screen.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cobre as seções de Relatório que dependem de dados reais cruzados
/// (aderência ao plano, recordes pessoais e volume por padrão), não só o
/// estado vazio já coberto em report_screen_test.dart.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> seed() async {
    final now = DateTime.now();
    await db
        .into(db.trainingPlanRecords)
        .insert(
          TrainingPlanRecordsCompanion.insert(
            requestedDaysPerWeek: 3,
            actualDaysPerWeek: 3,
            minutesPerSession: 30,
            ruleVersion: 'v1',
            catalogVersion: 'v1',
            planJson: jsonEncode({'sessions': <Object>[]}),
            generatedAt: now,
            validUntil: now.add(const Duration(days: 7)),
          ),
        );
    final sessionId = await db
        .into(db.workoutSessionRecords)
        .insert(
          WorkoutSessionRecordsCompanion.insert(
            dayLabel: 'Treino A',
            status: 'completed',
            planRuleVersion: 'v1',
            catalogVersion: 'v1',
            itemsJson: '[]',
            startedAt: now.subtract(const Duration(minutes: 30)),
            completedAt: Value(now),
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
            repsCompleted: 12,
            perceivedEffort: 'adequate',
            completedAt: now,
            clientEventId: const Value('evt-1'),
          ),
        );
    await db
        .into(db.xpLedgerRecords)
        .insert(
          XpLedgerRecordsCompanion.insert(
            amount: 40,
            eventType: 'sessionCompleted',
            sourceId: '$sessionId',
            idempotencyKey: 'xp-session-$sessionId',
            ruleVersion: 'v1',
            createdAt: now,
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
            weightKg: 70,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  testWidgets(
    'aderência, recordes pessoais e volume por padrão refletem dados reais',
    (tester) async {
      await seed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildCalisthenicsRpgTheme(),
            home: const ReportScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Aderência: 1 sessão concluída de uma meta de 3/semana.
      await tester.dragUntilVisible(
        find.textContaining('sessões esperadas'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('sessões esperadas'), findsOneWidget);
      expect(find.textContaining('meta: 3/semana'), findsOneWidget);

      // Recorde pessoal do único exercício com série registrada.
      await tester.dragUntilVisible(
        find.text('Flexão na parede'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Flexão na parede'), findsOneWidget);
      expect(find.text('12 reps'), findsWidgets);

      // Volume por padrão de movimento.
      await tester.dragUntilVisible(
        find.text('push horizontal'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('push horizontal'), findsOneWidget);

      // XP da sessão aparece junto ao histórico.
      await tester.dragUntilVisible(
        find.text('Treino A'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('+40 XP'), findsOneWidget);

      // Peso/altura/IMC: 70 kg / 1.75 m² = 22.9, "Peso adequado".
      await tester.dragUntilVisible(
        find.textContaining('IMC: 22.9'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('IMC: 22.9'), findsOneWidget);
      expect(find.textContaining('Peso adequado'), findsOneWidget);
    },
  );
}
