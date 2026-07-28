import 'package:calisthenics_rpg/shared/data/exercise_media_catalog_provider.dart';
import 'package:calisthenics_rpg/shared/domain/exercise_media_catalog.dart';
import 'package:calisthenics_rpg/shared/presentation/exercise_media.dart';
import 'package:calisthenics_rpg/shared/presentation/exercise_media_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// EXERCISE_MEDIA_GUIDE.md §13/§22: quando não há imagem local para o
/// slug, a tela não pode travar nem ficar em branco — cai para o
/// placeholder estático (ícone fixo, sem animação).
void main() {
  Widget wrap(Widget child) {
    return ProviderScope(child: MaterialApp(home: child));
  }

  testWidgets(
    'cai para o placeholder estático quando não há imagem local para o slug',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const ExerciseMedia(
            exerciseSlug: 'exercicio_sem_foto_alguma',
            pattern: 'push_horizontal',
            namePtBr: 'Exercício sem foto',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ExerciseMediaPlaceholder), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    },
  );

  testWidgets('mostra o rótulo semântico com o nome do exercício', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ExerciseMedia(
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

  testWidgets('usa a imagem do catálogo de mídia quando mediaSlug é fornecido e '
      'existe', (tester) async {
    // Override em vez de carregar o JSON real via `rootBundle`: essa
    // leitura passa por canal de plataforma, que só é entregue com
    // tempo de parede real dentro de `testWidgets` — mesmo padrão já
    // usado para `appDatabaseProvider` nos outros testes de widget.
    const entry = MediaCatalogEntry(
      slug: 'flexao_inclinada_media',
      name: 'Flexão inclinada média',
      category: 'Empurrar horizontal',
      categorySlug: 'empurrar_horizontal',
      level: 3,
      mediaKey: 'flexao_inclinada_media_v1',
      assetPath:
          'assets/images/exercises/empurrar_horizontal/flexao_inclinada_media.png',
      mediaType: 'static_png',
      visualReviewStatus: VisualReviewStatus.requiresProfessionalReview,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseMediaCatalogProvider.overrideWith(
            (ref) => MediaCatalogIndex([entry]),
          ),
        ],
        child: const MaterialApp(
          home: ExerciseMedia(
            exerciseSlug: 'push_up_incline',
            pattern: 'push_horizontal',
            namePtBr: 'Flexão inclinada',
            mediaSlug: 'flexao_inclinada_media',
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    final assetImage = image.image as AssetImage;
    expect(
      assetImage.assetName,
      'assets/images/exercises/empurrar_horizontal/flexao_inclinada_media.png',
    );
    // "usar BoxFit.contain; preservar a proporção; não recortar o
    // corpo ou o equipamento" (README do pacote de imagens) — vale
    // tanto para a imagem real quanto para o placeholder, então checar
    // aqui cobre a regra em geral.
    expect(image.fit, BoxFit.contain);
  });
}
