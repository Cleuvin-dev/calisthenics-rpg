import 'package:calisthenics_rpg/shared/data/exercise_media_catalog_provider.dart';
import 'package:calisthenics_rpg/shared/domain/exercise_media_catalog.dart';
import 'package:calisthenics_rpg/shared/presentation/exercise_media_placeholder.dart';
import 'package:calisthenics_rpg/shared/presentation/pattern_level_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// `PatternLevelMedia` traduz `pattern` (namespace do app) + `level` para
/// o `mediaSlug` do catálogo de 195 imagens via `categorySlug:level` —
/// usado nas telas de avaliação (uma imagem por opção de autorrelato) e
/// na Evolução (imagem da colocação atual).
void main() {
  const entry = MediaCatalogEntry(
    slug: 'agachamento_livre',
    name: 'Agachamento livre',
    category: 'Agachamento e unilateral',
    categorySlug: 'agachamento_unilateral',
    level: 5,
    mediaKey: 'agachamento_livre_v1',
    assetPath:
        'assets/images/exercises/agachamento_unilateral/agachamento_livre.png',
    mediaType: 'static_png',
    visualReviewStatus: VisualReviewStatus.requiresProfessionalReview,
  );

  testWidgets('resolve a imagem certa via categorySlug:level do padrão', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseMediaCatalogProvider.overrideWith(
            (ref) => MediaCatalogIndex([entry]),
          ),
        ],
        child: const MaterialApp(
          home: PatternLevelMedia(
            pattern: 'squat',
            level: 5,
            namePtBr: 'Agachamento livre',
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    final assetImage = image.image as AssetImage;
    expect(
      assetImage.assetName,
      'assets/images/exercises/agachamento_unilateral/agachamento_livre.png',
    );
  });

  testWidgets('cai para o placeholder estático quando o nível não tem imagem '
      'associada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseMediaCatalogProvider.overrideWith(
            (ref) => MediaCatalogIndex([entry]),
          ),
        ],
        child: const MaterialApp(
          home: PatternLevelMedia(
            pattern: 'squat',
            // Nível sem entrada correspondente na lista de teste acima.
            level: 0,
            namePtBr: 'Sentar e levantar de banco alto',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ExerciseMediaPlaceholder), findsOneWidget);
  });
}
