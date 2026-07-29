import 'package:calisthenics_rpg/shared/presentation/exercise_fullscreen_viewer.dart';
import 'package:calisthenics_rpg/shared/presentation/exercise_image_card.dart';
import 'package:calisthenics_rpg/shared/presentation/exercise_media_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// ExerciseImageCard (imagem principal da tela de execução) e
/// ExerciseFullscreenViewer (zoom): tocar abre a visualização ampliada
/// via `Hero`, fechar não deve perder nenhum estado do que está por
/// baixo (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md, seção de zoom do
/// pedido do usuário).
void main() {
  Widget wrap(Widget home) {
    return ProviderScope(child: MaterialApp(home: home));
  }

  testWidgets('cai para o placeholder quando não há imagem para o slug', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: ExerciseImageCard(
            exerciseSlug: 'exercicio_sem_foto_alguma',
            pattern: 'push_horizontal',
            namePtBr: 'Exercício sem foto',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ExerciseMediaPlaceholder), findsOneWidget);
    expect(find.text('Toque para ampliar'), findsOneWidget);
  });

  testWidgets(
    'toque abre o visualizador em tela cheia e fechar preserva o estado '
    'do widget pai (ex.: um cronômetro rodando por baixo)',
    (tester) async {
      var counterBuilds = 0;
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) {
                    counterBuilds++;
                    return const Text('cronômetro-fake');
                  },
                ),
                const ExerciseImageCard(
                  exerciseSlug: 'exercicio_sem_foto_alguma',
                  pattern: 'push_horizontal',
                  namePtBr: 'Exercício sem foto',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final buildsBeforeOpen = counterBuilds;

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseFullscreenViewer), findsOneWidget);

      final closeButton = find.bySemanticsLabel('Fechar visualização ampliada');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseFullscreenViewer), findsNothing);
      expect(find.text('cronômetro-fake'), findsOneWidget);
      // O widget por baixo nunca foi reconstruído do zero (empurrar uma
      // rota por cima não destrói a árvore que ficou embaixo).
      expect(counterBuilds, buildsBeforeOpen);
    },
  );

  testWidgets('duplo toque no visualizador alterna o zoom sem erro', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ExerciseFullscreenViewer(
          assetPath: 'assets/images/does_not_exist.png',
          namePtBr: 'Exercício sem foto',
          pattern: 'push_horizontal',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(InteractiveViewer), findsOneWidget);

    final center = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    // Não travou nem lançou exceção ao alternar zoom repetidamente.
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
