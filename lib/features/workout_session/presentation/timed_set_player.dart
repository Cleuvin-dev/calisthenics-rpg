import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workout_session_providers.dart';
import '../domain/active_timer.dart';
import '../domain/workout_session.dart';

enum _Phase { ready, preparing, running, paused }

/// Painel de dose por tempo (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md
/// §12): contagem preparatória 3-2-1, contador regressivo, pausa,
/// retomada, conclusão e interrupção. `ActiveTimer` (monotônico) é a
/// autoridade do tempo; o `Timer.periodic` aqui só repinta a UI e decide
/// quando persistir (SETTINGS_AND_TIMED_EXERCISES.md §13).
///
/// Quando [initialElapsedMs] vem preenchido (recuperação após fechar o
/// app), o painel começa pausado — nunca retoma contando sozinho.
class TimedSetPlayer extends ConsumerStatefulWidget {
  const TimedSetPlayer({
    super.key,
    required this.workoutSessionId,
    required this.exerciseSlug,
    required this.pattern,
    required this.exerciseNamePtBr,
    required this.setNumber,
    required this.totalSets,
    required this.targetSeconds,
    required this.onFinalized,
    required this.onPain,
    this.initialElapsedMs,
    this.countdownSeconds = 3,
  });

  final int workoutSessionId;
  final String exerciseSlug;
  final String pattern;
  final String exerciseNamePtBr;
  final int setNumber;
  final int totalSets;
  final int targetSeconds;

  /// Chamado depois que a série é finalizada com sucesso (alvo atingido,
  /// interrompida ou dor) — o pai decide o que fazer a seguir.
  final VoidCallback onFinalized;

  /// Chamado depois de finalizar por dor — o pai mostra o fluxo de
  /// segurança (mesmo diálogo do player por repetições).
  final VoidCallback onPain;

  final int? initialElapsedMs;

  /// Preferência de "Contagem regressiva" (Definição > Treino), aplicada
  /// à contagem preparatória antes de a série por tempo começar a valer.
  final int countdownSeconds;

  @override
  ConsumerState<TimedSetPlayer> createState() => _TimedSetPlayerState();
}

