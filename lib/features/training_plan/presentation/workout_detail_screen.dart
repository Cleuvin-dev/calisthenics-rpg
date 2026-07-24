import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/presentation/exercise_media.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../../workout_session/domain/workout_session.dart';
import '../../workout_session/presentation/workout_player_screen.dart';
import '../domain/exercise_catalog.dart';
import '../domain/workout_catalog.dart';

/// Detalhe do treino antes de iniciar
/// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §8): nome, objetivo,
/// duração, dificuldade, equipamentos, lista ordenada, aviso de
/// segurança e botão "Iniciar treino".
class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.placement,
  });

  final Workout workout;
  final CapabilityEstimateRecord placement;

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  bool _starting = false;

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

  Future<void> _startWorkout() async {
    setState(() => _starting = true);
    final repository = ref.read(workoutSessionRepositoryProvider);
    final active = await repository.latestActive();

    if (active != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Finalize ou pause a sessão em andamento antes '
              'de iniciar outra.',
            ),
          ),
        );
      }
      await _openSession(active.id);
      if (mounted) setState(() => _starting = false);
      return;
    }

    final id = await repository.startSession(
      dayLabel: widget.workout.namePtBr,
      items: widget.workout.exercises.map(_toSessionItem).toList(),
      planRuleVersion: workoutCatalogVersion,
      catalogVersion: exerciseCatalogVersion,
      now: DateTime.now(),
    );
    ref.invalidate(latestActiveWorkoutSessionProvider);
    await _openSession(id);
    if (mounted) setState(() => _starting = false);
  }

  WorkoutSessionItem _toSessionItem(CatalogExercise exercise) {
    return WorkoutSessionItem(
      pattern: exercise.pattern,
      exerciseSlug: exercise.slug,
      namePtBr: exercise.namePtBr,
      setsRepsGuidance: exercise.setsRepsGuidance,
      doseType: exercise.doseType,
      targetSets: exercise.targetSets,
      targetReps: exercise.targetReps,
      targetSeconds: exercise.targetSeconds,
      restSeconds: exercise.restSeconds,
      mediaSlug: exercise.mediaSlug,
    );
  }

  String _doseText(CatalogExercise exercise) {
    final dose = exercise.doseType == DoseType.duration
        ? '${exercise.targetSeconds} segundos'
        : '${exercise.targetReps} repetições';
    return '${exercise.targetSets} séries · $dose · '
        'descanso ${exercise.restSeconds} s';
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    return Scaffold(
      appBar: AppBar(title: Text(workout.namePtBr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            workout.objectivePtBr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('${workout.level.labelPtBr} · ~${workout.estimatedMinutes} min'),
          Text(
            workout.equipment.isEmpty
                ? 'Sem equipamento'
                : 'Equipamento: ${workout.equipment.map((e) => e.label).join(', ')}',
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(workout.safetyNoticePtBr)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Exercícios', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final exercise in workout.exercises)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: ExerciseMedia(
                  exerciseSlug: exercise.slug,
                  pattern: exercise.pattern,
                  namePtBr: exercise.namePtBr,
                  mediaSlug: exercise.mediaSlug,
                  size: 56,
                ),
                title: Text(exercise.namePtBr),
                subtitle: Text(_doseText(exercise)),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _starting ? null : _startWorkout,
            child: _starting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Iniciar treino'),
          ),
        ],
      ),
    );
  }
}
