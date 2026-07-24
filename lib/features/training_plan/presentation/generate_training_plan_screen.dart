import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../onboarding/data/training_preferences_repository.dart';
import '../data/training_plan_providers.dart';
import '../domain/weekly_plan_generator.dart';

/// Tela de transição entre a colocação e o plano semanal: o usuário aciona
/// a geração explicitamente (o motor não decide nada "em silêncio",
/// TRAINING_ENGINE.md §10).
class GenerateTrainingPlanScreen extends ConsumerStatefulWidget {
  const GenerateTrainingPlanScreen({
    super.key,
    required this.preferences,
    required this.placement,
  });

  final TrainingPreferenceRecord preferences;
  final CapabilityEstimateRecord placement;

  @override
  ConsumerState<GenerateTrainingPlanScreen> createState() =>
      _GenerateTrainingPlanScreenState();
}

class _GenerateTrainingPlanScreenState
    extends ConsumerState<GenerateTrainingPlanScreen> {
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);

    const generator = WeeklyPlanGenerator();
    final plan = generator.generate(
      preferences: widget.preferences.toDomain(),
      pushHorizontalCapabilityLevel: widget.placement.level,
      now: DateTime.now(),
    );

    await ref.read(trainingPlanRepositoryProvider).save(plan);

    ref.invalidate(latestTrainingPlanProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seu plano de treino')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pronto para gerar sua primeira semana',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Vamos montar ${widget.preferences.daysPerWeek} sessões de '
              '${widget.preferences.minutesPerSession} minutos, a partir '
              'da sua colocação inicial (${widget.placement.levelName}).',
            ),
            const SizedBox(height: 8),
            const Text(
              'O plano usa regras conservadoras e um catálogo mínimo de '
              'exercícios — ainda não é o catálogo completo revisado por '
              'profissional.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _generating ? null : _generate,
              child: _generating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gerar plano da semana'),
            ),
          ],
        ),
      ),
    );
  }
}
