import 'package:calisthenics_rpg/features/assessment/domain/conservative_placement.dart';
import 'package:calisthenics_rpg/features/assessment/domain/fundamental_pattern_anchors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ConservativePlacementCalculator();
  final now = DateTime(2026, 7, 24);

  test('coloca um nível abaixo do autorrelato para squat', () {
    final result = calculator.calculateForPattern(
      pattern: squatPattern,
      anchor: squatAnchors.first, // skillLevel 1
      levelNames: squatLevelNames,
      now: now,
    );

    expect(result.pattern, squatPattern);
    expect(result.level, 0);
    expect(result.levelName, 'Sentar e levantar de banco alto');
    expect(result.inputAnchor, 'mediumBenchSitStand');
    expect(result.confidence, 'low');
    expect(result.reasonCode, PlacementReasonCode.skippedTestOneLevelBelow);
    expect(result.validUntil, now.add(const Duration(days: 30)));
  });

  test('coloca um nível abaixo do autorrelato para pull_horizontal', () {
    final result = calculator.calculateForPattern(
      pattern: pullHorizontalPattern,
      anchor: pullHorizontalAnchors.last, // skillLevel 7
      levelNames: pullHorizontalLevelNames,
      now: now,
    );

    expect(result.level, 6);
    expect(result.levelName, 'Remada com pés elevados');
  });

  test('calculateSkippedEntirelyForPattern usa o nível mais conservador',
      () {
    final result = calculator.calculateSkippedEntirelyForPattern(
      pattern: hingePosteriorChainPattern,
      levelNames: hingePosteriorChainLevelNames,
      now: now,
    );

    expect(result.level, 0);
    expect(result.levelName, 'Ponte de glúteos curta');
    expect(result.inputAnchor, isNull);
    expect(result.reasonCode, PlacementReasonCode.skippedEntirely);
  });

  test('fundamentalPatternLadders cobre os quatro padrões esperados', () {
    final patterns = fundamentalPatternLadders.map((l) => l.pattern).toSet();
    expect(patterns, {
      pullHorizontalPattern,
      squatPattern,
      hingePosteriorChainPattern,
      coreAntiExtensionPattern,
    });
  });

  test('cada âncora aponta para um nível existente no mapa de nomes menos 1',
      () {
    for (final ladder in fundamentalPatternLadders) {
      for (final anchor in ladder.anchors) {
        expect(
          ladder.levelNames.containsKey(anchor.skillLevel - 1),
          isTrue,
          reason: '${ladder.pattern}/${anchor.name} não tem nível '
              '${anchor.skillLevel - 1} nomeado',
        );
      }
    }
  });
}
