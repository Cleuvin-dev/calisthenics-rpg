import 'package:calisthenics_rpg/features/assessment/domain/conservative_placement.dart';
import 'package:calisthenics_rpg/features/assessment/domain/push_horizontal_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ConservativePlacementCalculator();
  final now = DateTime(2026, 7, 23);

  test('coloca um nível abaixo do autorrelato de parede', () {
    final result =
        calculator.calculate(anchor: PushHorizontalAnchor.wall, now: now);
    expect(result.level, 0);
    expect(result.levelName, 'Empurrar a parede em pé');
  });

  test('coloca um nível abaixo do autorrelato de bancada/inclinada', () {
    final result = calculator.calculate(
      anchor: PushHorizontalAnchor.inclineHighSurface,
      now: now,
    );
    expect(result.level, 2);
    expect(result.levelName, 'Flexão em superfície muito alta');
  });

  test('coloca um nível abaixo do autorrelato de joelhos', () {
    final result =
        calculator.calculate(anchor: PushHorizontalAnchor.knees, now: now);
    expect(result.level, 4);
    expect(result.levelName, 'Flexão inclinada baixa');
  });

  test('coloca um nível abaixo do autorrelato de chão', () {
    final result =
        calculator.calculate(anchor: PushHorizontalAnchor.floor, now: now);
    expect(result.level, 6);
    expect(result.levelName, 'Negativa de flexão');
  });

  test('confiança é sempre baixa e a regra é versionada', () {
    final result =
        calculator.calculate(anchor: PushHorizontalAnchor.floor, now: now);
    expect(result.confidence, 'low');
    expect(result.ruleVersion, conservativePlacementRuleVersion);
    expect(result.reasonCode, PlacementReasonCode.skippedTestOneLevelBelow);
  });

  test('validade padrão é 30 dias a partir do cálculo', () {
    final result =
        calculator.calculate(anchor: PushHorizontalAnchor.wall, now: now);
    expect(result.validUntil, now.add(const Duration(days: 30)));
  });
}