class _TimedSetPlayerState extends ConsumerState<TimedSetPlayer>
    with WidgetsBindingObserver {
  late _Phase _phase;
  late ActiveTimer _timer;
  Timer? _uiTicker;
  Timer? _prepTicker;
  int _prepRemaining = 0;
  bool _hasPersistedRow = false;
  bool _busy = false;
  int _lastPersistedSecond = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = ActiveTimer();
    if (widget.initialElapsedMs != null) {
      _timer.restore(Duration(milliseconds: widget.initialElapsedMs!));
      _hasPersistedRow = true;
      _phase = _Phase.paused;
    } else {
      _phase = _Phase.ready;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiTicker?.cancel();
    _prepTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final backgrounding =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden;
    if (_phase == _Phase.running && backgrounding) {
      _persistProgress(running: true);
    }
  }

  Future<void> _persistProgress({required bool running}) async {
    if (!_hasPersistedRow) return;
    await ref
        .read(workoutSessionRepositoryProvider)
        .updateTimedSetProgress(
          workoutSessionId: widget.workoutSessionId,
          activeElapsedMs: _timer.elapsed.inMilliseconds,
          running: running,
          now: DateTime.now(),
        );
  }

  void _startPreparation() {
    if (widget.countdownSeconds <= 0) {
      _beginRunning();
      return;
    }
    setState(() {
      _phase = _Phase.preparing;
      _prepRemaining = widget.countdownSeconds;
    });
    _prepTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _prepRemaining--);
      if (_prepRemaining <= 0) {
        t.cancel();
        _beginRunning();
      }
    });
  }

  void _cancelPreparation() {
    _prepTicker?.cancel();
    setState(() => _phase = _Phase.ready);
  }

  Future<void> _beginRunning() async {
    if (!_hasPersistedRow) {
      await ref
          .read(workoutSessionRepositoryProvider)
          .startTimedSet(
            workoutSessionId: widget.workoutSessionId,
            exerciseSlug: widget.exerciseSlug,
            pattern: widget.pattern,
            setNumber: widget.setNumber,
            targetSeconds: widget.targetSeconds,
            now: DateTime.now(),
          );
      _hasPersistedRow = true;
    }
    if (!mounted) return;
    _timer.start();
    setState(() => _phase = _Phase.running);
    _uiTicker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (!mounted) return;
    final elapsedMs = _timer.elapsed.inMilliseconds;
    if (elapsedMs >= widget.targetSeconds * 1000) {
      _uiTicker?.cancel();
      _timer.pause();
      _completeAtTarget();
      return;
    }
    final currentSecond = elapsedMs ~/ 1000;
    if (currentSecond != _lastPersistedSecond) {
      _lastPersistedSecond = currentSecond;
      unawaited(_persistProgress(running: true));
    }
    setState(() {});
  }

  void _pause() {
    _uiTicker?.cancel();
    _timer.pause();
    setState(() => _phase = _Phase.paused);
    unawaited(_persistProgress(running: false));
  }

  void _resume() {
    _timer.resume();
    setState(() => _phase = _Phase.running);
    _uiTicker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _tick(),
    );
    unawaited(_persistProgress(running: true));
  }

  Future<void> _restartSet() async {
    _uiTicker?.cancel();
    if (_hasPersistedRow) {
      await ref
          .read(workoutSessionRepositoryProvider)
          .discardActiveTimedSet(widget.workoutSessionId);
      _hasPersistedRow = false;
    }
    if (!mounted) return;
    setState(() {
      _timer = ActiveTimer();
      _lastPersistedSecond = -1;
      _phase = _Phase.ready;
    });
  }

  Future<void> _stop() async {
    _uiTicker?.cancel();
    if (_timer.isRunning) _timer.pause();
    await _finalize(
      completionReason: TimedSetCompletionReason.userStopped,
      perceivedEffort: PerceivedEffort.notCompleted,
    );
  }

  Future<void> _reportPain() async {
    _uiTicker?.cancel();
    if (_timer.isRunning) _timer.pause();
    await _finalize(
      completionReason: TimedSetCompletionReason.pain,
      perceivedEffort: PerceivedEffort.pain,
    );
    if (mounted) widget.onPain();
  }

  Future<void> _completeAtTarget() async {
    setState(() => _phase = _Phase.paused);
    final effort = await _askPerceivedEffort();
    if (effort == null || !mounted) return; // segue pausado até escolher
    await _finalize(
      completionReason: TimedSetCompletionReason.targetReached,
      perceivedEffort: effort,
    );
  }

  Future<PerceivedEffort?> _askPerceivedEffort() {
    return showModalBottomSheet<PerceivedEffort>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempo concluído! Como foi a série?',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PerceivedEffort.values.map((effort) {
                return ChoiceChip(
                  label: Text(effort.labelPtBr),
                  selected: false,
                  onSelected: (_) => Navigator.of(sheetContext).pop(effort),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finalize({
    required TimedSetCompletionReason completionReason,
    required PerceivedEffort perceivedEffort,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref
        .read(workoutSessionRepositoryProvider)
        .finalizeTimedSet(
          workoutSessionId: widget.workoutSessionId,
          exerciseSlug: widget.exerciseSlug,
          pattern: widget.pattern,
          setNumber: widget.setNumber,
          targetSeconds: widget.targetSeconds,
          activeDurationMs: _timer.elapsed.inMilliseconds,
          completionReason: completionReason,
          perceivedEffort: perceivedEffort,
          now: DateTime.now(),
        );
    _hasPersistedRow = false;
    if (!mounted) return;
    widget.onFinalized();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = (widget.targetSeconds - _timer.elapsed.inSeconds)
        .clamp(0, widget.targetSeconds);
    final progress = 1 - (remainingSeconds / widget.targetSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Série ${widget.setNumber} de ${widget.totalSets}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_phase == _Phase.preparing)
          _PreparationView(
            secondsRemaining: _prepRemaining,
            onCancel: _cancelPreparation,
          )
        else if (_phase == _Phase.running || _phase == _Phase.paused)
          _RunningView(
            remainingSeconds: remainingSeconds,
            progress: progress,
            paused: _phase == _Phase.paused,
          )
        else
          Text(
            'Alvo: ${widget.targetSeconds} segundos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        const SizedBox(height: 24),
        _buildActions(context),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (_phase) {
      case _Phase.ready:
        return Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _startPreparation,
                child: const Text('Iniciar'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: _busy ? null : _reportPain,
              child: const Text('Senti dor'),
            ),
          ],
        );
      case _Phase.preparing:
        return const SizedBox.shrink();
      case _Phase.running:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _pause,
                    child: const Text('Pausar'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _busy ? null : _reportPain,
                  child: const Text('Senti dor'),
                ),
              ],
            ),
            TextButton(
              onPressed: _busy ? null : _stop,
              child: const Text('Interromper'),
            ),
          ],
        );
      case _Phase.paused:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _resume,
                    child: const Text('Continuar'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _restartSet,
                  child: const Text('Recomeçar série'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _busy ? null : _stop,
                    child: const Text('Interromper'),
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _busy ? null : _reportPain,
                  child: const Text('Senti dor'),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class _PreparationView extends StatelessWidget {
  const _PreparationView({
    required this.secondsRemaining,
    required this.onCancel,
  });

  final int secondsRemaining;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            secondsRemaining > 0 ? '$secondsRemaining' : 'Começar',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({
    required this.remainingSeconds,
    required this.progress,
    required this.paused,
  });

  final int remainingSeconds;
  final double progress;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: progress.clamp(0, 1),
                strokeWidth: 8,
              ),
            ),
            Semantics(
              label: paused
                  ? '$remainingSeconds segundos restantes, pausado'
                  : '$remainingSeconds segundos restantes, timer em andamento',
              child: Text(
                '$minutes:$seconds',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
