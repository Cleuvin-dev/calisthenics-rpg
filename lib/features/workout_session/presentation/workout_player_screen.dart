import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../assessment/data/capability_estimate_providers.dart';
import '../../progression/data/progression_providers.dart';
import '../../rpg/data/rpg_providers.dart';
import '../../rpg/domain/level_curve.dart';
import '../../rpg/domain/xp_rules.dart';
import '../data/workout_session_providers.dart';
import '../data/workout_session_repository.dart';
import '../domain/workout_session.dart';
import 'log_set_sheet.dart';
import 'workout_summary_screen.dart';

/// Player de exercício (SCREENS_AND_FLOWS.md §4): série atual, alvo,
/// registro e o botão de dor sempre visível, nunca escondido em menu.
class WorkoutPlayerScreen extends ConsumerStatefulWidget {
  const WorkoutPlayerScreen({
    super.key,
    required this.workoutSessionId,
    required this.pushHorizontalPlacement,
  });

  final int workoutSessionId;

  /// Colocação atual em push_horizontal, usada para avaliar confirmação
  /// de domínio ao concluir a sessão (ver `_completeSession`).
  final CapabilityEstimateRecord pushHorizontalPlacement;

  @override
  ConsumerState<WorkoutPlayerScreen> createState() =>
      _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends ConsumerState<WorkoutPlayerScreen> {
  int _currentIndex = 0;

  Future<void> _pauseAndExit() async {
    await ref
        .read(workoutSessionRepositoryProvider)
        .pause(widget.workoutSessionId);
    ref.invalidate(latestActiveWorkoutSessionProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandonar sessão?'),
        content: const Text(
          'As séries já registradas continuam salvas no seu histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(workoutSessionRepositoryProvider)
        .abandon(widget.workoutSessionId, DateTime.now());
    ref.invalidate(latestActiveWorkoutSessionProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _logSet(WorkoutSessionItem item, int setNumber) async {
    final result = await showModalBottomSheet<LoggedSet>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogSetSheet(setNumber: setNumber),
    );
    if (result == null) return;

    await ref.read(workoutSessionRepositoryProvider).logSet(
          workoutSessionId: widget.workoutSessionId,
          exerciseSlug: item.exerciseSlug,
          pattern: item.pattern,
          setNumber: setNumber,
          repsCompleted: result.reps,
          perceivedEffort: result.effort,
          now: DateTime.now(),
        );
    ref.invalidate(setLogsForSessionProvider(widget.workoutSessionId));

    if (result.effort == PerceivedEffort.pain && mounted) {
      await _showPainDialog();
    }
  }

  Future<void> _reportPainNow(WorkoutSessionItem item, int setNumber) async {
    await ref.read(workoutSessionRepositoryProvider).logSet(
          workoutSessionId: widget.workoutSessionId,
          exerciseSlug: item.exerciseSlug,
          pattern: item.pattern,
          setNumber: setNumber,
          repsCompleted: 0,
          perceivedEffort: PerceivedEffort.pain,
          now: DateTime.now(),
        );
    ref.invalidate(setLogsForSessionProvider(widget.workoutSessionId));
    if (mounted) await _showPainDialog();
  }

  Future<void> _showPainDialog() {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pare este exercício'),
        content: const Text(
          'Dor não é requisito de progresso. Vamos seguir para o próximo '
          'exercício da sessão.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSession(
    String dayLabel,
    List<WorkoutSessionItem> items,
  ) async {
    final now = DateTime.now();
    final sessionRepository = ref.read(workoutSessionRepositoryProvider);
    await sessionRepository.complete(widget.workoutSessionId, now);
    ref.invalidate(latestActiveWorkoutSessionProvider);

    final masteryResult =
        await ref.read(progressionRepositoryProvider).evaluateAndPromotePushHorizontal(
              currentLevel: widget.pushHorizontalPlacement.level,
              placementComputedAt: widget.pushHorizontalPlacement.computedAt,
              now: now,
            );
    if (masteryResult?.promoted ?? false) {
      ref.invalidate(latestCapabilityEstimateProvider('push_horizontal'));
    }

    final xpRepository = ref.read(xpLedgerRepositoryProvider);
    const levelCalculator = LevelCalculator();
    final levelBefore = levelCalculator.levelFor(await xpRepository.totalXp()).level;

    final logs = await sessionRepository.setLogsFor(widget.workoutSessionId);
    final awards = awardsForCompletedSession(
      workoutSessionId: widget.workoutSessionId,
      items: items,
      loggedExerciseSlugs: logs.map((l) => l.exerciseSlug).toSet(),
      masteryPromoted: masteryResult?.promoted ?? false,
      masteryPattern: 'push_horizontal',
      masteryNewLevel: masteryResult?.newLevel,
    );
    final xpAwarded = await xpRepository.grantAwards(awards, now: now);
    final levelAfter = levelCalculator.levelFor(await xpRepository.totalXp()).level;
    ref.invalidate(levelProgressProvider);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          workoutSessionId: widget.workoutSessionId,
          dayLabel: dayLabel,
          masteryResult: masteryResult,
          xpAwarded: xpAwarded,
          leveledUp: levelAfter > levelBefore,
          newLevel: levelAfter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync =
        ref.watch(workoutSessionByIdProvider(widget.workoutSessionId));

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(body: Center(child: Text('Erro: $error'))),
      data: (session) {
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Sessão não encontrada.')),
          );
        }

        final items = session.items;
        final currentItem = items[_currentIndex];
        final isLast = _currentIndex == items.length - 1;
        final logsAsync =
            ref.watch(setLogsForSessionProvider(widget.workoutSessionId));

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.pause),
              tooltip: 'Pausar e sair',
              onPressed: _pauseAndExit,
            ),
            title: Text(session.dayLabel),
            actions: [
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: 'Abandonar sessão',
                onPressed: _confirmAbandon,
              ),
            ],
          ),
          body: logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erro: $error')),
            data: (logs) {
              final itemLogs = logs
                  .where((l) => l.exerciseSlug == currentItem.exerciseSlug)
                  .toList();
              final nextSetNumber = itemLogs.length + 1;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Exercício ${_currentIndex + 1}/${items.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentItem.namePtBr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(currentItem.setsRepsGuidance),
                  const SizedBox(height: 16),
                  for (final log in itemLogs)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text('Série ${log.setNumber}: '
                          '${log.repsCompleted} reps'),
                      subtitle: Text(
                        PerceivedEffort.values
                            .byName(log.perceivedEffort)
                            .labelPtBr,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              _logSet(currentItem, nextSetNumber),
                          child: const Text('Registrar série'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () =>
                            _reportPainNow(currentItem, nextSetNumber),
                        child: const Text('Dor'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  if (isLast) {
                    _completeSession(session.dayLabel, items);
                  } else {
                    setState(() => _currentIndex++);
                  }
                },
                child: Text(isLast ? 'Concluir sessão' : 'Próximo exercício'),
              ),
            ),
          ),
        );
      },
    );
  }
}
