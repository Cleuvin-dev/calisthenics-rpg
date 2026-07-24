import 'package:flutter/material.dart';

import '../domain/workout_session.dart';

class LoggedSet {
  const LoggedSet({required this.reps, required this.effort});

  final int reps;
  final PerceivedEffort effort;
}

/// Formulário de registro de série (FR-021/FR-022): repetições e
/// percepção — sem escala numérica de RPE, para manter o registro rápido.
class LogSetSheet extends StatefulWidget {
  const LogSetSheet({super.key, required this.setNumber});

  final int setNumber;

  @override
  State<LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends State<LogSetSheet> {
  int _reps = 8;
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
            'Série ${widget.setNumber}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _reps > 0 ? () => setState(() => _reps--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_reps reps', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                onPressed: () => setState(() => _reps++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
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
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
