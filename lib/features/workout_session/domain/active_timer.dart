/// Cronômetro de tempo ativo com fonte monotônica
/// (SETTINGS_AND_TIMED_EXERCISES.md §13 — "não usar apenas decremento por
/// `Timer.periodic`"; `Timer.periodic` só deve atualizar a UI, nunca medir
/// a duração sozinho). Trocar o relógio do aparelho não altera o tempo
/// ativo, porque a fonte padrão é `Stopwatch` (monotônica), não
/// `DateTime.now()`.
///
/// Pausa não conta como tempo ativo: [pause] soma o trecho corrido ao
/// acumulado e para de avançar até [resume]/[start].
class ActiveTimer {
  ActiveTimer({int Function()? nowMs}) : _nowMs = nowMs ?? _systemNowMs;

  final int Function() _nowMs;

  static final Stopwatch _systemStopwatch = Stopwatch()..start();
  static int _systemNowMs() => _systemStopwatch.elapsedMilliseconds;

  int _accumulatedMs = 0;
  int? _segmentStartMs;

  bool get isRunning => _segmentStartMs != null;

  Duration get elapsed => Duration(milliseconds: _elapsedMs);

  int get _elapsedMs =>
      _accumulatedMs + (isRunning ? _nowMs() - _segmentStartMs! : 0);

  void start() {
    if (isRunning) return;
    _segmentStartMs = _nowMs();
  }

  void pause() {
    if (!isRunning) return;
    _accumulatedMs += _nowMs() - _segmentStartMs!;
    _segmentStartMs = null;
  }

  void resume() => start();

  /// Restaura um tempo já acumulado (recuperação após fechar o app ou
  /// bloquear a tela) — não fica rodando automaticamente; quem chamar
  /// decide se retoma com [start] ou mantém pausado.
  void restore(Duration accumulated) {
    _accumulatedMs = accumulated.inMilliseconds;
    _segmentStartMs = null;
  }
}
