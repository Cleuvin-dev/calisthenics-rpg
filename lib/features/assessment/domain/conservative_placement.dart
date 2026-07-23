import 'push_horizontal_anchor.dart';

/// Versão da regra de colocação conservadora aplicada nesta história.
/// Muda sempre que o mapeamento âncora→nível for revisado.
const conservativePlacementRuleVersion = 'conservative-placement-v1';

enum PlacementReasonCode { skippedTestOneLevelBelow }

class ConservativePlacementResult {
  const ConservativePlacementResult({
    required this.pattern,
    required this.level,
    required this.levelName,
    required this.confidence,
    required this.ruleVersion,
    required this.reasonCode,
    required this.inputAnchor,
    required this.computedAt,
    required this.validUntil,
  });

  final String pattern;
  final int level;
  final String levelName;

  /// Sempre 'low' nesta história: teste prático foi pulado (FR-012).
  final String confidence;
  final String ruleVersion;
  final PlacementReasonCode reasonCode;
  final PushHorizontalAnchor inputAnchor;
  final DateTime computedAt;
  final DateTime validUntil;
}

/// Colocação conservadora quando o usuário opta por pular o teste
/// (FR-012), aplicando a regra "um nó abaixo" de
/// SCORING_AND_PLACEMENT.md §7 com confiança baixa.
///
/// O período de validade (30 dias) é um valor de produto provisório,
/// dentro da janela de 4-8 semanas sugerida em INITIAL_ASSESSMENT.md §8,
/// pendente de aprovação profissional.
class ConservativePlacementCalculator {
  const ConservativePlacementCalculator();

  ConservativePlacementResult calculate({
    required PushHorizontalAnchor anchor,
    required DateTime now,
  }) {
    final level = anchor.skillLevel - 1;
    final levelName = pushHorizontalLevelNames[level] ?? 'Nível $level';

    return ConservativePlacementResult(
      pattern: 'push_horizontal',
      level: level,
      levelName: levelName,
      confidence: 'low',
      ruleVersion: conservativePlacementRuleVersion,
      reasonCode: PlacementReasonCode.skippedTestOneLevelBelow,
      inputAnchor: anchor,
      computedAt: now,
      validUntil: now.add(const Duration(days: 30)),
    );
  }
}
