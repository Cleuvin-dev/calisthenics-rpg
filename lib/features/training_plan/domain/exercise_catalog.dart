import '../../onboarding/domain/training_preferences.dart';

/// Tipo de dose de um exercício (EXERCISE_SCHEMA.md §2
/// `prescription.dose_type`, VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md
/// §19). `repsOrDuration` está modelado para completude do schema, mas
/// nenhuma entrada do catálogo mínimo o usa ainda — o plano escolheria
/// uma modalidade antes da sessão, e o player nunca alterna sozinho.
enum DoseType { reps, duration, repsOrDuration }

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
    required this.doseType,
    this.targetSets = 2,
    this.targetReps,
    this.targetSeconds,
    this.minSeconds,
    this.maxSeconds,
    this.safetyCapSeconds,
    this.restSeconds = 60,
    this.requiredEquipment = const {},
    this.minCapabilityLevel = 0,
    this.maxCapabilityLevel = 100,
    this.isWarmup = false,
    this.mediaSlug,
  });

  final String slug;
  final String namePtBr;

  /// Um dos padrões oficiais de EXERCISE_SCHEMA.md §3.
  final String pattern;

  /// Dose conservadora, em texto (TRAINING_ENGINE.md §6 — números finais
  /// exigem aprovação profissional; este é um placeholder de MVP). Mantido
  /// como descrição legível ao lado dos campos estruturados abaixo.
  final String setsRepsGuidance;

  final DoseType doseType;

  /// Número de séries alvo — usado por ambas as modalidades.
  final int targetSets;

  /// Alvo de repetições por série, só para `DoseType.reps`. O player
  /// mostra este valor como alvo e inicia `performed_reps` igual a ele
  /// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §11.2).
  final int? targetReps;

  /// Duração recomendada, em segundos — só para `DoseType.duration`.
  /// Sem seletor de duração personalizável nesta entrega (fora do escopo
  /// combinado); os limites ficam registrados para uso futuro e para
  /// validação de segurança caso um valor customizado apareça.
  final int? targetSeconds;
  final int? minSeconds;
  final int? maxSeconds;
  final int? safetyCapSeconds;

  /// Descanso sugerido entre séries deste exercício, em segundos.
  final int restSeconds;

  /// Vazio significa "sem equipamento" (sempre elegível).
  final Set<Equipment> requiredEquipment;

  /// Faixa de nível de capacidade (escala própria de cada padrão — 0-7
  /// para push_horizontal/pull_horizontal/core_anti_extension, 0-5 para
  /// squat/hinge_posterior_chain) em que esta variação é apropriada.
  /// Padrões sem colocação salva usam nível 0 (mais conservadora),
  /// espelhando `calculateSkippedEntirely` em conservative_placement.dart.
  final int minCapabilityLevel;
  final int maxCapabilityLevel;

  final bool isWarmup;

  /// Slug no catálogo de 195 imagens estáticas
  /// (`assets/data/exercise_media_catalog.json`,
  /// `App_RPG_Exercise_Images/`), quando existe uma associação
  /// confiável — confirmada por referência cruzada de `starter_file`
  /// (as 4 imagens já usadas na história vertical anterior) ou por nome
  /// idêntico ao nó de `SKILL_TREES.md` no mesmo padrão/categoria.
  /// `null` quando a correspondência não é inequívoca (ex.: aquecimento,
  /// que não é um nó de nenhuma árvore) — nesses casos o placeholder
  /// animado continua sendo usado, o que é seguro e esperado. Ver
  /// `docs/PROJECT_STATUS.md` para a lista completa de associações e o
  /// que ficou de fora.
  final String? mediaSlug;

  bool suitableForLevel(int level) =>
      level >= minCapabilityLevel && level <= maxCapabilityLevel;

  bool availableWithEquipment(Set<Equipment> available) =>
      requiredEquipment.every(available.contains);
}

/// Catálogo mínimo versionado. Nova versão sempre que dose, padrão ou
/// requisito de equipamento mudar (EXERCISE_SCHEMA.md §6).
const exerciseCatalogVersion = 'minimal-catalog-v4';

/// Padrões cobertos nesta versão do catálogo. Os demais padrões oficiais de
/// EXERCISE_SCHEMA.md §3 ainda não têm variação cadastrada.
/// Slug do exercício de aquecimento, sempre o primeiro item de qualquer
/// sessão gerada. Referenciado por fora do catálogo (ex.: missão diária
/// "concluir o aquecimento" em `features/missions`).
const warmupExerciseSlug = 'warmup_joint_mobility';

