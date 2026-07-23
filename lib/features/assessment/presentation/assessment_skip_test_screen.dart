import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/capability_estimate_providers.dart';
import '../domain/conservative_placement.dart';
import '../domain/push_horizontal_anchor.dart';

class AssessmentSkipTestScreen extends ConsumerStatefulWidget {
  const AssessmentSkipTestScreen({super.key});

  @override
  ConsumerState<AssessmentSkipTestScreen> createState() =>
      _AssessmentSkipTestScreenState();
}

class _AssessmentSkipTestScreenState
    extends ConsumerState<AssessmentSkipTestScreen> {
  PushHorizontalAnchor? _selected;
  bool _submitting = false;

  Future<void> _submit() async {
    final anchor = _selected;
    if (anchor == null) return;

    setState(() => _submitting = true);

    final result = const ConservativePlacementCalculator().calculate(
      anchor: anchor,
      now: DateTime.now(),
    );

    await ref.read(capabilityEstimateRepositoryProvider).save(result);

    ref.invalidate(latestCapabilityEstimateProvider('push_horizontal'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colocação inicial — empurrar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Você pode pular o teste prático agora e receber uma colocação '
            'conservadora, confirmada depois. Qual variação de flexão você '
            'acredita conseguir com boa técnica hoje?',
          ),
          const SizedBox(height: 16),
          RadioGroup<PushHorizontalAnchor>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v),
            child: Column(
              children: PushHorizontalAnchor.values
                  .map(
                    (a) => RadioListTile<PushHorizontalAnchor>(
                      title: Text(a.label),
                      value: a,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_selected == null || _submitting) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Pular teste e ver colocação conservadora'),
          ),
        ],
      ),
    );
  }
}
