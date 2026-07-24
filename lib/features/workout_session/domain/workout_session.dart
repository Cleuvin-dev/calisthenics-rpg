/// Estados de uma sessão de treino (REQUIREMENTS.md FR-026: "diferenciar
/// sessão iniciada, pausada, abandonada e concluída").
enum WorkoutSessionStatus { inProgress, paused, abandoned, completed }

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
  });

  final String pattern;
  final String exerciseSlug;
  final String namePtBr;
  final String setsRepsGuidance;

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        'exerciseSlug': exerciseSlug,
        'namePtBr': namePtBr,
        'setsRepsGuidance': setsRepsGuidance,
      };

  factory WorkoutSessionItem.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionItem(
      pattern: json['pattern'] as String,
      exerciseSlug: json['exerciseSlug'] as String,
      namePtBr: json['namePtBr'] as String,
      setsRepsGuidance: json['setsRepsGuidance'] as String,
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
