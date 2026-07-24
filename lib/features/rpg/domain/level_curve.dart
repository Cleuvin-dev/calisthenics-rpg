import 'dart:math';

/// Curva de nível de RPG_SYSTEM.md §3:
/// `xp_necessario = arredondar(100 + 25 × nivel^1.35)`.
/// O backend real usaria tabela pré-calculada e versionada; aqui a
/// fórmula é a própria regra versionada do MVP local-only.
const levelCurveVersion = 'level-curve-v1';

int xpRequiredForLevel(int level) => (100 + 25 * pow(level, 1.35)).round();

class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.currentLevelXp,
    required this.xpForNextLevel,
  });

  final int level;

  /// XP acumulado dentro do nível atual (não o total desde o início).
  final int currentLevelXp;

  /// XP necessário para completar o nível atual.
  final int xpForNextLevel;

  double get progress => currentLevelXp / xpForNextLevel;
}

class LevelCalculator {
  const LevelCalculator();

  LevelProgress levelFor(int totalXp) {
    var level = 1;
    var remaining = totalXp;

    while (true) {
      final needed = xpRequiredForLevel(level);
      if (remaining < needed) {
        return LevelProgress(
          level: level,
          currentLevelXp: remaining,
          xpForNextLevel: needed,
        );
      }
      remaining -= needed;
      level++;
    }
  }
}