/// Slug da prancha completa — referenciado pelo catálogo de treinos
/// (`workout_catalog.dart`) e pelos assets locais desta entrega.
const forearmPlankSlug = 'forearm_plank_full';

const List<CatalogExercise> exerciseCatalog = [
  // Aquecimento — sempre o primeiro bloco da sessão (TRAINING_ENGINE.md §5).
  CatalogExercise(
    slug: warmupExerciseSlug,
    namePtBr: 'Mobilidade articular geral e marcha estacionária',
    pattern: 'mobility_specific',
    setsRepsGuidance: '3-5 min contínuos, ritmo confortável',
    doseType: DoseType.duration,
    targetSets: 1,
    targetSeconds: 240,
    minSeconds: 180,
    maxSeconds: 300,
    safetyCapSeconds: 300,
    isWarmup: true,
  ),

  // push_horizontal — mesma escada de push_horizontal_anchor.dart (0-7).
  CatalogExercise(
    slug: 'push_up_wall',
    namePtBr: 'Flexão na parede',
    pattern: 'push_horizontal',
    setsRepsGuidance: '2 séries de 6-10 repetições',
    doseType: DoseType.reps,
    targetSets: 2,
    targetReps: 6,
    minCapabilityLevel: 0,
    maxCapabilityLevel: 1,
    mediaSlug: 'flexao_na_parede',
  ),
  CatalogExercise(
    slug: 'push_up_incline',
    namePtBr: 'Flexão inclinada (bancada/superfície alta ou similar)',
    pattern: 'push_horizontal',
    setsRepsGuidance: '3 séries de 10 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 10,
    restSeconds: 60,
    // Sem exigir Equipment.elevatedSurface: qualquer superfície firme e
    // segura serve (mesa, escada, parapeito), diferente de elástico/barra.
    minCapabilityLevel: 2,
    maxCapabilityLevel: 3,
    // Confirmado por referência cruzada: o media_key deste nó do
    // catálogo de 195 imagens cita "push_up_incline_start.png", o mesmo
    // arquivo já usado para este slug na história vertical anterior.
    mediaSlug: 'flexao_inclinada_media',
  ),
  CatalogExercise(
    slug: 'push_up_knees',
    namePtBr: 'Flexão de joelhos',
    pattern: 'push_horizontal',
    setsRepsGuidance: '2-3 séries de 6-10 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 6,
    minCapabilityLevel: 4,
    maxCapabilityLevel: 5,
    mediaSlug: 'flexao_joelhos',
  ),
  CatalogExercise(
    slug: 'push_up_floor',
    namePtBr: 'Flexão tradicional (chão)',
    pattern: 'push_horizontal',
    setsRepsGuidance: '2-4 séries de 5-10 repetições, reps em reserva',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 5,
    minCapabilityLevel: 6,
    maxCapabilityLevel: 100,
    mediaSlug: 'flexao_tradicional',
  ),

  // pull_horizontal — escada em camadas espelhando push_horizontal (0-7),
  // nomes/mediaSlug conferidos em exercise_media_catalog.json
  // (categoria puxar_horizontal_escapula).
  CatalogExercise(
    slug: 'scapular_retraction_bodyweight',
    namePtBr: 'Retração escapular assistida (sem equipamento)',
    pattern: 'pull_horizontal',
    setsRepsGuidance: '2-3 séries de 8-12 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 8,
    minCapabilityLevel: 0,
    maxCapabilityLevel: 1,
    mediaSlug: 'retracao_escapular_guiada',
  ),
  CatalogExercise(
    slug: 'band_row',
    namePtBr: 'Remada com elástico',
    pattern: 'pull_horizontal',
    setsRepsGuidance: '2-3 séries de 8-12 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 8,
    requiredEquipment: {Equipment.elasticBand},
    minCapabilityLevel: 0,
    maxCapabilityLevel: 1,
    mediaSlug: 'remada_pe_elastico',
  ),
  CatalogExercise(
    slug: 'incline_australian_row',
    namePtBr: 'Remada australiana inclinada',
    pattern: 'pull_horizontal',
    setsRepsGuidance: '3 séries de 8-12 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 8,
    minCapabilityLevel: 2,
    maxCapabilityLevel: 3,
    mediaSlug: 'remada_australiana_inclinada',
  ),
  CatalogExercise(
    slug: 'horizontal_row_straight_legs',
    namePtBr: 'Remada horizontal com pernas estendidas',
    pattern: 'pull_horizontal',
    setsRepsGuidance: '3 séries de 8-10 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 8,
    minCapabilityLevel: 4,
    maxCapabilityLevel: 5,
    mediaSlug: 'remada_horizontal_pernas_estendidas',
  ),
  CatalogExercise(
    slug: 'assisted_archer_row',
    namePtBr: 'Archer row assistida',
    pattern: 'pull_horizontal',
    setsRepsGuidance: '3 séries de 6-8 repetições por lado',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 6,
    minCapabilityLevel: 6,
    maxCapabilityLevel: 100,
    mediaSlug: 'archer_row_assistida',
  ),

  // squat — escada em camadas (0-5, ladeira mais curta que push_horizontal),
  // nomes/mediaSlug conferidos em exercise_media_catalog.json
  // (categoria agachamento_unilateral).
  CatalogExercise(
    slug: 'medium_bench_sit_to_stand',
    namePtBr: 'Sentar e levantar de banco médio',
    pattern: 'squat',
    setsRepsGuidance: '3 séries de 10-12 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 10,
    minCapabilityLevel: 0,
    maxCapabilityLevel: 1,
    mediaSlug: 'sentar_levantar_banco_medio',
  ),
  CatalogExercise(
    slug: 'assisted_squat_comfortable_range',
    namePtBr: 'Agachamento assistido em amplitude confortável',
    pattern: 'squat',
    setsRepsGuidance: '3 séries de 10-12 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 10,
    minCapabilityLevel: 2,
    maxCapabilityLevel: 3,
    mediaSlug: 'agachamento_assistido_amplitude_confortavel',
  ),
  CatalogExercise(
    slug: 'sit_to_stand_squat',
    namePtBr: 'Agachamento livre',
    pattern: 'squat',
    setsRepsGuidance: '3 séries de 12 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 12,
    restSeconds: 60,
    minCapabilityLevel: 4,
    maxCapabilityLevel: 100,
    // Confirmado por referência cruzada: o media_key deste nó cita
    // "bodyweight_squat_bottom.png", o mesmo arquivo já usado para este
    // slug na história vertical anterior.
    mediaSlug: 'agachamento_livre',
  ),

  // hinge_posterior_chain — escada em camadas (0-5), nomes/mediaSlug
  // conferidos em exercise_media_catalog.json (categoria cadeia_posterior).
  CatalogExercise(
    slug: 'glute_bridge',
    namePtBr: 'Ponte de glúteos',
    pattern: 'hinge_posterior_chain',
    setsRepsGuidance: '2-3 séries de 10-15 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 10,
    minCapabilityLevel: 0,
    maxCapabilityLevel: 1,
    mediaSlug: 'ponte_gluteos_completa',
  ),
  CatalogExercise(
    slug: 'good_morning_bodyweight',
    namePtBr: 'Good morning sem carga/elástico',
    pattern: 'hinge_posterior_chain',
    setsRepsGuidance: '3 séries de 10-12 repetições',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 10,
    minCapabilityLevel: 2,
    maxCapabilityLevel: 3,
    mediaSlug: 'good_morning_sem_carga_elastico',
  ),
  CatalogExercise(
    slug: 'unilateral_bridge',
    namePtBr: 'Ponte unilateral',
    pattern: 'hinge_posterior_chain',
    setsRepsGuidance: '3 séries de 8-10 repetições por lado',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 8,
    minCapabilityLevel: 4,
    maxCapabilityLevel: 100,
    mediaSlug: 'ponte_unilateral',
  ),

  // core_anti_extension — escada em camadas (0-7), nomes/mediaSlug
  // conferidos em exercise_media_catalog.json
  // (categoria core_anterior_compressao).
  CatalogExercise(
    slug: 'dead_bug_simplified',
    namePtBr: 'Dead bug simplificado',
    pattern: 'core_anti_extension',
    setsRepsGuidance: '2-3 séries de 8-12 repetições por lado',
    doseType: DoseType.reps,
    targetSets: 3,
    targetReps: 8,
    minCapabilityLevel: 0,
    maxCapabilityLevel: 2,
    mediaSlug: 'dead_bug_simplificado',
  ),
  CatalogExercise(
    slug: 'incline_plank',
    namePtBr: 'Prancha inclinada',
    pattern: 'core_anti_extension',
    setsRepsGuidance: '3 séries de 20-30 segundos',
    doseType: DoseType.duration,
    targetSets: 3,
    targetSeconds: 20,
    minSeconds: 10,
    maxSeconds: 40,
    safetyCapSeconds: 60,
    minCapabilityLevel: 3,
    maxCapabilityLevel: 4,
    mediaSlug: 'prancha_inclinada',
  ),
  CatalogExercise(
    slug: forearmPlankSlug,
    namePtBr: 'Prancha completa',
    pattern: 'core_anti_extension',
    setsRepsGuidance: '3 séries de 30 segundos',
    doseType: DoseType.duration,
    targetSets: 3,
    targetSeconds: 30,
    minSeconds: 10,
    maxSeconds: 60,
    safetyCapSeconds: 90,
    restSeconds: 45,
    minCapabilityLevel: 5,
    maxCapabilityLevel: 6,
    // Confirmado por referência cruzada: o media_key deste nó cita
    // "forearm_plank_hold.png", o mesmo arquivo já usado para este slug
    // na história vertical anterior.
    mediaSlug: 'prancha_completa',
  ),
  CatalogExercise(
    slug: 'hollow_tuck_hold',
    namePtBr: 'Hollow tuck hold',
    pattern: 'core_anti_extension',
    setsRepsGuidance: '3 séries de 15-20 segundos',
    doseType: DoseType.duration,
    targetSets: 3,
    targetSeconds: 15,
    minSeconds: 10,
    maxSeconds: 30,
    safetyCapSeconds: 45,
    minCapabilityLevel: 7,
    maxCapabilityLevel: 100,
    mediaSlug: 'hollow_tuck_hold',
  ),

  // Bônus — só entram quando o orçamento de tempo sobra ou o equipamento
  // permite (WEEKLY_PLAN_GENERATOR aplica os filtros).
  CatalogExercise(
    slug: 'pike_push_up',
    namePtBr: 'Flexão pike (ombro)',
    pattern: 'push_vertical',
    setsRepsGuidance: '2 séries de 5-8 repetições',
    doseType: DoseType.reps,
    targetSets: 2,
    targetReps: 5,
    // Nome/nível não são idênticos ao nó do catálogo (que distingue
    // "inclinada" de "no chão") — escolhida a variação inclinada, mais
    // conservadora, como aproximação razoável. Não confirmado por
    // referência cruzada como os slugs acima.
    mediaSlug: 'pike_push_up_inclinada',
  ),
  CatalogExercise(
    slug: 'parallel_bar_support_hold',
    namePtBr: 'Suporte estático em paralelas',
    pattern: 'support_dip',
    setsRepsGuidance: '2-3 séries de 10-20 segundos',
    doseType: DoseType.duration,
    targetSets: 3,
    targetSeconds: 10,
    minSeconds: 10,
    maxSeconds: 20,
    safetyCapSeconds: 30,
    requiredEquipment: {Equipment.parallelBars},
    // Sem associação confiável: nenhum nó de "dips_suporte" corresponde
    // com segurança a um suporte estático não assistido em paralelas
    // completas (os nós próximos são "assistido" ou já um dip dinâmico).
    // Fica com o placeholder animado até essa variação existir no
    // catálogo de imagens ou ser revisada manualmente.
  ),
  CatalogExercise(
    slug: 'wall_assisted_handstand',
    namePtBr: 'Equilíbrio com apoio na parede',
    pattern: 'hand_balance',
    setsRepsGuidance: '2-3 tentativas de 10-20 segundos',
    doseType: DoseType.duration,
    targetSets: 3,
    targetSeconds: 10,
    minSeconds: 10,
    maxSeconds: 20,
    safetyCapSeconds: 30,
    // "Handstand de costas para parede" (nível 4 de handstand) é a
    // aproximação mais próxima do apoio assistido na parede. Não
    // confirmado por referência cruzada.
    mediaSlug: 'handstand_costas_parede',
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

/// Entrada do catálogo pelo slug, ou `null` se não existir (ex.: conteúdo
/// aposentado — histórico permanece referenciável mesmo sem entrada viva).
CatalogExercise? catalogExerciseForSlug(String slug) {
  for (final exercise in exerciseCatalog) {
    if (exercise.slug == slug) return exercise;
  }
  return null;
}

/// Variação de um padrão treinada no nível de capacidade atual, ou `null`
/// se nenhuma variação cobrir esse nível (fora da escala coberta pelo
/// catálogo para este padrão).
String? exerciseForPatternAndLevel(String pattern, int level) {
  final matches = exercisesForPattern(
    pattern,
  ).where((e) => e.suitableForLevel(level));
  return matches.isEmpty ? null : matches.first.slug;
}
