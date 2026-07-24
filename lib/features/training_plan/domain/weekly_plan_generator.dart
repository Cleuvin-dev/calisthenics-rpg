import '../../onboarding/domain/training_preferences.dart';
import 'exercise_catalog.dart';
import 'training_plan.dart';

/// Versão da regra determinística de geração de plano. Muda sempre que o
/// algoritmo, os templates ou o orçamento por duração forem revisados.
const weeklyPlanGeneratorRuleVersion = 'weekly-plan-v1';

/// Nível de capacidade mais conservador possível (SCORING_AND_PLACEMENT.md
/// §4 "não avaliado"), usado para todo padrão sem colocação própria ainda.
const _unassessedCapabilityLevel = 0;

/// Template de um dia: padrões em ordem de prioridade
/// (TRAINING_ENGINE.md §4). Os primeiros [requiredSlots] são obrigatórios;
/// o restante só entra se o orçamento de tempo sobrar.
class _DayTemplate {
  const _DayTemplate(this.label, this.patterns, this.requiredSlots);

  final String label;
  final List<String> patterns;
  final int requiredSlots;
}

/// Gera uma semana executável a partir de preferências e capacidade
/// conhecida, seguindo o algoritmo simplificado de TRAINING_ENGINE.md §7.
///
/// Regra determinística versionada do MVP: catálogo mínimo
/// ([exerciseCatalogVersion]), sem histórico de adesão/prontidão ainda
/// (essas entradas de TRAINING_ENGINE.md §2 ficam para quando houver
/// sessões executadas registradas).
class WeeklyPlanGenerator {
  const WeeklyPlanGenerator();

  WeeklyPlan generate({
    required TrainingPreferences preferences,
    required int? pushHorizontalCapabilityLevel,
    required DateTime now,
  }) {
    final requestedDays = preferences.daysPerWeek;
    final template = _templateFor(requestedDays);
    final actualDays = template.length;

    final capabilityLevel =
        pushHorizontalCapabilityLevel ?? _unassessedCapabilityLevel;
    final budget = _exerciseBudget(preferences.minutesPerSession);

    final sessions = template
        .map(
          (day) => _buildSession(
            day: day,
            minutesPerSession: preferences.minutesPerSession,
            budget: budget,
            capabilityLevel: capabilityLevel,
            availableEquipment: preferences.equipment,
          ),
        )
        .toList();

    return WeeklyPlan(
      ruleVersion: weeklyPlanGeneratorRuleVersion,
      catalogVersion: exerciseCatalogVersion,
      requestedDaysPerWeek: requestedDays,
      actualDaysPerWeek: actualDays,
      minutesPerSession: preferences.minutesPerSession,
      sessions: sessions,
      generatedAt: now,
      // Sem mesociclo/adesão modelados ainda: revalidar em 14 dias ou
      // quando preferências/capacidade mudarem, o que ocorrer primeiro.
      validUntil: now.add(const Duration(days: 14)),
      frequencyDowngradeReason: requestedDays > actualDays
          ? 'Sem histórico suficiente para sustentar $requestedDays dias '
              'por semana ainda (WEEKLY_TEMPLATES.md §6); plano reduzido '
              'para $actualDays dias.'
          : null,
    );
  }

  PlannedSession _buildSession({
    required _DayTemplate day,
    required int minutesPerSession,
    required int budget,
    required int capabilityLevel,
    required Set<Equipment> availableEquipment,
  }) {
    final items = <PlannedExerciseItem>[];

    final warmup = exercisesForPattern('mobility_specific')
        .firstWhere((e) => e.isWarmup);
    items.add(_toItem(warmup, PlanReasonCode.foundationGap));

    var slotsFilled = 0;
    for (var i = 0; i < day.patterns.length && slotsFilled < budget; i++) {
      final pattern = day.patterns[i];
      final chosen = _pickExercise(
        pattern: pattern,
        capabilityLevel: capabilityLevel,
        availableEquipment: availableEquipment,
      );
      if (chosen == null) continue;

      final isRequired = i < day.requiredSlots;
      items.add(_toItem(
        chosen.exercise,
        isRequired ? PlanReasonCode.foundationGap : PlanReasonCode.weeklyBalance,
        equipmentSubstituted: chosen.substituted,
      ));
      slotsFilled++;
    }

    return PlannedSession(
      dayLabel: day.label,
      targetMinutes: minutesPerSession,
      items: items,
    );
  }

  PlannedExerciseItem _toItem(
    CatalogExercise exercise,
    PlanReasonCode reasonCode, {
    bool equipmentSubstituted = false,
  }) {
    return PlannedExerciseItem(
      pattern: exercise.pattern,
      exerciseSlug: exercise.slug,
      namePtBr: exercise.namePtBr,
      setsRepsGuidance: exercise.setsRepsGuidance,
      reasonCode: equipmentSubstituted
          ? PlanReasonCode.equipmentSubstitution
          : reasonCode,
    );
  }

