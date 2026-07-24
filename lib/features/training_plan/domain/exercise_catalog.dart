import '../../onboarding/domain/training_preferences.dart';

/// Entrada mínima do catálogo de exercícios (EXERCISE_SCHEMA.md), suficiente
/// para o motor de treino determinístico do MVP. Não é o catálogo editorial
/// completo (15+ variações por padrão, mídia, revisão profissional) previsto
/// em EXERCISE_SCHEMA.md §7 — apenas uma variação conservadora por padrão/
/// faixa de capacidade, para destravar a primeira geração de plano.
class CatalogExercise {
  const CatalogExercise({
    required this.slug,
    required this.namePtBr,
    required this.pattern,
    required this.setsRepsGuidance,
    this.requiredEquipment = const {},
    this.minCapabilityLevel = 0,
    this.maxCapabilityLevel = 100,
    this.isWarmup = false,
  });

  final String slug;
  final String namePtBr;

  /// Um dos padrões oficiais de EXERCISE_SCHEMA.md §3.
  final String pattern;

  /// Dose conservadora, em texto (TRAINING_ENGINE.md §6 — números finais
  /// exigem aprovação profissional; este é um placeholder de MVP).
  final String setsRepsGuidance;

  /// Vazio significa "sem equipamento" (sempre elegível).
  final Set<Equipment> requiredEquipment;

  /// Faixa de nível de capacidade (0-7, escala de push_horizontal) em que
  /// esta variação é apropriada. Padrões sem avaliação própria usam a
  /// variação de nível 0 (mais conservadora), espelhando
  /// `calculateSkippedEntirely` em conservative_placement.dart.
  final int minCapabilityLevel;
  final int maxCapabilityLevel;

  final bool isWarmup;

  bool suitableForLevel(int level) =>
      level >= minCapabilityLevel && level <= maxCapabilityLevel;

  bool availableWithEquipment(Set<Equipment> available) =>
      requiredEquipment.every(available.contains);
}

/// Catálogo mínimo versionado. Nova versão sempre que dose, padrão ou
/// requisito de equipamento mudar (EXERCISE_SCHEMA.md §6).
const exerciseCatalogVersion = 'minimal-catalog-v1';

/// Padrões cobertos nesta versão do catálogo. Os demais padrões oficiais de
/// EXERCISE_SCHEMA.md §3 ainda não têm variação cadastrada.
/// Slug do exercício de aquecimento, sempre o primeiro item de qualquer
/// sessão gerada. Referenciado por fora do catálogo (ex.: missão diária
/// "concluir o aquecimento" em `features/missions`).
const warmupExerciseSlug = 'warmup_joint_mobility';

