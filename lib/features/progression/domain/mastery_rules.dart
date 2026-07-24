/// Regra determinística mínima de domínio por variação de push_horizontal
/// (PROGRESSION_RULES.md §2). Números espelham a dose conservadora já
/// usada no catálogo (`exercise_catalog.dart`) — placeholders de MVP,
/// números finais exigem aprovação profissional (TRAINING_ENGINE.md §6).
const masteryRuleVersion = 'mastery-push-horizontal-v1';

class MasteryRule {
  const MasteryRule({
    required this.exerciseSlug,
    required this.minRepsPerSet,
    required this.minQualifyingSets,
    required this.confirmationsRequired,
    required this.minHoursBetweenConfirmations,
  });

  final String exerciseSlug;

  /// Repetições mínimas por série para a série contar como evidência.
  final int minRepsPerSet;

  /// Séries qualificadas mínimas na sessão para ela contar como uma
  /// confirmação (PROGRESSION_RULES.md §2 `mastery_rule.sets`).
  final int minQualifyingSets;

  /// Sessões qualificadas necessárias (PROGRESSION_RULES.md §2
  /// `confirmations`).
  final int confirmationsRequired;

  /// Intervalo mínimo entre confirmações (`min_hours_between`).
  final int minHoursBetweenConfirmations;
}

/// Uma regra por variação da escada de push_horizontal
/// (push_horizontal_anchor.dart). Sem regra para níveis 8+: a escala
/// deste MVP só cobre 0-7 (pushHorizontalLevelNames).
const Map<String, MasteryRule> pushHorizontalMasteryRules = {
  'push_up_wall': MasteryRule(
    exerciseSlug: 'push_up_wall',
    minRepsPerSet: 6,
    minQualifyingSets: 2,
    confirmationsRequired: 2,
    minHoursBetweenConfirmations: 48,
  ),
  'push_up_incline': MasteryRule(
    exerciseSlug: 'push_up_incline',
    minRepsPerSet: 6,
    minQualifyingSets: 2,
    confirmationsRequired: 2,
    minHoursBetweenConfirmations: 48,
  ),
  'push_up_knees': MasteryRule(
    exerciseSlug: 'push_up_knees',
    minRepsPerSet: 6,
    minQualifyingSets: 2,
    confirmationsRequired: 2,
    minHoursBetweenConfirmations: 48,
  ),
  'push_up_floor': MasteryRule(
    exerciseSlug: 'push_up_floor',
    minRepsPerSet: 5,
    minQualifyingSets: 2,
    confirmationsRequired: 2,
    minHoursBetweenConfirmations: 48,
  ),
};