  /// Escolhe a melhor variação disponível para o padrão: entre as
  /// compatíveis com nível e equipamento, prefere a que exige mais
  /// equipamento específico (estímulo mais rico quando o usuário tem
  /// o recurso); cai para a variação sem equipamento quando necessário
  /// (EXERCISE_SCHEMA.md §4 — critérios de substituição).
  _PickedExercise? _pickExercise({
    required String pattern,
    required int capabilityLevel,
    required Set<Equipment> availableEquipment,
  }) {
    final candidates = exercisesForPattern(pattern)
        .where((e) => e.suitableForLevel(capabilityLevel))
        .toList()
      ..sort(
        (a, b) => b.requiredEquipment.length.compareTo(
          a.requiredEquipment.length,
        ),
      );

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      if (candidate.availableWithEquipment(availableEquipment)) {
        // Índice > 0 significa que uma variação mais específica existia
        // mas não pôde ser usada por falta de equipamento (substituição).
        return _PickedExercise(candidate, i > 0);
      }
    }
    return null;
  }

  /// Quantidade de itens não-aquecimento por sessão, conforme
  /// WEEKLY_TEMPLATES.md §7.
  int _exerciseBudget(int minutesPerSession) {
    if (minutesPerSession <= 20) return 3;
    if (minutesPerSession <= 35) return 4;
    if (minutesPerSession <= 65) return 6;
    return 8;
  }

  /// Templates por frequência semanal (WEEKLY_TEMPLATES.md §2-6). Pedidos
  /// de 6 dias caem para o template de 5 (§6): o motor ainda não modela
  /// histórico/recuperação suficiente para validar 6 dias.
  List<_DayTemplate> _templateFor(int requestedDaysPerWeek) {
    switch (requestedDaysPerWeek) {
      case 2:
        return const [
          _DayTemplate('Full Body A', [
            'push_horizontal',
            'pull_horizontal',
            'squat',
            'core_anti_extension',
          ], 4),
          _DayTemplate('Full Body B', [
            'pull_horizontal',
            'hinge_posterior_chain',
            'push_horizontal',
            'core_anti_extension',
          ], 4),
        ];
      case 3:
        return const [
          _DayTemplate('Full Body A', [
            'push_horizontal',
            'squat',
            'core_anti_extension',
            'pull_horizontal',
          ], 4),
          _DayTemplate('Full Body B', [
            'pull_horizontal',
            'hinge_posterior_chain',
            'push_horizontal',
            'core_anti_extension',
          ], 4),
          _DayTemplate('Full Body C', [
            'squat',
            'pull_horizontal',
            'push_horizontal',
            'core_anti_extension',
            'hand_balance',
          ], 4),
        ];
      case 4:
        return const [
          _DayTemplate('Superior A', [
            'push_horizontal',
            'pull_horizontal',
            'core_anti_extension',
            'push_vertical',
          ], 3),
          _DayTemplate('Inferior A', [
            'squat',
            'hinge_posterior_chain',
            'core_anti_extension',
          ], 3),
          _DayTemplate('Superior B', [
            'pull_horizontal',
            'push_horizontal',
            'support_dip',
          ], 3),
          _DayTemplate('Inferior B', [
            'hinge_posterior_chain',
            'squat',
            'hand_balance',
          ], 3),
        ];
      case 5:
      case 6:
        return const [
          _DayTemplate('Push', [
            'push_horizontal',
            'push_vertical',
            'core_anti_extension',
          ], 2),
          _DayTemplate('Pull', [
            'pull_horizontal',
            'core_anti_extension',
          ], 2),
          _DayTemplate('Legs', [
            'squat',
            'hinge_posterior_chain',
          ], 2),
          _DayTemplate('Skills + Core', [
            'core_anti_extension',
            'hand_balance',
            'support_dip',
          ], 2),
          _DayTemplate('Full Body', [
            'push_horizontal',
            'pull_horizontal',
            'squat',
            'hinge_posterior_chain',
            'core_anti_extension',
          ], 4),
        ];
      default:
        // 2 é o mínimo de REQUIREMENTS.md FR-015; qualquer valor abaixo
        // (não deveria ocorrer, onboarding já restringe 2..6) usa o
        // template de 2 dias como piso seguro.
        return _templateFor(2);
    }
  }
}

class _PickedExercise {
  const _PickedExercise(this.exercise, this.substituted);

  final CatalogExercise exercise;
  final bool substituted;
}
