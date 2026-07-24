import 'package:calisthenics_rpg/features/workout_session/domain/active_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('elapsed é zero antes de iniciar', () {
    final timer = ActiveTimer(nowMs: () => 0);
    expect(timer.elapsed, Duration.zero);
    expect(timer.isRunning, isFalse);
  });

  test('conta o tempo enquanto roda', () {
    var now = 0;
    final timer = ActiveTimer(nowMs: () => now);

    timer.start();
    now = 1000;
    expect(timer.elapsed, const Duration(milliseconds: 1000));

    now = 2500;
    expect(timer.elapsed, const Duration(milliseconds: 2500));
  });

  test('pausa não conta como tempo ativo', () {
    var now = 0;
    final timer = ActiveTimer(nowMs: () => now);

    timer.start();
    now = 1000;
    timer.pause();
    expect(timer.elapsed, const Duration(milliseconds: 1000));

    // Tempo passa enquanto pausado — não deve contar.
    now = 5000;
    expect(timer.elapsed, const Duration(milliseconds: 1000));
    expect(timer.isRunning, isFalse);
  });

  test('retomar soma ao tempo já acumulado, sem contar a pausa', () {
    var now = 0;
    final timer = ActiveTimer(nowMs: () => now);

    timer.start();
    now = 1000;
    timer.pause();

    now = 5000; // pausado por 4s, não deve contar
    timer.resume();
    now = 6000; // +1s ativo
    expect(timer.elapsed, const Duration(milliseconds: 2000));
  });

  test('start() chamado duas vezes seguidas não reinicia o segmento', () {
    var now = 0;
    final timer = ActiveTimer(nowMs: () => now);

    timer.start();
    now = 500;
    timer.start(); // no-op, já está rodando
    now = 1000;
    expect(timer.elapsed, const Duration(milliseconds: 1000));
  });

  test('restore recupera tempo acumulado após fechar o app', () {
    final timer = ActiveTimer(nowMs: () => 999999);
    timer.restore(const Duration(seconds: 12));

    expect(timer.elapsed, const Duration(seconds: 12));
    expect(timer.isRunning, isFalse);

    var now = 0;
    final resumed = ActiveTimer(nowMs: () => now);
    resumed.restore(const Duration(seconds: 12));
    now = 100;
    resumed.start();
    now = 600;
    expect(resumed.elapsed, const Duration(milliseconds: 12500));
  });
}
