import 'package:calisthenics_rpg/shared/presentation/exercise_media.dart';
import 'package:calisthenics_rpg/shared/presentation/pattern_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// EXERCISE_MEDIA_GUIDE.md §13/§22: quando não há imagem local para o
/// slug, a tela não pode travar nem ficar em branco — cai para a
/// ilustração animada (mesmo placeholder usado antes desta entrega).
void main() {
  testWidgets(
    'cai para PatternIllustration quando não há imagem local para o slug',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseMedia(
            exerciseSlug: 'exercicio_sem_foto_alguma',
            pattern: 'push_horizontal',
            namePtBr: 'Exercício sem foto',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(PatternIllustration), findsOneWidget);
    },
  );

  testWidgets('mostra o rótulo semântico com o nome do exercício',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExerciseMedia(
          exerciseSlug: 'exercicio_sem_foto_alguma',
          pattern: 'push_horizontal',
          namePtBr: 'Exercício sem foto',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.bySemanticsLabel('Demonstração de Exercício sem foto'),
      findsOneWidget,
    );
  });
}
