import 'package:flutter/material.dart';

import 'pattern_illustration.dart';

/// Resolve a mídia de um exercício: imagem local se existir, senão a
/// ilustração animada por padrão como placeholder
/// (EXERCISE_MEDIA_GUIDE.md §11 "resolveMedia" simplificado para o que
/// esta entrega tem: só uma posição estática por exercício, sem
/// início/fim/demo separados). `Image.asset` com `errorBuilder` cobre
/// `missing`/`load_error` sem travar a sessão (§13, §22) — não é preciso
/// manter uma lista manual de "quais exercícios têm foto".
class ExerciseMedia extends StatelessWidget {
  const ExerciseMedia({
    super.key,
    required this.exerciseSlug,
    required this.pattern,
    required this.namePtBr,
    this.size = 96,
  });

  final String exerciseSlug;
  final String pattern;
  final String namePtBr;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: 'Demonstração de $namePtBr',
        image: true,
        child: Image.asset(
          'assets/images/exercises/$exerciseSlug/v1/start.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              PatternIllustration(pattern: pattern, size: size),
        ),
      ),
    );
  }
}
