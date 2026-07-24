import '../../training_plan/domain/exercise_catalog.dart' show DoseType;

/// Estados de uma sessão de treino (REQUIREMENTS.md FR-026: "diferenciar
/// sessão iniciada, pausada, abandonada e concluída").
enum WorkoutSessionStatus { inProgress, paused, abandoned, completed }

/// Motivo de conclusão de uma série por tempo
/// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §12.1/§20).
enum TimedSetCompletionReason { targetReached, userStopped, pain }

/// Percepção da série, conforme REQUIREMENTS.md FR-022 e o ajuste
/// pós-série de TRAINING_ENGINE.md §8. Substitui uma escala numérica de
/// RPE/RIR por categorias diretas, mais simples de registrar em campo.
enum PerceivedEffort { tooEasy, adequate, hardCompleted, notCompleted, pain }

extension PerceivedEffortLabel on PerceivedEffort {
  String get labelPtBr {
    switch (this) {
      case PerceivedEffort.tooEasy:
        return 'Muito fácil';
      case PerceivedEffort.adequate:
        return 'Adequado';
      case PerceivedEffort.hardCompleted:
        return 'Difícil, concluí';
      case PerceivedEffort.notCompleted:
        return 'Não completei';
      case PerceivedEffort.pain:
        return 'Dor';
    }
  }
}

/// Item de treino congelado no início da sessão (cópia do
/// `PlannedExerciseItem` do plano ativo naquele momento). Regenerar o
/// plano depois não deve alterar uma sessão já iniciada
/// (TRAINING_ENGINE.md §10).
class WorkoutSessionItem {
  const WorkoutSessionItem({
    required this.pattern,
    required this.exerciseSlug,
    required this.namePtBr,
    required this.setsRepsGuidance,
    this.doseType = DoseType.reps,
    this.targetSets = 1,
    this.targetReps,
    this.targetSeconds,
    this.restSeconds = 60,
  });

  final String pattern;
  final String exerciseSlug;
  final String namePtBr;
  final String setsRepsGuidance;

  final DoseType doseType;
  final int targetSets;
  final int? targetReps;
  final int? targetSeconds;
  final int restSeconds;

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        'exerciseSlug': exerciseSlug,
        'namePtBr': namePtBr,
        'setsRepsGuidance': setsRepsGuidance,
        'doseType': doseType.name,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetSeconds': targetSeconds,
        'restSeconds': restSeconds,
      };

  /// Tolerante a sessões congeladas antes da dose estruturada existir —
  /// mesma filosofia de `PlannedExerciseItem.fromJson`.
  factory WorkoutSessionItem.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionItem(
      pattern: json['pattern'] as String,
      exerciseSlug: json['exerciseSlug'] as String,
      namePtBr: json['namePtBr'] as String,
      setsRepsGuidance: json['setsRepsGuidance'] as String,
      doseType: json['doseType'] == null
          ? DoseType.reps
          : DoseType.values.byName(json['doseType'] as String),
      targetSets: json['targetSets'] as int? ?? 1,
      targetReps: json['targetReps'] as int?,
      targetSeconds: json['targetSeconds'] as int?,
      restSeconds: json['restSeconds'] as int? ?? 60,
    );
  }
}

class SetLog {
  const SetLog({
    required this.exerciseSlug,
    required this.pattern,
    required this.setNumber,
    required this.repsCompleted,
    required this.perceivedEffort,
    required this.completedAt,
  });

  final String exerciseSlug;
  final String pattern;
  final int setNumber;
  final int repsCompleted;
  final PerceivedEffort perceivedEffort;
  final DateTime completedAt;
}