const List<CatalogExercise> exerciseCatalog = [
  // Aquecimento — sempre o primeiro bloco da sessão (TRAINING_ENGINE.md §5).
  CatalogExercise(
    slug: warmupExerciseSlug,
    namePtBr: 'Mobilidade articular geral e marcha estacionária',
    pattern: 'mobility_specific',
    setsRepsGuidance: '3-5 min contínuos, ritmo confortável',
    isWarmup: true,
  ),

  // push_horizontal — mesma escada de push_horizontal_anchor.dart (0-7).
  CatalogExercise(
    slug: 'push_up_wall',
    namePtBr: 'Flexão na parede',
    pattern: 'push_horizontal',
    setsRepsGuidance: '2 séries de 6-10 repetições',
    minCapabilityLevel: 0,
    maxCapabilityLevel: 1,
  ),
  CatalogExercise(
    slug: 'push_up_incline',
    namePtBr: 'Flexão inclinada (bancada/superfície alta ou similar)',
    pattern: 'push_horizontal',
    setsRepsGuidance: '2-3 séries de 6-10 repetições',
    // Sem exigir Equipment.elevatedSurface: qualquer superfície firme e
    // segura serve (mesa, escada, parapeito), diferente de elástico/barra.
    minCapabilityLevel: 2,
    maxCapabilityLevel: 3,
  ),
  CatalogExercise(
    slug: 'push_up_knees',
    namePtBr: 'Flexão de joelhos',
    pattern: 'push_horizontal',
    setsRepsGuidance: '2-3 séries de 6-10 repetições',
    minCapabilityLevel: 4,
    maxCapabilityLevel: 5,
  ),
  CatalogExercise(
    slug: 'push_up_floor',
    namePtBr: 'Flexão tradicional (chão)',
    pattern: 'push_horizontal',
    setsRepsGuidance: '2-4 séries de 5-10 repetições, reps em reserva',
    minCapabilityLevel: 6,
    maxCapabilityLevel: 100,
  ),

  // pull_horizontal — não avaliado ainda: variação única e conservadora,
  // com alternativa quando há elástico disponível.
  CatalogExercise(
    slug: 'scapular_retraction_bodyweight',
    namePtBr: 'Retração escapular assistida (sem equipamento)',
    pattern: 'pull_horizontal',
    setsRepsGuidance: '2-3 séries de 8-12 repetições',
  ),
  CatalogExercise(
    slug: 'band_row',
    namePtBr: 'Remada com elástico',
    pattern: 'pull_horizontal',
    setsRepsGuidance: '2-3 séries de 8-12 repetições',
    requiredEquipment: {Equipment.elasticBand},
  ),

  // squat
  CatalogExercise(
    slug: 'sit_to_stand_squat',
    namePtBr: 'Agachamento livre (sentar e levantar)',
    pattern: 'squat',
    setsRepsGuidance: '2-3 séries de 8-15 repetições',
  ),

  // hinge_posterior_chain
  CatalogExercise(
    slug: 'glute_bridge',
    namePtBr: 'Ponte de glúteos',
    pattern: 'hinge_posterior_chain',
    setsRepsGuidance: '2-3 séries de 10-15 repetições',
  ),

  // core_anti_extension
  CatalogExercise(
    slug: 'dead_bug_simplified',
    namePtBr: 'Dead bug simplificado',
    pattern: 'core_anti_extension',
    setsRepsGuidance: '2-3 séries de 8-12 repetições por lado',
  ),

  // Bônus — só entram quando o orçamento de tempo sobra ou o equipamento
  // permite (WEEKLY_PLAN_GENERATOR aplica os filtros).
  CatalogExercise(
    slug: 'pike_push_up',
    namePtBr: 'Flexão pike (ombro)',
    pattern: 'push_vertical',
    setsRepsGuidance: '2 séries de 5-8 repetições',
  ),
  CatalogExercise(
    slug: 'parallel_bar_support_hold',
    namePtBr: 'Suporte estático em paralelas',
    pattern: 'support_dip',
    setsRepsGuidance: '2-3 séries de 10-20 segundos',
    requiredEquipment: {Equipment.parallelBars},
  ),
  CatalogExercise(
    slug: 'wall_assisted_handstand',
    namePtBr: 'Equilíbrio com apoio na parede',
    pattern: 'hand_balance',
    setsRepsGuidance: '2-3 tentativas de 10-20 segundos',
  ),
];

List<CatalogExercise> exercisesForPattern(String pattern) =>
    exerciseCatalog.where((e) => e.pattern == pattern).toList();

/// Nome amigável de um exercício pelo slug, ou o próprio slug se não
/// estiver mais no catálogo (conteúdo aposentado permanece referenciável
/// no histórico, DATA_MODEL.md §4).
String exerciseNameForSlug(String slug) {
  for (final exercise in exerciseCatalog) {
    if (exercise.slug == slug) return exercise.namePtBr;
  }
  return slug;
}

/// Variação de push_horizontal treinada no nível de capacidade atual, ou
/// `null` se nenhuma variação cobrir esse nível (fora da escala 0-7 desta
/// versão do catálogo).
String? pushHorizontalExerciseForLevel(int level) {
  final matches = exercisesForPattern('push_horizontal')
      .where((e) => e.suitableForLevel(level));
  return matches.isEmpty ? null : matches.first.slug;
}
