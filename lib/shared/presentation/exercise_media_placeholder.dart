import 'package:flutter/material.dart';

import 'pattern_illustration.dart';

/// Placeholder reutilizável para quando não há mídia estática de um
/// exercício (asset ausente ou erro de decodificação) — "um erro de
/// imagem nunca pode impedir o treino"
/// (`App_RPG_Exercise_Images/CLAUDE_CODE_PROMPT.md`). Reaproveita a
/// ilustração animada por família de movimento já usada no app em vez de
/// uma silhueta genérica nova.
class ExerciseMediaPlaceholder extends StatelessWidget {
  const ExerciseMediaPlaceholder({
    super.key,
    required this.pattern,
    this.size = 96,
  });

  final String pattern;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PatternIllustration(pattern: pattern, size: size);
  }
}
