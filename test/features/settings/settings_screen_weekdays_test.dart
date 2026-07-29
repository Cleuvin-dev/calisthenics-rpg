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

/// Backend em memória para `SettingsRepository` nos testes: usar o
/// arquivo real de disco travaria `pumpAndSettle`/`pump` dentro da zona
/// `FakeAsync` de `testWidgets` (mesma causa do hang corrigido em
/// main_shell_test.dart), e `userSettingsProvider.overrideWith` fixo não
/// refletiria o que `save()` grava. Isto permite o ciclo real
/// salvar → invalidar → reler pela mesma cadeia de providers de produção.
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
    'usuário formaliza dias de treino na semana e a meta atualiza na tela',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Dias de treino na semana'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ainda não definido'), findsOneWidget);
      expect(find.text('3 dias por semana'), findsOneWidget);

      await tester.tap(find.text('Dias de treino na semana'));
      await tester.pumpAndSettle();

      final saveButtonFinder = find.widgetWithText(FilledButton, 'Salvar');
      expect(
        tester.widget<FilledButton>(saveButtonFinder).onPressed,
        isNull,
        reason: 'sem nenhum dia marcado, não deve deixar salvar',
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Seg'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Qua'));
      await tester.pump();

      expect(
        tester.widget<FilledButton>(saveButtonFinder).onPressed,
        isNotNull,
      );

      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Seg, Qua'), findsOneWidget);
      expect(
        find.text('2 dias por semana'),
        findsOneWidget,
        reason:
            'a quantidade formalizada deve seguir os dias escolhidos, não '
            'ficar dessincronizada',
      );
    },
  );

  testWidgets(
    'tocar em "X dias por semana" abre o mesmo editor de dias da semana',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('3 dias por semana'), findsOneWidget);

      await tester.tap(find.text('3 dias por semana'));
      await tester.pumpAndSettle();

      expect(find.text('Dias de treino na semana'), findsWidgets);
      expect(find.byType(FilterChip), findsNWidgets(7));
    },
  );

  testWidgets('usuário ajusta a contagem regressiva e o valor persiste', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Contagem regressiva'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('3s'), findsOneWidget);

    await tester.tap(find.text('Contagem regressiva'));
    await tester.pumpAndSettle();

    final dialogSlider = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Slider),
    );
    tester.widget<Slider>(dialogSlider).onChanged!(8);
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('8s'), findsOneWidget);
  });

  testWidgets(
    '"Refazer avaliação física" deixa escolher push_horizontal e salva '
    'uma nova colocação, mostrando o lembrete de regenerar o plano',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Refazer avaliação física'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Refazer avaliação física'));
      await tester.pumpAndSettle();

      expect(find.text('Empurrar horizontal'), findsOneWidget);
      expect(find.text('Outros padrões'), findsOneWidget);

      await tester.tap(find.text('Empurrar horizontal'));
      await tester.pumpAndSettle();

      expect(find.text('Colocação inicial — empurrar'), findsOneWidget);

      await tester.tap(find.text('Não quero responder agora'));
      await tester.pumpAndSettle();

      expect(find.text('Colocação inicial — empurrar'), findsNothing);
      expect(
        find.textContaining('Colocação salva'),
        findsOneWidget,
        reason: 'lembrete só aparece depois de uma colocação real ser salva',
      );
    },
  );

  testWidgets(
    'voltar do seletor de "Refazer avaliação física" sem escolher nada '
    'não mostra o lembrete',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Refazer avaliação física'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Refazer avaliação física'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(20, 20)); // fora do bottom sheet
      await tester.pumpAndSettle();

      expect(find.textContaining('Colocação salva'), findsNothing);
    },
  );
}
