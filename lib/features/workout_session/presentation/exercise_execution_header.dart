import 'package:flutter/material.dart';

/// Cabeçalho compacto da tela de execução (VISUAL_ARCHITECTURE_AND_
/// WORKOUT_PLAYER.md, seção 2.1 do pedido do usuário): botão voltar,
/// título fixo, nível (quando existe mediaSlug associado — 2 exercícios
/// do catálogo não têm, ver `exercise_catalog.dart`), nome, categoria e
/// progresso da sessão.
class ExerciseExecutionHeader extends StatelessWidget {
  const ExerciseExecutionHeader({
    super.key,
    required this.exerciseNamePtBr,
    required this.categoryLabel,
    required this.exerciseIndex,
    required this.totalExercises,
    this.level,
    this.onBack,
    this.onAbandon,
  });

  /// Nível do exercício no catálogo de mídia (0-23, numeração global do
  /// pacote de imagens — não é o nível de capacidade 0-7 por padrão).
  /// `null` quando o exercício não tem `mediaSlug` associado.
  final int? level;
  final String exerciseNamePtBr;
  final String categoryLabel;
  final int exerciseIndex;
  final int totalExercises;
  final VoidCallback? onBack;

  /// Abandonar a sessão (mesma ação que já existia na `AppBar` antiga) —
  /// mostrado como ícone à direita para não perder essa funcionalidade
  /// no reestilo do cabeçalho.
  final VoidCallback? onAbandon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = level == null
        ? categoryLabel
        : '$categoryLabel • Nível $level';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar',
            ),
            Expanded(
              child: Text(
                'Treino em andamento',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onAbandon,
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Abandonar sessão',
            ),
          ],
        ),
        if (level != null)
          Center(
            child: Chip(
              avatar: Icon(
                Icons.shield_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              label: Text('NÍVEL $level'),
              backgroundColor: Colors.transparent,
              side: BorderSide(color: colorScheme.primary),
            ),
          ),
        const SizedBox(height: 12),
        Text(exerciseNamePtBr, style: textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(height: 2),
        Text(
          'Exercício $exerciseIndex/$totalExercises',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
