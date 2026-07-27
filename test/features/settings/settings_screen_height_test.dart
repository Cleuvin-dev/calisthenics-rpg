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
    'usuário define a altura e o valor persiste sem perder outras preferências',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.text('Não definida — necessária para calcular o IMC'),
        findsOneWidget,
      );

      await tester.tap(find.text('Altura'));
      await tester.pumpAndSettle();

      final saveButtonFinder = find.widgetWithText(FilledButton, 'Salvar');
      expect(tester.widget<FilledButton>(saveButtonFinder).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '175');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(saveButtonFinder).onPressed,
        isNotNull,
      );

      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('175 cm'), findsOneWidget);
      // A meta de dias por semana original não deve ter sido perdida ao
      // gravar uma nova linha de preferências só com a altura mudando.
      expect(find.text('3 dias por semana'), findsOneWidget);
    },
  );

  testWidgets('rejeita altura fora da faixa plausível', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Altura'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '999');
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar'))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('Informe um valor entre'), findsOneWidget);
  });
}
