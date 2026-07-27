import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/data/exercise_media_catalog_provider.dart';
import '../../../shared/presentation/exercise_media.dart';
import '../../assessment/data/capability_estimate_providers.dart';
import '../../assessment/domain/fundamental_pattern_anchors.dart';
import '../../progression/data/progression_providers.dart';
import '../../progression/domain/mastery_evaluator.dart';
import '../../rpg/data/rpg_providers.dart';
import '../../settings/data/settings_providers.dart';
import '../../rpg/domain/level_curve.dart';
import '../../rpg/domain/xp_rules.dart';
import '../../training_plan/domain/exercise_catalog.dart' show DoseType;
import '../data/workout_session_providers.dart';
import '../data/workout_session_repository.dart';
import '../domain/workout_session.dart';
import 'log_set_sheet.dart';
import 'rest_screen.dart';
import 'timed_set_player.dart';
import 'timed_set_recovery_dialog.dart';
import 'workout_summary_screen.dart';

/// Player de exercício (SCREENS_AND_FLOWS.md §4): série atual, alvo,
/// registro e o botão de dor sempre visível, nunca escondido em menu.
/// Compartilha o mesmo "shell" (AppBar, mídia, nome, série) entre as
/// modalidades por repetições e por tempo
/// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §10), só a área de dose
/// muda.
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
  int? _recoveredElapsedMs;
  int? _recoveredSetNumber;
  bool _submitting = false;
  bool _recoveryChecked = false;
  int _precachedForIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkForActiveTimedSet(),
    );
  }

  /// Recuperação após fechar o app/bloquear a tela
  /// (SETTINGS_AND_TIMED_EXERCISES.md §13.3): se havia uma série por
  /// tempo em andamento, pergunta o que fazer antes de mostrar o player
  /// normalmente — nunca retoma ou descarta sozinho.
  Future<void> _checkForActiveTimedSet() async {
    final repository = ref.read(workoutSessionRepositoryProvider);
    final active = await repository.activeTimedSetFor(widget.workoutSessionId);
    if (active == null || !mounted) {
      setState(() => _recoveryChecked = true);
      return;
    }

    final session = await ref.read(
      workoutSessionByIdProvider(widget.workoutSessionId).future,
    );
    if (session == null || !mounted) {
      setState(() => _recoveryChecked = true);
      return;
    }

    final items = session.items;
    final idx = items.indexWhere((i) => i.exerciseSlug == active.exerciseSlug);
    final exerciseName = idx == -1 ? active.exerciseSlug : items[idx].namePtBr;

    final choice = await showTimedSetRecoveryDialog(
      context,
      active: active,
      exerciseNamePtBr: exerciseName,
    );

    switch (choice) {
      case TimedSetRecoveryChoice.resume:
        setState(() {
          if (idx != -1) _currentIndex = idx;
          _recoveredElapsedMs = active.activeElapsedMs;
          _recoveredSetNumber = active.setNumber;
        });
      case TimedSetRecoveryChoice.markInterrupted:
        await repository.finalizeTimedSet(
          workoutSessionId: widget.workoutSessionId,
          exerciseSlug: active.exerciseSlug,
          pattern: active.pattern,
          setNumber: active.setNumber,
          targetSeconds: active.targetSeconds,
          activeDurationMs: active.activeElapsedMs,
          completionReason: TimedSetCompletionReason.userStopped,
          perceivedEffort: PerceivedEffort.notCompleted,
          now: DateTime.now(),
        );
        if (idx != -1 && mounted) setState(() => _currentIndex = idx);
        ref.invalidate(setLogsForSessionProvider(widget.workoutSessionId));
      case TimedSetRecoveryChoice.discard:
        await repository.discardActiveTimedSet(widget.workoutSessionId);
      case null:
        break;
    }

    if (mounted) setState(() => _recoveryChecked = true);
  }

  /// Pré-carrega só a imagem do exercício atual e a seguinte
  /// (`App_RPG_Exercise_Images/CLAUDE_CODE_PROMPT.md` #11) — não a
  /// sessão inteira, para não pressionar a memória de aparelhos Android
  /// intermediários. Falha de precache é silenciosa: o próprio
  /// `Image.asset`/`ExerciseMedia` já tem seu `errorBuilder` para quando
  /// a imagem realmente for exibida.
  void _precacheAdjacentMedia(List<WorkoutSessionItem> items) {
    if (_precachedForIndex == _currentIndex) return;
    _precachedForIndex = _currentIndex;

    final catalog = ref.read(exerciseMediaCatalogProvider).value;
    String resolve(WorkoutSessionItem item) {
      final mediaSlug = item.mediaSlug;
      final fromCatalog = mediaSlug == null
          ? null
          : catalog?.bySlug(mediaSlug)?.assetPath;
      return fromCatalog ??
          'assets/images/exercises/${item.exerciseSlug}/v1/start.png';
    }

    final toPreload = [
      items[_currentIndex],
      if (_currentIndex + 1 < items.length) items[_currentIndex + 1],
    ];
    for (final item in toPreload) {
      // `onError` (não só `.catchError` no Future retornado) é
      // necessário: o pipeline de imagem do Flutter também reporta o
      // erro via `FlutterError.onError` de forma síncrona, então só
      // capturar a Future não é suficiente para evitar o erro "subir".
      unawaited(
        precacheImage(
          AssetImage(resolve(item)),
          context,
          onError: (exception, stackTrace) {},
        ),
      );
    }
  }

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

  Future<void> _logSet(
    WorkoutSessionItem item,
    int setNumber,
    int totalSets,
  ) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final result = await showModalBottomSheet<LoggedSet>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogSetSheet(
        setNumber: setNumber,
        totalSets: totalSets,
        targetReps: item.targetReps ?? 8,
      ),
    );
    if (result == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    await ref
        .read(workoutSessionRepositoryProvider)
        .logSet(
          workoutSessionId: widget.workoutSessionId,
          exerciseSlug: item.exerciseSlug,
          pattern: item.pattern,
          setNumber: setNumber,
          repsCompleted: result.reps,
          targetReps: item.targetReps,
          perceivedEffort: result.effort,
          now: DateTime.now(),
        );
    ref.invalidate(setLogsForSessionProvider(widget.workoutSessionId));
    if (mounted) setState(() => _submitting = false);

    if (result.effort == PerceivedEffort.pain && mounted) {
      await _showPainDialog();
    }
  }

  Future<void> _reportPainNow(WorkoutSessionItem item, int setNumber) async {
    await ref
        .read(workoutSessionRepositoryProvider)
        .logSet(
          workoutSessionId: widget.workoutSessionId,
          exerciseSlug: item.exerciseSlug,
          pattern: item.pattern,
          setNumber: setNumber,
          repsCompleted: 0,
          targetReps: item.targetReps,
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

  Future<void> _advanceOrComplete(
    WorkoutSessionRecord session,
    List<WorkoutSessionItem> items,
    bool isLast,
  ) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    if (isLast) {
      await _completeSession(session.dayLabel, items);
      return;
    }

    final current = items[_currentIndex];
    final next = items[_currentIndex + 1];
    if (current.restSeconds > 0 && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RestScreen(
            seconds: current.restSeconds,
            nextExerciseSlug: next.exerciseSlug,
            nextExercisePattern: next.pattern,
            nextExerciseNamePtBr: next.namePtBr,
            nextExerciseMediaSlug: next.mediaSlug,
            onPauseSession: () {
              Navigator.of(context).pop();
              _pauseAndExit();
            },
            onPain: () async {
              await _showPainDialog();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _currentIndex++;
        _submitting = false;
      });
    }
  }

  Future<void> _completeSession(
    String dayLabel,
    List<WorkoutSessionItem> items,
  ) async {
    final now = DateTime.now();
    final sessionRepository = ref.read(workoutSessionRepositoryProvider);
    await sessionRepository.complete(widget.workoutSessionId, now);
    ref.invalidate(latestActiveWorkoutSessionProvider);

    final progressionRepository = ref.read(progressionRepositoryProvider);
    final masteryResults = <String, MasteryEvaluationResult>{};
    final masteryPromotions = <String, int>{};

    final pushHorizontalResult = await progressionRepository.evaluateAndPromote(
      pattern: 'push_horizontal',
      currentLevel: widget.pushHorizontalPlacement.level,
      placementComputedAt: widget.pushHorizontalPlacement.computedAt,
      now: now,
    );
    if (pushHorizontalResult != null) {
      masteryResults['push_horizontal'] = pushHorizontalResult;
    }
    if (pushHorizontalResult?.promoted ?? false) {
      masteryPromotions['push_horizontal'] = pushHorizontalResult!.newLevel!;
      ref.invalidate(latestCapabilityEstimateProvider('push_horizontal'));
    }

    // Os 4 padrões opcionais só têm progressão avaliada quando já existe
    // uma colocação salva (o usuário respondeu a autoavaliação em algum
    // momento) — sem isso não há `placementComputedAt` como marco pra
    // saber quais sessões contam como evidência.
    for (final ladder in fundamentalPatternLadders) {
      final placement = await ref.read(
        latestCapabilityEstimateProvider(ladder.pattern).future,
      );
      if (placement == null) continue;

      final result = await progressionRepository.evaluateAndPromote(
        pattern: ladder.pattern,
        currentLevel: placement.level,
        placementComputedAt: placement.computedAt,
        now: now,
      );
      if (result != null) {
        masteryResults[ladder.pattern] = result;
      }
      if (result?.promoted ?? false) {
        masteryPromotions[ladder.pattern] = result!.newLevel!;
        ref.invalidate(latestCapabilityEstimateProvider(ladder.pattern));
      }
    }

    final xpRepository = ref.read(xpLedgerRepositoryProvider);
    const levelCalculator = LevelCalculator();
    final levelBefore = levelCalculator
        .levelFor(await xpRepository.totalXp())
        .level;

    final logs = await sessionRepository.setLogsFor(widget.workoutSessionId);
    final awards = awardsForCompletedSession(
      workoutSessionId: widget.workoutSessionId,
      items: items,
      loggedExerciseSlugs: logs.map((l) => l.exerciseSlug).toSet(),
      masteryPromotions: masteryPromotions,
    );
    final xpAwarded = await xpRepository.grantAwards(awards, now: now);
    final levelAfter = levelCalculator
        .levelFor(await xpRepository.totalXp())
        .level;
    ref.invalidate(levelProgressProvider);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          workoutSessionId: widget.workoutSessionId,
          dayLabel: dayLabel,
          masteryResults: masteryResults,
          xpAwarded: xpAwarded,
          leveledUp: levelAfter > levelBefore,
          newLevel: levelAfter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      workoutSessionByIdProvider(widget.workoutSessionId),
    );
    final countdownSeconds = ref
        .watch(userSettingsProvider)
        .maybeWhen(
          data: (settings) => settings.countdownSeconds,
          orElse: () => 3,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Voltar (gesto/botão do sistema) pausa a sessão como o botão de
        // pausar do AppBar — sem isso, a sessão ficava presa em
        // "inProgress" mesmo depois de o usuário sair da tela.
        _pauseAndExit();
      },
      child: !_recoveryChecked
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : sessionAsync.when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) =>
                  Scaffold(body: Center(child: Text('Erro: $error'))),
              data: (session) {
                if (session == null) {
                  return const Scaffold(
                    body: Center(child: Text('Sessão não encontrada.')),
                  );
                }

                final items = session.items;
                final currentItem = items[_currentIndex];
                final isLast = _currentIndex == items.length - 1;
                final logsAsync = ref.watch(
                  setLogsForSessionProvider(widget.workoutSessionId),
                );
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _precacheAdjacentMedia(items),
                );

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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Erro: $error')),
                    data: (logs) {
                      final itemLogs = logs
                          .where(
                            (l) => l.exerciseSlug == currentItem.exerciseSlug,
                          )
                          .toList();
                      final nextSetNumber = itemLogs.length + 1;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Center(
                            child: ExerciseMedia(
                              key: ValueKey(currentItem.exerciseSlug),
                              exerciseSlug: currentItem.exerciseSlug,
                              pattern: currentItem.pattern,
                              namePtBr: currentItem.namePtBr,
                              mediaSlug: currentItem.mediaSlug,
                              size: 140,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                          if (currentItem.doseType == DoseType.duration)
                            TimedSetPlayer(
                              key: ValueKey(
                                '${currentItem.exerciseSlug}-$nextSetNumber',
                              ),
                              workoutSessionId: widget.workoutSessionId,
                              exerciseSlug: currentItem.exerciseSlug,
                              pattern: currentItem.pattern,
                              exerciseNamePtBr: currentItem.namePtBr,
                              setNumber: nextSetNumber,
                              totalSets: currentItem.targetSets,
                              targetSeconds: currentItem.targetSeconds ?? 30,
                              initialElapsedMs:
                                  nextSetNumber == _recoveredSetNumber
                                  ? _recoveredElapsedMs
                                  : null,
                              countdownSeconds: countdownSeconds,
                              onFinalized: () => ref.invalidate(
                                setLogsForSessionProvider(
                                  widget.workoutSessionId,
                                ),
                              ),
                              onPain: () => _showPainDialog(),
                            )
                          else ...[
                            for (final log in itemLogs)
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.check_circle_outline),
                                title: Text(
                                  'Série ${log.setNumber}: '
                                  '${log.repsCompleted} reps',
                                ),
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
                                    onPressed: _submitting
                                        ? null
                                        : () => _logSet(
                                            currentItem,
                                            nextSetNumber,
                                            currentItem.targetSets,
                                          ),
                                    child: const Text('Registrar série'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                  onPressed: () => _reportPainNow(
                                    currentItem,
                                    nextSetNumber,
                                  ),
                                  child: const Text('Senti dor'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  bottomNavigationBar: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        onPressed: _submitting
                            ? null
                            : () => _advanceOrComplete(session, items, isLast),
                        child: Text(
                          isLast ? 'Concluir sessão' : 'Próximo exercício',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
