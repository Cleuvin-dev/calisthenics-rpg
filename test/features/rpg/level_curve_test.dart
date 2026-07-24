import 'package:calisthenics_rpg/features/rpg/domain/level_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = LevelCalculator();

  test('xpRequiredForLevel segue a fórmula de RPG_SYSTEM.md §3', () {
    expect(xpRequiredForLevel(1), 125);
    expect(xpRequiredForLevel(2), 164);
  });

  test('0 XP começa no nível 1, sem progresso', () {
    final progress = calculator.levelFor(0);
    expect(progress.level, 1);
    expect(progress.currentLevelXp, 0);
    expect(progress.xpForNextLevel, xpRequiredForLevel(1));
  });

  test('XP dentro do nível 1 não sobe de nível', () {
    final progress = calculator.levelFor(50);
    expect(progress.level, 1);
    expect(progress.currentLevelXp, 50);
  });

  test('XP exatamente no limite do nível avança para o próximo', () {
    final needed = xpRequiredForLevel(1);
    final progress = calculator.levelFor(needed);
    expect(progress.level, 2);
    expect(progress.currentLevelXp, 0);
  });

  test('XP acumulado atravessa múltiplos níveis corretamente', () {
    final level1 = xpRequiredForLevel(1);
    final level2 = xpRequiredForLevel(2);
    final progress = calculator.levelFor(level1 + level2 + 10);

    expect(progress.level, 3);
    expect(progress.currentLevelXp, 10);
  });

  test('progress reflete a fração do nível atual', () {
    final needed = xpRequiredForLevel(1);
    final progress = calculator.levelFor(needed ~/ 2);
    expect(progress.progress, closeTo(0.5, 0.05));
  });
}
