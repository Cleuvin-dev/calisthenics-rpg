import 'package:flutter/material.dart';

/// Estado exibido no card de métricas (seção 4 do pedido do usuário) —
/// não é o mesmo enum de `WorkoutSessionStatus` (que é da sessão inteira,
/// não do exercício/série atual).
enum ExerciseSetStatus { waiting, active, paused, resting, completed }

extension ExerciseSetStatusLabel on ExerciseSetStatus {
  String get labelPtBr => switch (this) {
    ExerciseSetStatus.waiting => 'Aguardando',
    ExerciseSetStatus.active => 'Em execução',
    ExerciseSetStatus.paused => 'Pausado',
    ExerciseSetStatus.resting => 'Descanso',
    ExerciseSetStatus.completed => 'Concluído',
  };
}

/// Card de métricas da série atual (seção 4 do pedido do usuário): série,
/// alvo (repetições ou tempo — rótulo decidido por quem chama, já que só
/// o `WorkoutSessionItem` sabe o `doseType`), descanso e status. Usa
/// `Wrap` (não `Row` rígido) para quebrar em duas linhas em telas
/// pequenas sem cortar texto (ARCHITECTURE.md, armadilha de overflow já
/// conhecida no projeto).
class ExerciseSetMetricsCard extends StatelessWidget {
  const ExerciseSetMetricsCard({
    super.key,
    required this.currentSet,
    required this.totalSets,
    required this.metricLabel,
    required this.metricValue,
    required this.restSeconds,
    required this.status,
  });

  final int currentSet;
  final int totalSets;

  /// "REPETIÇÕES" ou "TEMPO", conforme `DoseType` do exercício atual.
  final String metricLabel;

  /// Ex.: "10" (reps) ou "45s" (tempo).
  final String metricValue;
  final int restSeconds;
  final ExerciseSetStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _Metric(label: 'SÉRIE', value: '$currentSet/$totalSets'),
            _Metric(label: metricLabel, value: metricValue),
            _Metric(label: 'DESCANSO', value: '${restSeconds}s'),
            _Metric(
              label: 'STATUS',
              value: status.labelPtBr,
              valueColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
