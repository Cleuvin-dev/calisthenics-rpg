import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/presentation/exercise_media.dart';
import '../domain/active_timer.dart';

/// Tela de descanso entre exercícios
/// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §14). Pular ou estender
/// não gera nem remove XP. Sem persistência entre sessões do app — se o
/// app fechar durante o descanso, reabrir simplesmente volta a mostrar o
/// próximo exercício pronto para começar, sem risco de perda de dado
/// (diferente de uma série em andamento).
class RestScreen extends StatefulWidget {
  const RestScreen({
    super.key,
    required this.seconds,
    required this.nextExerciseSlug,
    required this.nextExercisePattern,
    required this.nextExerciseNamePtBr,
    required this.onPauseSession,
    required this.onPain,
  });

  final int seconds;
  final String nextExerciseSlug;
  final String nextExercisePattern;
  final String nextExerciseNamePtBr;
  final VoidCallback onPauseSession;
  final VoidCallback onPain;

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  late int _totalSeconds = widget.seconds;
  final ActiveTimer _timer = ActiveTimer();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _timer.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _remaining =>
      (_totalSeconds - _timer.elapsed.inSeconds).clamp(0, _totalSeconds);

  void _tick() {
    if (!mounted) return;
    if (_remaining <= 0) {
      _ticker?.cancel();
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  void _addFifteenSeconds() {
    setState(() => _totalSeconds += 15);
  }

  void _skip() {
    _ticker?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Descanso'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: 'Pausar sessão',
            onPressed: widget.onPauseSession,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Semantics(
              label: '$_remaining segundos de descanso restantes',
              child: Text(
                '$_remaining s',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 32),
            Text('Próximo', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ExerciseMedia(
              exerciseSlug: widget.nextExerciseSlug,
              pattern: widget.nextExercisePattern,
              namePtBr: widget.nextExerciseNamePtBr,
              size: 80,
            ),
            const SizedBox(height: 8),
            Text(
              widget.nextExerciseNamePtBr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addFifteenSeconds,
                    child: const Text('+15 s'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _skip,
                    child: const Text('Pular descanso'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: widget.onPain,
              child: const Text('Senti dor'),
            ),
          ],
        ),
      ),
    );
  }
}
