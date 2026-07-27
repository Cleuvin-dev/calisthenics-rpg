import 'dart:async';

import 'package:calisthenics_rpg/app/app_reset.dart';
import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/core/database/app_database_provider.dart';
import 'package:calisthenics_rpg/features/settings/data/progress_reset_providers.dart';
import 'package:calisthenics_rpg/features/settings/data/progress_reset_service.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_providers.dart';
import 'package:calisthenics_rpg/features/settings/data/settings_repository.dart';
import 'package:calisthenics_rpg/features/settings/data/storage_usage_providers.dart';
import 'package:calisthenics_rpg/features/settings/presentation/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Conta chamadas a [reset] para provar que o toque duplo durante a operação
/// não dispara uma segunda transação, sem depender de inspecionar o banco.
class _TrackedResetService extends ProgressResetService {
  _TrackedResetService(
    super.db, {
    required this.onCall,
    super.beforeCommitForTesting,
  });

  final VoidCallback onCall;

  @override
  Future<ProgressResetResult> reset() {
    onCall();
    return super.reset();
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

  testWidgets(
    'reset exige ciência e texto exato, bloqueia toque duplo e volta ao início',
    (tester) async {
      final gate = Completer<void>();
      var resetCallCount = 0;
      final navigatorKey = GlobalKey<NavigatorState>();
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            userSettingsProvider.overrideWith(
              (ref) async => const UserSettings(),
            ),
            storageUsageProvider.overrideWith((ref) async => 0),
            progressResetServiceProvider.overrideWithValue(
              _TrackedResetService(
                db,
                onCall: () => resetCallCount++,
                beforeCommitForTesting: () => gate.future,
              ),
            ),
          ],
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                navigatorKey: navigatorKey,
                home: const Scaffold(body: Center(child: Text('Início'))),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(preferences: preferences),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Reiniciar progresso e métricas'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reiniciar progresso e métricas'));
      await tester.pumpAndSettle();

      final continueButtonFinder = find.widgetWithText(
        FilledButton,
        'Apagar progresso',
      );
      expect(
        tester.widget<FilledButton>(continueButtonFinder).onPressed,
        isNull,
        reason: 'sem ciência marcada e sem o texto, deve continuar bloqueado',
      );

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'errado');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(continueButtonFinder).onPressed,
        isNull,
        reason: 'texto incorreto não pode liberar o botão destrutivo',
      );

      await tester.enterText(find.byType(TextField), 'REINICIAR');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(continueButtonFinder).onPressed,
        isNotNull,
        reason: 'ciência marcada + texto exato deve liberar o botão',
      );

      await tester.tap(continueButtonFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Confirmação final'),
        findsOneWidget,
        reason: 'confirmação final deve ser uma etapa separada',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar e apagar'));
      await tester.pump();

      expect(resetCallCount, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(continueButtonFinder).onPressed,
        isNull,
        reason: 'botão deve ficar desabilitado enquanto o reset está em voo',
      );

      await tester.tap(continueButtonFinder, warnIfMissed: false);
      await tester.pump();
      expect(
        resetCallCount,
        1,
        reason: 'toque repetido durante o reset não pode disparar outro reset',
      );

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Início'), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(container.read(appResetEpochProvider), 1);
    },
  );
}
