import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/level_up_celebration.dart';
import '../../assessment/domain/fundamental_pattern_anchors.dart';
import '../../progression/domain/mastery_evaluator.dart';
import '../data/workout_session_providers.dart';
import '../domain/workout_session.dart';

/// Rótulo amigável de um padrão de movimento, reaproveitando
/// `FundamentalPatternLadder.titlePtBr` para os 4 padrões opcionais e um
/// rótulo próprio para `push_horizontal` (que não está nessa lista por
/// ter sua própria escada dedicada, `push_horizontal_anchor.dart`).
String _patternLabelPtBr(String pattern) {
  if (pattern == 'push_horizontal') return 'Empurrar horizontal';
  for (final ladder in fundamentalPatternLadders) {
    if (ladder.pattern == pattern) return ladder.titlePtBr;
  }
  return pattern;
}

/// Resumo ao final da sessão (SCREENS_AND_FLOWS.md §2 — "Treino: resumo").
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.workoutSessionId,
    required this.dayLabel,
    this.masteryResults = const {},
    this.xpAwarded = 0,
    this.leveledUp = false,
    this.newLevel,
  });

  final int workoutSessionId;
  final String dayLabel;

  /// Resultados da avaliação de domínio rodada ao concluir a sessão, por
  /// padrão (ver `WorkoutPlayerScreen._completeSession`) — só inclui
  /// padrões com regra avaliada nesta sessão, não os 5 sempre.
  final Map<String, MasteryEvaluationResult> masteryResults;

  /// XP efetivamente concedido ao concluir a sessão (RPG_SYSTEM.md §2),
  /// já recortado por tetos anti-abuso quando aplicável.
  final int xpAwarded;
  final bool leveledUp;
  final int? newLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(setLogsForSessionProvider(workoutSessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sessão concluída')),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (logs) {
          final painCount = logs
              .where((l) => l.perceivedEffort == PerceivedEffort.pain.name)
              .length;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayLabel, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${logs.length} séries registradas'),
                if (xpAwarded > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+$xpAwarded XP',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (leveledUp) ...[
                  const SizedBox(height: 8),
                  Center(child: LevelUpCelebration(level: newLevel ?? 0)),
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Você alcançou o nível $newLevel! A próxima '
                        'habilidade será liberada quando os requisitos '
                        'físicos forem confirmados.',
                      ),
                    ),
                  ),
                ],
                if (painCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$painCount série(s) com dor — não contam como evidência '
                    'de domínio (PROGRESSION_RULES.md §8).',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                for (final entry in masteryResults.entries) ...[
                  if (entry.value.promoted) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Domínio confirmado! Sua colocação em '
                          '${_patternLabelPtBr(entry.key)} avançou de '
                          'nível. Gere um novo plano para refletir a nova '
                          'variação.',
                        ),
                      ),
                    ),
                  ] else if (entry.value.hasPartialProgress) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${_patternLabelPtBr(entry.key)}: você atingiu o '
                          'alvo em ${entry.value.qualifyingConfirmations} de '
                          '${entry.value.confirmationsRequired} sessões '
                          'necessárias. Repita em outra sessão com a mesma '
                          'técnica para confirmar o domínio.',
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                const Text(
                  'Treino salvo neste aparelho.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Voltar ao plano'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
