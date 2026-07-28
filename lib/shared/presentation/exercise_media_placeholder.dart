import 'package:flutter/material.dart';

/// Placeholder estático para quando não há uma das 195 imagens reais de
/// um exercício (asset ausente, sem `mediaSlug` associado, ou erro de
/// decodificação) — "um erro de imagem nunca pode impedir o treino"
/// (`App_RPG_Exercise_Images/CLAUDE_CODE_PROMPT.md`). Ícone fixo, sem
/// animação: a pedido do usuário, a ilustração animada por família de
/// movimento que existia antes desta entrega foi removida — só as fotos
/// reais entregues ficam visíveis no app.
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
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.fitness_center,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
