import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_providers.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_repository.dart';
import 'package:calisthenics_rpg/features/settings/data/storage_usage_providers.dart';
import 'package:calisthenics_rpg/features/settings/presentation/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemorySettingsRepository extends SettingsRepository {
  UserSettings _current = const UserSettings();

  @override
  Future<UserSettings> load() async => _current;

  @override
  Future<void> save(UserSettings settings) async {
    _current = settings;
  }
}

void main() {
  late AppDatabase db;
  final preferences = TrainingPreferenceRecord(
    id: 1,
    daysPerWeek: 3,
    minutesPerSession: 30,
    location: 'home',
    equipmentJson: '[]',
    updatedAt: DateTime(2026, 7, 27),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Widget wrap() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(
          _InMemorySettingsRepository(),
        ),
        storageUsageProvider.overrideWith((ref) async => 0),
      ],
      child: MaterialApp(home: SettingsScreen(preferences: preferences)),
    );
  }

  testWidgets(
    'objetivo padrão é força muscular e o usuário pode trocar pra perder '
    'gordura',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Força muscular'), findsOneWidget);

      await tester.tap(find.text('Objetivo de treino'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Perder gordura'));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Perder gordura'), findsOneWidget);
      expect(
        find.text(
          'Objetivo salvo. Toque em "Gerar novamente" no plano da '
          'semana para aplicar a nova dose.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('editar dias de treino não apaga altura nem objetivo já salvos '
      '(regressão)', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Define altura.
    await tester.tap(find.text('Altura'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '175');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('175 cm'), findsOneWidget);

    // Define objetivo.
    await tester.tap(find.text('Objetivo de treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Condicionamento físico'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Condicionamento físico'), findsOneWidget);

    // Edita dias de treino — antes desta correção, isto zerava a
    // altura salva porque `_editWeekdays` reconstruía as preferências
    // sem repassar `heightCm`.
    await tester.tap(find.text('Dias de treino na semana'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Seg'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Seg'), findsOneWidget);
    expect(find.text('175 cm'), findsOneWidget);
    expect(find.text('Condicionamento físico'), findsOneWidget);
  });
}
