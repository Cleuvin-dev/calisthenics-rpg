import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/active_timer.dart';

/// Descanso **entre séries do mesmo exercício** (seção 5 do pedido do
/// usuário) — diferente de `RestScreen`, que é o descanso entre
/// exercícios (tela cheia, com prévia do próximo exercício). Reaproveita
/// o mesmo `ActiveTimer` monotônico já usado em `RestScreen`/
/// `TimedSetPlayer`. Sem persistência entre aberturas do app (mesmo
/// espírito de `RestScreen`): se o app fechar durante o descanso entre
/// séries, reabrir mostra a próxima série pronta para começar, sem risco
/// de perda de dado.
class RestTimerPanel extends StatefulWidget {
  const RestTimerPanel({
    super.key,
    required this.seconds,
    required this.onFinished,
  });

  final int seconds;

  /// Chamado uma única vez, seja pelo tempo esgotar ou pelo usuário
  /// pular o descanso.
  final VoidCallback onFinished;

  @override
  State<RestTimerPanel> createState() => _RestTimerPanelState();
}

class _RestTimerPanelState extends State<RestTimerPanel> {
  final ActiveTimer _timer = ActiveTimer();
  Timer? _ticker;
  bool _finished = false;

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
      (widget.seconds - _timer.elapsed.inSeconds).clamp(0, widget.seconds);

  void _tick() {
    if (!mounted || _finished) return;
    if (_remaining <= 0) {
      _finish();
      return;
    }
    setState(() {});
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'DESCANSO',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: '$_remaining segundos de descanso restantes',
          child: Text('${_remaining}s', style: textTheme.displayMedium),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _finished ? null : _finish,
          child: const Text('Pular descanso'),
        ),
      ],
    );
  }
}
