import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assessment/data/capability_estimate_providers.dart';
import '../../assessment/domain/fundamental_pattern_anchors.dart';
import '../../assessment/presentation/other_patterns_assessment_screen.dart';
import '../../training_plan/domain/exercise_catalog.dart';
import '../../workout_session/data/workout_session_providers.dart';

const _patternTitles = <String, String>{
  'push_horizontal': 'Empurrar horizontal',
  pullHorizontalPattern: 'Puxar horizontal',
  squatPattern: 'Agachar',
  hingePosteriorChainPattern: 'Cadeia posterior',
  coreAntiExtensionPattern: 'Core (anti-extensão)',
};

/// Tela "Evolução" (SCREENS_AND_FLOWS.md §1/§2): colocação por padrão,
/// recordes informais por exercício e histórico curto de sessões.
/// Ainda não inclui atributos narrativos nem gráfico por exercício ao
/// longo do tempo (RPG_SYSTEM.md §4) — fica para uma próxima rodada.
class EvolutionScreen extends ConsumerWidget {
  const EvolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolução')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Colocação por padrão',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final pattern in _patternTitles.keys)
            _PatternPlacementTile(pattern: pattern),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OtherPatternsAssessmentScreen(),
              ),
            ),
            child: const Text('Avaliar padrões pendentes'),
          ),
          const SizedBox(height: 24),
          Text('Recordes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final bestRepsAsync = ref.watch(bestRepsByExerciseProvider);
              return bestRepsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Erro: $error'),
                data: (bestReps) {
                  if (bestReps.isEmpty) {
                    return const Text(
                      'Nenhum recorde ainda — recordes aparecem depois da '
                      'primeira série concluída sem dor.',
                    );
                  }
                  final entries = bestReps.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  return Card(
                    child: Column(
                      children: [
                        for (final entry in entries)
                          ListTile(
                            dense: true,
                            title: Text(exerciseNameForSlug(entry.key)),
                            trailing: Text('${entry.value} reps'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Histórico de sessões',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final recentAsync = ref.watch(recentCompletedSessionsProvider);
              return recentAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Erro: $error'),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const Text('Nenhuma sessão concluída ainda.');
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (final session in sessions)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(session.dayLabel),
                            subtitle: Text(_formatDate(session.completedAt!)),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}



class _PatternPlacementTile extends ConsumerWidget {
  const _PatternPlacementTile({required this.pattern});

  final String pattern;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimateAsync = ref.watch(latestCapabilityEstimateProvider(pattern));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(_patternTitles[pattern] ?? pattern),
        subtitle: estimateAsync.when(
          loading: () => const Text('Carregando...'),
          error: (_, _) => const Text('Erro'),
          data: (estimate) => Text(
            estimate == null
                ? 'Não avaliado'
                : '${estimate.levelName} (nível ${estimate.level}, '
                    'confiança ${estimate.confidence})',
          ),
        ),
      ),
    );
  }
}
