import 'mission.dart';

class DailyMissionFacts {
  const DailyMissionFacts({
    required this.loggedExerciseSlugs,
    required this.completedSessionCount,
    required this.warmupExerciseSlug,
  });

  final Set<String> loggedExerciseSlugs;
  final int completedSessionCount;
  final String warmupExerciseSlug;
}

class WeeklyMissionFacts {
  const WeeklyMissionFacts({
    required this.completedSessionCount,
    required this.requiredSessionCount,
    required this.plannedPatterns,
    required this.trainedPatterns,
    required this.masteryConfirmedThisWeek,
  });

  final int completedSessionCount;
  final int requiredSessionCount;
  final Set<String> plannedPatterns;
  final Set<String> trainedPatterns;
  final bool masteryConfirmedThisWeek;
}

/// Avalia missões a partir de fatos já coletados — puro, sem banco.
class MissionEvaluator {
  const MissionEvaluator();

  List<MissionEvaluationResult> evaluateDaily(DailyMissionFacts facts) {
    return dailyMissionDefinitions.map((definition) {
      final completed = switch (definition.type) {
        MissionType.completeWarmup =>
          facts.loggedExerciseSlugs.contains(facts.warmupExerciseSlug),
        MissionType.logAnySet => facts.loggedExerciseSlugs.isNotEmpty,
        MissionType.completeSession => facts.completedSessionCount > 0,
        _ => false,
      };
      return MissionEvaluationResult(definition: definition, completed: completed);
    }).toList();
  }

  List<MissionEvaluationResult> evaluateWeekly(WeeklyMissionFacts facts) {
    return weeklyMissionDefinitions.map((definition) {
      switch (definition.type) {
        case MissionType.weeklyFrequency:
          return MissionEvaluationResult(
            definition: definition,
            completed:
                facts.completedSessionCount >= facts.requiredSessionCount,
            progressLabel:
                '${facts.completedSessionCount}/${facts.requiredSessionCount} sessões',
          );
        case MissionType.trainAllPatterns:
          final trainedCount =
              facts.trainedPatterns.intersection(facts.plannedPatterns).length;
          return MissionEvaluationResult(
            definition: definition,
            completed: facts.plannedPatterns.isNotEmpty &&
                facts.plannedPatterns.every(facts.trainedPatterns.contains),
            progressLabel: '$trainedCount/${facts.plannedPatterns.length} padrões',
          );
        case MissionType.confirmMastery:
          return MissionEvaluationResult(
            definition: definition,
            completed: facts.masteryConfirmedThisWeek,
          );
        default:
          return MissionEvaluationResult(definition: definition, completed: false);
      }
    }).toList();
  }
}
