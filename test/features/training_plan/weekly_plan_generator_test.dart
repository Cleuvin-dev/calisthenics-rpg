import 'package:calisthenics_rpg/features/onboarding/domain/training_preferences.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/training_plan.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/weekly_plan_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const generator = WeeklyPlanGenerator();
  final now = DateTime(2026, 7, 24);

  TrainingPreferences prefs({
    required int daysPerWeek,
    required int minutesPerSession,
    Set<Equipment> equipment = const {},
  }) {
    return TrainingPreferences(
      daysPerWeek: daysPerWeek,
      minutesPerSession: minutesPerSession,
      location: TrainingLocation.home,
      equipment: equipment,
    );
  }

  test('gera uma sessão por dia solicitado dentro do suportado', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 3, minutesPerSession: 30),
      capabilityLevelsByPattern: const {'push_horizontal': 0},
      now: now,
    );

    expect(plan.requestedDaysPerWeek, 3);
    expect(plan.actualDaysPerWeek, 3);
    expect(plan.sessions.length, 3);
    expect(plan.frequencyDowngradeReason, isNull);
    expect(plan.ruleVersion, weeklyPlanGeneratorRuleVersion);
  });

  test('reduz pedido de 6 dias para 5 e explica o motivo', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 6, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': 3},
      now: now,
    );

    expect(plan.requestedDaysPerWeek, 6);
    expect(plan.actualDaysPerWeek, 5);
    expect(plan.sessions.length, 5);
    expect(plan.frequencyDowngradeReason, isNotNull);
  });

  test('toda sessão começa com o aquecimento', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 15),
      capabilityLevelsByPattern: const {'push_horizontal': null},
      now: now,
    );

    for (final session in plan.sessions) {
      expect(session.items.first.exerciseSlug, 'warmup_joint_mobility');
    }
  });

  test('sessão curta (15 min) respeita o orçamento de exercícios', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 15),
      capabilityLevelsByPattern: const {'push_horizontal': 0},
      now: now,
    );

    // 1 aquecimento + até 3 exercícios (WEEKLY_TEMPLATES.md §7).
    for (final session in plan.sessions) {
      expect(session.items.length, lessThanOrEqualTo(4));
    }
  });

  test('sessão longa (75 min) inclui mais itens que uma curta', () {
    final shortPlan = generator.generate(
      preferences: prefs(daysPerWeek: 3, minutesPerSession: 15),
      capabilityLevelsByPattern: const {'push_horizontal': 0},
      now: now,
    );
    final longPlan = generator.generate(
      preferences: prefs(daysPerWeek: 3, minutesPerSession: 75),
      capabilityLevelsByPattern: const {'push_horizontal': 0},
      now: now,
    );

    expect(
      longPlan.sessions.first.items.length,
      greaterThan(shortPlan.sessions.first.items.length),
    );
  });

  test('sem capacidade avaliada, usa a variação mais conservadora de push', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': null},
      now: now,
    );

    final pushItem = plan.sessions.first.items.firstWhere(
      (i) => i.pattern == 'push_horizontal',
    );
    expect(pushItem.exerciseSlug, 'push_up_wall');
  });

  test('nível de push_horizontal alto escolhe a variação avançada', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': 7},
      now: now,
    );

    final pushItem = plan.sessions.first.items.firstWhere(
      (i) => i.pattern == 'push_horizontal',
    );
    expect(pushItem.exerciseSlug, 'push_up_floor');
  });

  test('sem elástico disponível, puxada usa a variação sem equipamento '
      'com motivo de substituição', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': 0},
      now: now,
    );

    final pullItem = plan.sessions.first.items.firstWhere(
      (i) => i.pattern == 'pull_horizontal',
    );
    expect(pullItem.exerciseSlug, 'scapular_retraction_bodyweight');
    expect(pullItem.reasonCode, PlanReasonCode.equipmentSubstitution);
  });

  test('com elástico disponível, puxada usa a variação com elástico', () {
    final plan = generator.generate(
      preferences: prefs(
        daysPerWeek: 2,
        minutesPerSession: 45,
        equipment: {Equipment.elasticBand},
      ),
      capabilityLevelsByPattern: const {'push_horizontal': 0},
      now: now,
    );

    final pullItem = plan.sessions.first.items.firstWhere(
      (i) => i.pattern == 'pull_horizontal',
    );
    expect(pullItem.exerciseSlug, 'band_row');
    expect(pullItem.reasonCode, isNot(PlanReasonCode.equipmentSubstitution));
  });

  test('serialização JSON preserva os dados do plano (round-trip)', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 4, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': 5},
      now: now,
    );

    final decoded = WeeklyPlan.fromJson(plan.toJson());

    expect(decoded.actualDaysPerWeek, plan.actualDaysPerWeek);
    expect(decoded.sessions.length, plan.sessions.length);
    expect(
      decoded.sessions.first.items.first.exerciseSlug,
      plan.sessions.first.items.first.exerciseSlug,
    );
    expect(decoded.generatedAt, plan.generatedAt);
    expect(decoded.validUntil, plan.validUntil);
  });

  test('nível baixo de squat usa a variação iniciante, nível alto usa a '
      'variação livre', () {
    final lowPlan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': 0, 'squat': 0},
      now: now,
    );
    final highPlan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': 0, 'squat': 5},
      now: now,
    );

    final lowSquat = lowPlan.sessions.first.items.firstWhere(
      (i) => i.pattern == 'squat',
    );
    final highSquat = highPlan.sessions.first.items.firstWhere(
      (i) => i.pattern == 'squat',
    );
    expect(lowSquat.exerciseSlug, 'medium_bench_sit_to_stand');
    expect(highSquat.exerciseSlug, 'sit_to_stand_squat');
  });

  test('padrão ausente do mapa usa a variação mais conservadora, igual a '
      'nível 0', () {
    final plan = generator.generate(
      preferences: prefs(daysPerWeek: 2, minutesPerSession: 45),
      capabilityLevelsByPattern: const {'push_horizontal': 0},
      now: now,
    );

    final hingeItem = plan.sessions
        .expand((s) => s.items)
        .firstWhere((i) => i.pattern == 'hinge_posterior_chain');
    expect(hingeItem.exerciseSlug, 'glute_bridge');
  });
}
