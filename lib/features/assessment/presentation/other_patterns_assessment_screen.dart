import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/capability_estimate_providers.dart';
import '../domain/conservative_placement.dart';
import '../domain/fundamental_pattern_anchors.dart';
import '../domain/movement_anchor.dart';

/// Avaliação conservadora dos padrões fundamentais além de
/// push_horizontal (que já é obrigatório antes do primeiro plano —
/// ver `AppFlowGate`). Esta tela é opcional e acessível a qualquer
/// momento pela Jornada/Evolução: cada padrão pode ficar "não avaliado"
/// indefinidamente sem bloquear nada, só limita o quanto o motor de
/// treino/progressão pode individualizar por enquanto.
class OtherPatternsAssessmentScreen extends ConsumerStatefulWidget {
  const OtherPatternsAssessmentScreen({super.key});

  @override
  ConsumerState<OtherPatternsAssessmentScreen> createState() =>
      _OtherPatternsAssessmentScreenState();
}

class _OtherPatternsAssessmentScreenState
    extends ConsumerState<OtherPatternsAssessmentScreen> {
  final Map<String, MovementAnchor?> _selections = {};
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);

    const calculator = ConservativePlacementCalculator();
    final repository = ref.read(capabilityEstimateRepositoryProvider);
    final now = DateTime.now();

    for (final ladder in fundamentalPatternLadders) {
      final anchor = _selections[ladder.pattern];
      if (anchor == null) continue; // deixa "não avaliado"

      final result = calculator.calculateForPattern(
        pattern: ladder.pattern,
        anchor: anchor,
        levelNames: ladder.levelNames,
        now: now,
      );
      await repository.save(result);
      ref.invalidate(latestCapabilityEstimateProvider(ladder.pattern));
    }

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selections.values.any((v) => v != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Avaliar outros padrões')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Como em empurrar horizontal, você pode pular o teste prático '
            'e receber uma colocação conservadora por padrão. Deixe em '
            'branco o que não quiser responder agora — não trava nada.',
          ),
          const SizedBox(height: 16),
          for (final ladder in fundamentalPatternLadders)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ladder.titlePtBr,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text('Qual variação você acredita conseguir com '
                          'boa técnica hoje?'),
                      RadioGroup<MovementAnchor?>(
                        groupValue: _selections[ladder.pattern],
                        onChanged: (v) =>
                            setState(() => _selections[ladder.pattern] = v),
                        child: Column(
                          children: ladder.anchors
                              .map(
                                (a) => RadioListTile<MovementAnchor?>(
                                  title: Text(a.label),
                                  value: a,
                                  dense: true,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          FilledButton(
            onPressed: (_submitting || !hasSelection) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar avaliação'),
          ),
        ],
      ),
    );
  }
}
