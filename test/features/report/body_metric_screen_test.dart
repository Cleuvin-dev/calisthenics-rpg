import 'package:calisthenics_rpg/app/theme.dart';
import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/report/presentation/body_metric_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Widget wrap() {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildCalisthenicsRpgTheme(),
        home: const BodyMetricScreen(),
      ),
    );
  }

  testWidgets('estado vazio explica como registrar o primeiro peso', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Nenhum peso registrado'), findsOneWidget);
  });

  testWidgets('não deixa salvar peso implausível e habilita com valor válido', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Adicionar peso'),
    );
    await tester.pumpAndSettle();

    final weightField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    final saveButton = find.widgetWithText(FilledButton, 'Salvar');

    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.enterText(weightField, '9999');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    expect(find.textContaining('Informe um valor entre'), findsOneWidget);

    await tester.enterText(weightField, '78.5');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('78.5 kg'), findsWidgets);
  });

  testWidgets('editar um registro atualiza o peso mostrado', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Adicionar peso'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '80',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('80 kg'), findsWidgets);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '82',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('82 kg'), findsWidgets);
    expect(find.textContaining('80 kg'), findsNothing);
  });

  testWidgets('excluir pede confirmação; cancelar mantém, confirmar remove', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Adicionar peso'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '80',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Excluir registro de peso?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('80 kg'), findsWidgets);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum peso registrado'), findsOneWidget);
  });
}
