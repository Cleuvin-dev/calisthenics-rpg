import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_media_catalog_provider.dart';
import 'exercise_media.dart';

/// `pattern` (namespace do app, ex.: `push_horizontal`) -> `categorySlug`
/// (namespace do catálogo de 195 imagens, `exercise_media_catalog.json`)
/// — os dois nunca foram unificados (ver `PROJECT_STATUS.md` §"Integração
/// do pacote de 195 imagens reais"), então telas que mostram a escada
/// 0-7/0-5 de um padrão por nível precisam traduzir entre os dois.
const patternMediaCategorySlug = <String, String>{
  'push_horizontal': 'empurrar_horizontal',
  'pull_horizontal': 'puxar_horizontal_escapula',
  'squat': 'agachamento_unilateral',
  'hinge_posterior_chain': 'cadeia_posterior',
  'core_anti_extension': 'core_anterior_compressao',
};

/// Mostra a foto real (ou placeholder animado, se ainda carregando/sem
/// associação) de um nó específico de uma escada de padrão+nível — usado
/// nas telas de avaliação (uma imagem por opção de autorrelato) e na
/// Evolução (imagem da colocação atual), reaproveitando `ExerciseMedia`
/// depois de resolver `categorySlug:level` para um `mediaSlug` via
/// `MediaCatalogIndex.byCategoryLevel`.
class PatternLevelMedia extends ConsumerWidget {
  const PatternLevelMedia({
    super.key,
    required this.pattern,
    required this.level,
    required this.namePtBr,
    this.size = 96,
  });

  final String pattern;
  final int level;
  final String namePtBr;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseMediaCatalogProvider);
    final categorySlug = patternMediaCategorySlug[pattern];
    final mediaSlug = categorySlug == null
        ? null
        : catalogAsync.whenOrNull(
            data: (index) => index.byCategoryLevel(categorySlug, level)?.slug,
          );

    return ExerciseMedia(
      exerciseSlug: '$pattern-level-$level',
      pattern: pattern,
      namePtBr: namePtBr,
      mediaSlug: mediaSlug,
      size: size,
    );
  }
}
