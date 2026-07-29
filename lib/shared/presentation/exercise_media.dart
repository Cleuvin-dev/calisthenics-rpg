import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_media_catalog_provider.dart';
import '../domain/exercise_media_catalog.dart';
import 'exercise_media_placeholder.dart';

/// Resolve o `asset_path` de um exercício, em ordem
/// (EXERCISE_MEDIA_GUIDE.md §11 "resolveMedia" simplificado,
/// `App_RPG_Exercise_Images/CLAUDE_CODE_PROMPT.md`) — compartilhado entre
/// [ExerciseMedia] (miniaturas de tamanho fixo) e `ExerciseImageCard`
/// (imagem principal da tela de execução), para as duas nunca divergirem
/// sobre qual arquivo mostrar:
///
/// 1. Se [mediaSlug] foi informado e existe no catálogo de 195 imagens
///    (`exercise_media_catalog.json`, associado por slug — nunca por
///    nome exibido), usa o `asset_path` de lá;
/// 2. senão, tenta a convenção antiga desta entrega
///    (`assets/images/exercises/<exerciseSlug>/v1/start.png`, os 3
///    exercícios da história vertical de reps/duração);
/// 3. senão, retorna `null` — quem chamar decide o placeholder.
String resolveExerciseAssetPath({
  required String exerciseSlug,
  required String? mediaSlug,
  required MediaCatalogIndex? catalog,
}) {
  final fromCatalog = mediaSlug == null
      ? null
      : catalog?.bySlug(mediaSlug)?.assetPath;
  return fromCatalog ?? 'assets/images/exercises/$exerciseSlug/v1/start.png';
}

class ExerciseMedia extends ConsumerWidget {
  const ExerciseMedia({
    super.key,
    required this.exerciseSlug,
    required this.pattern,
    required this.namePtBr,
    this.mediaSlug,
    this.size = 96,
  });

  final String exerciseSlug;
  final String pattern;
  final String namePtBr;

  /// Slug no catálogo de mídia estática (`exercise_media_catalog.json`),
  /// quando `CatalogExercise.mediaSlug` associou este exercício a uma das
  /// 195 imagens do pacote. `null` quando ainda não há associação
  /// confiável (ver `exercise_catalog.dart`).
  final String? mediaSlug;

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseMediaCatalogProvider);
    final assetPath = resolveExerciseAssetPath(
      exerciseSlug: exerciseSlug,
      mediaSlug: mediaSlug,
      catalog: catalogAsync.value,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: 'Demonstração de $namePtBr',
        image: true,
        child: Image.asset(
          assetPath,
          key: ValueKey(assetPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              ExerciseMediaPlaceholder(pattern: pattern, size: size),
        ),
      ),
    );
  }
}
