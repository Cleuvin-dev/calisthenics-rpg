/// Regra determinística mínima de domínio por variação de cada padrão
/// (PROGRESSION_RULES.md §2). Números espelham a dose conservadora já
/// usada no catálogo (`exercise_catalog.dart`) — placeholders de MVP,
/// números finais exigem aprovação profissional (TRAINING_ENGINE.md §6).
const masteryRuleVersion = 'mastery-rules-v1';

class MasteryRule {
  const MasteryRule({
    required this.exerciseSlug,
    this.minRepsPerSet,
    this.minSecondsPerSet,
    required this.minQualifyingSets,
    required this.confirmationsRequired,
    required this.minHoursBetweenConfirmations,
  }) : assert(
         minRepsPerSet != null || minSecondsPerSet != null,
         'Uma regra precisa de um limiar por repetições ou por duração.',
       );

  final String exerciseSlug;

  /// Repetições mínimas por série para a série contar como evidência —
  /// exercícios por repetição (`DoseType.reps`).
  final int? minRepsPerSet;

  /// Duração mínima (segundos de tempo ativo) por série para contar como
  /// evidência — exercícios por duração (`DoseType.duration`, ex.:
  /// pranchas), avaliados por `activeDurationMs` em vez de reps.
  final int? minSecondsPerSet;

  /// Séries qualificadas mínimas na sessão para ela contar como uma
  /// confirmação (PROGRESSION_RULES.md §2 `mastery_rule.sets`).
  final int minQualifyingSets;

  /// Sessões qualificadas necessárias (PROGRESSION_RULES.md §2
  /// `confirmations`).
  final int confirmationsRequired;

  /// Intervalo mínimo entre confirmações (`min_hours_between`).
  final int minHoursBetweenConfirmations;
}

/// Uma regra por variação de cada padrão, chaveada por
/// `pattern -> exerciseSlug`. Sem regra para níveis fora da escala
/// coberta pelo catálogo de cada padrão (ver `levelNamesByPattern` em
/// `progression_repository.dart`).
const Map<String, Map<String, MasteryRule>> masteryRulesByPattern = {
  'push_horizontal': {
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
  },
  'pull_horizontal': {
    'scapular_retraction_bodyweight': MasteryRule(
      exerciseSlug: 'scapular_retraction_bodyweight',
      minRepsPerSet: 8,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'band_row': MasteryRule(
      exerciseSlug: 'band_row',
      minRepsPerSet: 8,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'incline_australian_row': MasteryRule(
      exerciseSlug: 'incline_australian_row',
      minRepsPerSet: 8,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'horizontal_row_straight_legs': MasteryRule(
      exerciseSlug: 'horizontal_row_straight_legs',
      minRepsPerSet: 8,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'assisted_archer_row': MasteryRule(
      exerciseSlug: 'assisted_archer_row',
      minRepsPerSet: 6,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
  },
  'squat': {
    'medium_bench_sit_to_stand': MasteryRule(
      exerciseSlug: 'medium_bench_sit_to_stand',
      minRepsPerSet: 10,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'assisted_squat_comfortable_range': MasteryRule(
      exerciseSlug: 'assisted_squat_comfortable_range',
      minRepsPerSet: 10,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'sit_to_stand_squat': MasteryRule(
      exerciseSlug: 'sit_to_stand_squat',
      minRepsPerSet: 12,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
  },
  'hinge_posterior_chain': {
    'glute_bridge': MasteryRule(
      exerciseSlug: 'glute_bridge',
      minRepsPerSet: 10,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'good_morning_bodyweight': MasteryRule(
      exerciseSlug: 'good_morning_bodyweight',
      minRepsPerSet: 10,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'unilateral_bridge': MasteryRule(
      exerciseSlug: 'unilateral_bridge',
      minRepsPerSet: 8,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
  },
  'core_anti_extension': {
    'dead_bug_simplified': MasteryRule(
      exerciseSlug: 'dead_bug_simplified',
      minRepsPerSet: 8,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'incline_plank': MasteryRule(
      exerciseSlug: 'incline_plank',
      minSecondsPerSet: 20,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'forearm_plank_full': MasteryRule(
      exerciseSlug: 'forearm_plank_full',
      minSecondsPerSet: 30,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
    'hollow_tuck_hold': MasteryRule(
      exerciseSlug: 'hollow_tuck_hold',
      minSecondsPerSet: 15,
      minQualifyingSets: 2,
      confirmationsRequired: 2,
      minHoursBetweenConfirmations: 48,
    ),
  },
};
