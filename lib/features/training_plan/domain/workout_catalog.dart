import '../../onboarding/domain/training_preferences.dart';
import 'exercise_catalog.dart';

/// Catálogo de treinos nomeados e navegáveis
/// (SCREENS_AND_FLOWS.md §2 "Treino: catálogo visual de treinos com
/// filtros por nível"; VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md §7-8).
///
/// Aditivo e independente do `WeeklyPlanGenerator`: aquele gera uma
/// semana a partir da capacidade avaliada do usuário; este é uma lista de
/// treinos fixos e curados que o usuário escolhe diretamente, útil para
/// descoberta rápida e para esta história vertical do player (decisão
/// registrada no plano — ver `docs/PROJECT_STATUS.md`).
const workoutCatalogVersion = 'workout-catalog-v1';

enum WorkoutLevel { beginner, intermediate, advanced }

extension WorkoutLevelLabel on WorkoutLevel {
  String get labelPtBr {
    switch (this) {
      case WorkoutLevel.beginner:
        return 'Iniciante';
      case WorkoutLevel.intermediate:
        return 'Intermediário';
      case WorkoutLevel.advanced:
        return 'Avançado';
    }
  }
}

class Workout {
  const Workout({
    required this.slug,
    required this.namePtBr,
    required this.objectivePtBr,
    required this.level,
    required this.estimatedMinutes,
    required this.equipment,
    required this.safetyNoticePtBr,
    required this.exerciseSlugs,
  });

  final String slug;
  final String namePtBr;
  final String objectivePtBr;
  final WorkoutLevel level;
  final int estimatedMinutes;
  final Set<Equipment> equipment;
  final String safetyNoticePtBr;

  /// Ordem de execução (inclui aquecimento quando aplicável). A dose de
  /// cada exercício vem do catálogo (`CatalogExercise`) — este treino não
  /// duplica números, só ordena entradas já existentes.
  final List<String> exerciseSlugs;

  List<CatalogExercise> get exercises => exerciseSlugs
      .map(catalogExerciseForSlug)
      .whereType<CatalogExercise>()
      .toList();
}

const List<Workout> workoutCatalog = [
  Workout(
    slug: 'treino_a_fundacao',
    namePtBr: 'Treino A · Fundação',
    objectivePtBr: 'Fundamentos de empurrar, agachar e core.',
    level: WorkoutLevel.beginner,
    estimatedMinutes: 25,
    equipment: {},
    safetyNoticePtBr: 'Pare a qualquer momento se sentir dor. Prefira '
        'reduzir a amplitude ou trocar de variação a forçar a técnica.',
    exerciseSlugs: [
      warmupExerciseSlug,
      'push_up_incline',
      'sit_to_stand_squat',
      forearmPlankSlug,
    ],
  ),
];

Workout? workoutForSlug(String slug) {
  for (final workout in workoutCatalog) {
    if (workout.slug == slug) return workout;
  }
  return null;
}
