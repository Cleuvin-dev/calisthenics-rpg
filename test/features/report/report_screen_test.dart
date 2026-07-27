import 'package:calisthenics_rpg/app/theme.dart';
import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/report/presentation/report_screen.dart';
import 'package:calisthenics_rpg/features/report/data/report_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('relatório vazio explica como gerar o primeiro registro', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(
      (await ReportRepository(db).load(ReportPeriod.sevenDays)).sessions,
      isEmpty,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildCalisthenicsRpgTheme(),
          home: const ReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum treino concluído'), findsOneWidget);
    expect(find.textContaining('Conclua sua primeira sessão'), findsOneWidget);
  });
}
