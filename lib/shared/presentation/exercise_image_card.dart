import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_media_catalog_provider.dart';
import 'exercise_fullscreen_viewer.dart';
import 'exercise_media.dart';
import 'exercise_media_placeholder.dart';

/// Imagem principal da tela de execução de exercício — diferente de
/// [ExerciseMedia] (miniatura de tamanho fixo, usada em listas), esta
/// ocupa a largura toda e ~60% da altura do viewport, com
/// `BoxFit.contain` para nunca cortar o conteúdo já desenhado na própria
/// arte (nome, músculos, instruções). Toque abre
/// [ExerciseFullscreenViewer] com transição `Hero`.
class ExerciseImageCard extends ConsumerWidget {
  const ExerciseImageCard({
    super.key,
    required this.exerciseSlug,
    required this.pattern,
    required this.namePtBr,
    this.mediaSlug,
    this.heightFraction = 0.6,
  });

  final String exerciseSlug;
  final String pattern;
  final String namePtBr;
  final String? mediaSlug;

  /// Fração da altura do viewport ocupada pelo card (seção 2.2 do
  /// pedido: "aproximadamente 60% da altura visível inicial").
  final double heightFraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseMediaCatalogProvider);
    final assetPath = resolveExerciseAssetPath(
      exerciseSlug: exerciseSlug,
      mediaSlug: mediaSlug,
      catalog: catalogAsync.value,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final height = (viewportHeight * heightFraction).clamp(220.0, 520.0);

    void openFullscreen() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExerciseFullscreenViewer(
            assetPath: assetPath,
            namePtBr: namePtBr,
            pattern: pattern,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: openFullscreen,
          child: Ink(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Hero(
                      tag: assetPath,
                      child: Semantics(
                        label: 'Demonstração de $namePtBr',
                        image: true,
                        child: Image.asset(
                          assetPath,
                          key: ValueKey(assetPath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              ExerciseMediaPlaceholder(
                                pattern: pattern,
                                size: height * 0.6,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_full,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Toque para ampliar',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
