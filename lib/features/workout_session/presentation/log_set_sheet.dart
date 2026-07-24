import 'package:flutter/material.dart';

import '../domain/workout_session.dart';

class LoggedSet {
  const LoggedSet({required this.reps, required this.effort});

  final int reps;
  final PerceivedEffort effort;
}

/// Formulário de registro de série por repetições
/// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §11): o alvo fica visível
/// até a confirmação, `performed_reps` começa igual ao alvo (ajuste
/// rápido com `+`/`-`), e nada é salvo antes de "Concluir série".
class LogSetSheet extends StatefulWidget {
  const LogSetSheet({
    super.key,
    required this.setNumber,
    required this.totalSets,
    required this.targetReps,
  });

  final int setNumber;
  final int totalSets;

  /// Alvo de repetições desta série. Quando não há dose estruturada
  /// (plano antigo, sem regenerar), cai para um valor padrão razoável.
  final int targetReps;

  @override
  State<LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends State<LogSetSheet> {
  late int _reps = widget.targetReps;
  PerceivedEffort? _effort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Série ${widget.setNumber} de ${widget.totalSets}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'ALVO',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            '${widget.targetReps} repetições',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _reps > 0
                    ? () => setState(() => _reps--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Diminuir repetições realizadas',
              ),
              Semantics(
                label: '$_reps repetições realmente concluídas',
                child: Text(
                  '$_reps',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _reps++),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Aumentar repetições realizadas',
              ),
            ],
          ),
          Center(
            child: Text(
              'repetições realmente concluídas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Como foi a série?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PerceivedEffort.values.map((effort) {
              return ChoiceChip(
                label: Text(effort.labelPtBr),
                selected: _effort == effort,
                onSelected: (_) => setState(() => _effort = effort),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _effort == null
                ? null
                : () => Navigator.of(context).pop(
                      LoggedSet(reps: _reps, effort: _effort!),
                    ),
            child: const Text('Concluir série'),
          ),
        ],
      ),
    );
  }
}
