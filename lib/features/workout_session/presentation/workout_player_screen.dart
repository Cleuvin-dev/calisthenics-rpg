import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/data/exercise_media_catalog_provider.dart';
import '../../../shared/presentation/exercise_image_card.dart';
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
import 'exercise_bottom_navigation.dart';
import 'exercise_execution_header.dart';
import 'exercise_primary_action_button.dart';
import 'exercise_set_metrics_card.dart';
import 'log_set_sheet.dart';
import 'rest_screen.dart';
import 'rest_timer_panel.dart';
import 'timed_set_player.dart';
import 'timed_set_recovery_dialog.dart';
import 'workout_summary_screen.dart';

/// Player de exercício (SCREENS_AND_FLOWS.md §4): série atual, alvo,
/// registro e o botão de dor sempre visível, nunca escondido em menu.
/// Compartilha o mesmo "shell" (cabeçalho, imagem, card de métricas)
/// entre as modalidades por repetições e por tempo
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

  /// Descanso **entre séries do mesmo exercício** (seção 5 do pedido do
  /// usuário) — diferente do `RestScreen` entre exercícios, que continua
  /// existindo sem mudança em `_advanceOrComplete`.
  bool _resting = false;

  /// Status coarse reportado por `TimedSetPlayer` (só para exercícios por
  /// tempo — repetições não têm fase interna própria).
  ExerciseSetStatus? _timedStatus;

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
  /// `Image.asset`/`ExerciseMedia`/`ExerciseImageCard` já tem seu
  /// `errorBuilder` para quando a imagem realmente for exibida.
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

  /// Toda série concluída (reps ou tempo) que não é a última do exercício
  /// entra em descanso — exceto quando a razão foi dor/interrupção
  /// manual, casos em que o usuário já está saindo do exercício, não
  /// continuando para a próxima série.
  void _maybeEnterRest({
    required int justLoggedSetNumber,
    required int totalSets,
  }) {
    if (justLoggedSetNumber < totalSets) {
      setState(() => _resting = true);
    }
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
    } else if (mounted) {
      _maybeEnterRest(justLoggedSetNumber: setNumber, totalSets: totalSets);
    }
  }

  /// Pular a série atual sem executá-la (seção 6 do pedido do usuário) —
  /// pede confirmação porque afeta o progresso do exercício, e conta
  /// como uma série registrada (`notCompleted`) para a regra de "todas as
  /// séries registradas" que habilita avançar.
  Future<void> _skipSet(WorkoutSessionItem item, int setNumber) async {
    if (_submitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pular esta série?'),
        content: const Text(
          'Ela será registrada como não concluída — ainda conta para o '
          'total de séries do exercício.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pular série'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    await ref
        .read(workoutSessionRepositoryProvider)
        .logSet(
          workoutSessionId: widget.workoutSessionId,
          exerciseSlug: item.exerciseSlug,
          pattern: item.pattern,
          setNumber: setNumber,
          repsCompleted: 0,
          targetReps: item.targetReps,
          perceivedEffort: PerceivedEffort.notCompleted,
          now: DateTime.now(),
        );
    ref.invalidate(setLogsForSessionProvider(widget.workoutSessionId));
    if (mounted) setState(() => _submitting = false);
  }

  void _goToPreviousExercise() {
    if (_currentIndex == 0 || _submitting) return;
    setState(() {
      _currentIndex--;
      _resting = false;
      _timedStatus = null;
    });
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
        _resting = false;
        _timedStatus = null;
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

  /// Exercício considerado "pronto para avançar": todas as séries
  /// registradas, ou uma delas foi por dor (a mesma regra de segurança
  /// de sempre — dor encerra o exercício, não exige completar o resto).
  bool _exerciseReadyToAdvance(List<SetLogRecord> itemLogs, int totalSets) {
    if (itemLogs.length >= totalSets) return true;
    return itemLogs.any(
      (l) =>
          PerceivedEffort.values.byName(l.perceivedEffort) ==
          PerceivedEffort.pain,
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
    final catalogAsync = ref.watch(exerciseMediaCatalogProvider);

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

                final mediaEntry = currentItem.mediaSlug == null
                    ? null
                    : catalogAsync.value?.bySlug(currentItem.mediaSlug!);

                return Scaffold(
                  body: SafeArea(
                    child: logsAsync.when(
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
                        final setsComplete = _exerciseReadyToAdvance(
                          itemLogs,
                          currentItem.targetSets,
                        );
                        final displaySet = setsComplete
                            ? currentItem.targetSets
                            : nextSetNumber;

                        final ExerciseSetStatus status;
                        if (_resting) {
                          status = ExerciseSetStatus.resting;
                        } else if (setsComplete) {
                          status = ExerciseSetStatus.completed;
                        } else if (currentItem.doseType == DoseType.duration) {
                          status = _timedStatus ?? ExerciseSetStatus.waiting;
                        } else {
                          status = itemLogs.isEmpty
                              ? ExerciseSetStatus.waiting
                              : ExerciseSetStatus.active;
                        }

                        Widget? primaryButton;
                        if (setsComplete) {
                          primaryButton = ExercisePrimaryActionButton(
                            label: 'Concluir exercício',
                            onPressed: (_submitting || _resting)
                                ? null
                                : () => _advanceOrComplete(
                                    session,
                                    items,
                                    isLast,
                                  ),
                          );
                        } else if (currentItem.doseType != DoseType.duration) {
                          primaryButton = ExercisePrimaryActionButton(
                            label: 'Concluir série',
                            onPressed: (_submitting || _resting)
                                ? null
                                : () => _logSet(
                                    currentItem,
                                    nextSetNumber,
                                    currentItem.targetSets,
                                  ),
                          );
                        }
                        // Enquanto uma série por tempo está rodando, o
                        // próprio `TimedSetPlayer` já mostra seus botões
                        // de ação (Iniciar/Pausar/Continuar) no lugar do
                        // botão principal — evita duas ações
                        // concorrentes para a mesma coisa.

                        return Column(
                          children: [
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  ExerciseExecutionHeader(
                                    exerciseNamePtBr: currentItem.namePtBr,
                                    categoryLabel:
                                        mediaEntry?.category ??
                                        currentItem.pattern.replaceAll(
                                          '_',
                                          ' ',
                                        ),
                                    level: mediaEntry?.level,
                                    exerciseIndex: _currentIndex + 1,
                                    totalExercises: items.length,
                                    onBack: _pauseAndExit,
                                    onAbandon: _confirmAbandon,
                                  ),
                                  const SizedBox(height: 16),
                                  ExerciseImageCard(
                                    key: ValueKey(currentItem.exerciseSlug),
                                    exerciseSlug: currentItem.exerciseSlug,
                                    pattern: currentItem.pattern,
                                    namePtBr: currentItem.namePtBr,
                                    mediaSlug: currentItem.mediaSlug,
                                  ),
                                  const SizedBox(height: 16),
                                  ExerciseSetMetricsCard(
                                    currentSet: displaySet,
                                    totalSets: currentItem.targetSets,
                                    metricLabel:
                                        currentItem.doseType ==
                                            DoseType.duration
                                        ? 'TEMPO'
                                        : 'REPETIÇÕES',
                                    metricValue:
                                        currentItem.doseType ==
                                            DoseType.duration
                                        ? '${currentItem.targetSeconds ?? 0}s'
                                        : '${currentItem.targetReps ?? 0}',
                                    restSeconds: currentItem.restSeconds,
                                    status: status,
                                  ),
                                  const SizedBox(height: 16),
                                  if (_resting)
                                    RestTimerPanel(
                                      key: ValueKey(
                                        '${currentItem.exerciseSlug}-rest-$nextSetNumber',
                                      ),
                                      seconds: currentItem.restSeconds,
                                      onFinished: () {
                                        if (mounted) {
                                          setState(() => _resting = false);
                                        }
                                      },
                                    )
                                  else if (currentItem.doseType ==
                                      DoseType.duration)
                                    if (setsComplete)
                                      Text(
                                        'Todas as séries desta série por '
                                        'tempo já foram registradas.',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      )
                                    else
                                      TimedSetPlayer(
                                        key: ValueKey(
                                          '${currentItem.exerciseSlug}-$nextSetNumber',
                                        ),
                                        workoutSessionId:
                                            widget.workoutSessionId,
                                        exerciseSlug: currentItem.exerciseSlug,
                                        pattern: currentItem.pattern,
                                        exerciseNamePtBr: currentItem.namePtBr,
                                        setNumber: nextSetNumber,
                                        totalSets: currentItem.targetSets,
                                        targetSeconds:
                                            currentItem.targetSeconds ?? 30,
                                        initialElapsedMs:
                                            nextSetNumber == _recoveredSetNumber
                                            ? _recoveredElapsedMs
                                            : null,
                                        countdownSeconds: countdownSeconds,
                                        onStatusChanged: (value) {
                                          if (mounted) {
                                            setState(
                                              () => _timedStatus = value,
                                            );
                                          }
                                        },
                                        onFinalized: (reason) {
                                          ref.invalidate(
                                            setLogsForSessionProvider(
                                              widget.workoutSessionId,
                                            ),
                                          );
                                          if (!mounted) return;
                                          setState(() {
                                            _timedStatus = null;
                                          });
                                          if (reason ==
                                              TimedSetCompletionReason
                                                  .targetReached) {
                                            _maybeEnterRest(
                                              justLoggedSetNumber:
                                                  nextSetNumber,
                                              totalSets: currentItem.targetSets,
                                            );
                                          }
                                        },
                                        onPain: () => _showPainDialog(),
                                      )
                                  else ...[
                                    for (final log in itemLogs)
                                      ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.check_circle_outline,
                                        ),
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
                                    if (!setsComplete) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: OutlinedButton(
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
                                      ),
                                    ],
                                  ],
                                  if (primaryButton != null) ...[
                                    const SizedBox(height: 16),
                                    primaryButton,
                                  ],
                                ],
                              ),
                            ),
                            SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  16,
                                ),
                                child: ExerciseBottomNavigation(
                                  onSkipSet:
                                      (_resting ||
                                          _submitting ||
                                          setsComplete ||
                                          currentItem.doseType ==
                                              DoseType.duration)
                                      ? null
                                      : () => _skipSet(
                                          currentItem,
                                          nextSetNumber,
                                        ),
                                  onPrevious:
                                      (_currentIndex == 0 || _submitting)
                                      ? null
                                      : _goToPreviousExercise,
                                  onNext: (!setsComplete || _submitting)
                                      ? null
                                      : () => _advanceOrComplete(
                                          session,
                                          items,
                                          isLast,
                                        ),
                                  isLastExercise: isLast,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
