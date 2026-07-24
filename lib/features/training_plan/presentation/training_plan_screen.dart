import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/presentation/pattern_illustration.dart';
import '../../assessment/presentation/placement_result_screen.dart';
import '../../onboarding/data/training_preferences_repository.dart';
import '../../rpg/presentation/xp_level_badge.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../../workout_session/domain/workout_session.dart';
import '../../workout_session/presentation/workout_player_screen.dart';
import '../data/training_plan_providers.dart';
import '../data/training_plan_repository.dart';
import '../domain/training_plan.dart';
import '../domain/weekly_plan_generator.dart';

/// Exibe a semana gerada pelo motor de treino, com o motivo de cada item
/// (TRAINING_ENGINE.md §11 — explicabilidade).
class TrainingPlanScreen extends ConsumerStatefulWidget {
  const TrainingPlanScreen({
    super.key,
    required this.record,
    required this.preferences,
    required this.placement,
  });

  final TrainingPlanRecord record;
  final TrainingPreferenceRecord preferences;
  final CapabilityEstimateRecord placement;

  @override
  ConsumerState<TrainingPlanScreen> createState() =>
      _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends ConsumerState<TrainingPlanScreen> {
  bool _regenerating = false;

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);

    const generator = WeeklyPlanGenerator();
    final plan = generator.generate(
      preferences: widget.preferences.toDomain(),
      pushHorizontalCapabilityLevel: widget.placement.level,
      now: DateTime.now(),
    );

    await ref.read(trainingPlanRepositoryProvider).save(plan);

    ref.invalidate(latestTrainingPlanProvider);
  }

  Future<void> _openSession(int workoutSessionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutPlayerScreen(
          workoutSessionId: workoutSessionId,
          pushHorizontalPlacement: widget.placement,
        ),
      ),
    );
    ref.invalidate(latestActiveWorkoutSessionProvider);
  }

  Future<void> _startSession(PlannedSession session, WeeklyPlan plan) async {
    final repository = ref.read(workoutSessionRepositoryProvider);
    final active = await repository.latestActive();

    if (active != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Finalize ou pause a sessão em andamento antes '
                'de iniciar outra.'),
          ),
        );
      }
      await _openSession(active.id);
      return;
    }

    final id = await repository.startSession(
      dayLabel: session.dayLabel,
      items: session.items
          .map((i) => WorkoutSessionItem(
                pattern: i.pattern,
                exerciseSlug: i.exerciseSlug,
                namePtBr: i.namePtBr,
                setsRepsGuidance: i.setsRepsGuidance,
              ))
          .toList(),
      planRuleVersion: plan.ruleVersion,
      catalogVersion: plan.catalogVersion,
      now: DateTime.now(),
    );
    ref.invalidate(latestActiveWorkoutSessionProvider);
    await _openSession(id);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.record.toDomain();
    final activeSessionAsync = ref.watch(latestActiveWorkoutSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plano da semana')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const XpLevelBadge(),
          const SizedBox(height: 12),
          activeSessionAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (active) {
              if (active == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    title: Text('Sessão em andamento: ${active.dayLabel}'),
                    subtitle: Text(
                      active.status == WorkoutSessionStatus.paused.name
                          ? 'Pausada'
                          : 'Em andamento',
                    ),
                    trailing: FilledButton(
                      onPressed: () => _openSession(active.id),
                      child: const Text('Continuar'),
                    ),
                  ),
                ),
              );
            },
          ),
          if (plan.frequencyDowngradeReason != null) ...[
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(plan.frequencyDowngradeReason!),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            '${plan.actualDaysPerWeek} sessões, '
            '~${plan.minutesPerSession} min cada',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Gerado em ${_formatDate(plan.generatedAt)} · '
            'válido até ${_formatDate(plan.validUntil)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final session in plan.sessions)
            _SessionCard(
              session: session,
              onStart: () => _startSession(session, plan),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PlacementResultScreen(estimate: widget.placement),
              ),
            ),
            child: const Text('Ver colocação inicial'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _regenerating ? null : _regenerate,
            child: _regenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gerar novamente'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onStart});

  final PlannedSession session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.dayLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.tonal(
                  onPressed: onStart,
                  child: const Text('Iniciar sessão'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in session.items) _ExerciseRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.item});

  final PlannedExerciseItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatternIllustration(pattern: item.pattern, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namePtBr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(item.setsRepsGuidance),
                Text(
                  _reasonText(item.reasonCode),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reasonText(PlanReasonCode code) {
    switch (code) {
      case PlanReasonCode.foundationGap:
        return 'Incluído para cobrir um padrão fundamental da semana.';
      case PlanReasonCode.weeklyBalance:
        return 'Incluído para equilibrar o estímulo entre os dias.';
      case PlanReasonCode.equipmentSubstitution:
        return 'Trocado por uma variação sem equipamento, pois o '
            'equipamento preferido não está disponível.';
    }
  }
}
