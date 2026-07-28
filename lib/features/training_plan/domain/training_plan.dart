import 'exercise_catalog.dart' show DoseType;

/// Motivo de inclusão de um item, conforme os `reason_code` de
/// TRAINING_ENGINE.md §11. Só os códigos realmente produzidos pelo
/// gerador determinístico do MVP estão listados aqui.
enum PlanReasonCode {
  /// Cobre um padrão de movimento fundamental que precisa aparecer na
  /// semana (TRAINING_ENGINE.md §3).
  foundationGap,

  /// Ajuste para equilibrar fadiga/estímulo entre os dias da semana
  /// (TRAINING_ENGINE.md §4, item 5).
  weeklyBalance,

  /// A variação preferida exigia equipamento que o usuário não tem;
  /// a alternativa sem equipamento foi usada no lugar
  /// (EXERCISE_SCHEMA.md §4).
  equipmentSubstitution,
}

class PlannedExerciseItem {
  const PlannedExerciseItem({
    required this.pattern,
    required this.exerciseSlug,
    required this.namePtBr,
    required this.setsRepsGuidance,
    required this.reasonCode,
    this.doseType = DoseType.reps,
    this.targetSets = 1,
    this.targetReps,
    this.targetSeconds,
    this.restSeconds = 60,
    this.mediaSlug,
  });

  final String pattern;
  final String exerciseSlug;
  final String namePtBr;
  final String setsRepsGuidance;
  final PlanReasonCode reasonCode;

  final DoseType doseType;
  final int targetSets;
  final int? targetReps;
  final int? targetSeconds;
  final int restSeconds;

  /// Slug no catálogo de mídia estática (`exercise_catalog.dart`'s
  /// `CatalogExercise.mediaSlug`), copiado no momento em que o plano é
  /// gerado — mesma filosofia de instantâneo congelado dos demais
  /// campos aqui.
  final String? mediaSlug;

  Map<String, dynamic> toJson() => {
    'pattern': pattern,
    'exerciseSlug': exerciseSlug,
    'namePtBr': namePtBr,
    'setsRepsGuidance': setsRepsGuidance,
    'reasonCode': reasonCode.name,
    'doseType': doseType.name,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'targetSeconds': targetSeconds,
    'restSeconds': restSeconds,
    'mediaSlug': mediaSlug,
  };

  /// Tolerante a planos salvos antes da dose estruturada existir: sem
  /// `doseType`, assume `reps` com `targetReps` nulo — o player usa um
  /// alvo padrão nesse caso (ver `LogSetSheet`). Regenerar o plano
  /// ("Gerar novamente") preenche a dose estruturada real.
  factory PlannedExerciseItem.fromJson(Map<String, dynamic> json) {
    return PlannedExerciseItem(
      pattern: json['pattern'] as String,
      exerciseSlug: json['exerciseSlug'] as String,
      namePtBr: json['namePtBr'] as String,
      setsRepsGuidance: json['setsRepsGuidance'] as String,
      reasonCode: PlanReasonCode.values.byName(json['reasonCode'] as String),
      doseType: json['doseType'] == null
          ? DoseType.reps
          : DoseType.values.byName(json['doseType'] as String),
      targetSets: json['targetSets'] as int? ?? 1,
      targetReps: json['targetReps'] as int?,
      targetSeconds: json['targetSeconds'] as int?,
      restSeconds: json['restSeconds'] as int? ?? 60,
      mediaSlug: json['mediaSlug'] as String?,
    );
  }
}

class PlannedSession {
  const PlannedSession({
    required this.dayLabel,
    required this.targetMinutes,
    required this.items,
  });

  /// Ex.: "Dia A". Preferência, não data fixa (WEEKLY_TEMPLATES.md §1).
  final String dayLabel;
  final int targetMinutes;
  final List<PlannedExerciseItem> items;

  Map<String, dynamic> toJson() => {
    'dayLabel': dayLabel,
    'targetMinutes': targetMinutes,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory PlannedSession.fromJson(Map<String, dynamic> json) {
    return PlannedSession(
      dayLabel: json['dayLabel'] as String,
      targetMinutes: json['targetMinutes'] as int,
      items: (json['items'] as List)
          .map((e) => PlannedExerciseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Semana executável gerada pelo motor de treino (TRAINING_ENGINE.md §1).
class WeeklyPlan {
  const WeeklyPlan({
    required this.ruleVersion,
    required this.catalogVersion,
    required this.requestedDaysPerWeek,
    required this.actualDaysPerWeek,
    required this.minutesPerSession,
    required this.sessions,
    required this.generatedAt,
    required this.validUntil,
    this.frequencyDowngradeReason,
  });

  final String ruleVersion;
  final String catalogVersion;
  final int requestedDaysPerWeek;
  final int actualDaysPerWeek;
  final int minutesPerSession;
  final List<PlannedSession> sessions;
  final DateTime generatedAt;
  final DateTime validUntil;

  /// Preenchido quando `actualDaysPerWeek` < `requestedDaysPerWeek`
  /// (WEEKLY_TEMPLATES.md §6 — motor recusa 6 dias sem histórico
  /// suficiente e oferece 4-5 dias no lugar).
  final String? frequencyDowngradeReason;

  Map<String, dynamic> toJson() => {
    'ruleVersion': ruleVersion,
    'catalogVersion': catalogVersion,
    'requestedDaysPerWeek': requestedDaysPerWeek,
    'actualDaysPerWeek': actualDaysPerWeek,
    'minutesPerSession': minutesPerSession,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
    'validUntil': validUntil.toIso8601String(),
    'frequencyDowngradeReason': frequencyDowngradeReason,
  };

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      ruleVersion: json['ruleVersion'] as String,
      catalogVersion: json['catalogVersion'] as String,
      requestedDaysPerWeek: json['requestedDaysPerWeek'] as int,
      actualDaysPerWeek: json['actualDaysPerWeek'] as int,
      minutesPerSession: json['minutesPerSession'] as int,
      sessions: (json['sessions'] as List)
          .map((s) => PlannedSession.fromJson(s as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      frequencyDowngradeReason: json['frequencyDowngradeReason'] as String?,
    );
  }
}

/// Sessão pendente do "treino escolhido" do usuário: a primeira
/// [PlannedSession] da semana cujo `dayLabel` ainda não está em
/// [completedDayLabels]. `null` quando todas as sessões da semana já
/// foram concluídas. Usada tanto pelo card de próxima sessão da Jornada
/// quanto pela aba "Próximo treino" do plano semanal — uma única
/// resolução, para as duas telas nunca divergirem sobre qual é o
/// próximo dia.
PlannedSession? nextPendingSession(
  WeeklyPlan plan,
  Set<String> completedDayLabels,
) {
  for (final session in plan.sessions) {
    if (!completedDayLabels.contains(session.dayLabel)) return session;
  }
  return null;
}
