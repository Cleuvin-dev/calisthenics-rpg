import 'package:calisthenics_rpg/features/missions/domain/mission.dart';
import 'package:calisthenics_rpg/features/missions/domain/mission_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = MissionEvaluator();

  group('evaluateDaily', () {
    test('nenhuma atividade: nenhuma missão concluída', () {
      final results = evaluator.evaluateDaily(
        const DailyMissionFacts(
          loggedExerciseSlugs: {},
          completedSessionCount: 0,
          warmupExerciseSlug: 'warmup_joint_mobility',
        ),
      );

      expect(results.length, dailyMissionDefinitions.length);
      expect(results.every((r) => !r.completed), isTrue);
    });

    test('aquecimento logado conclui só a missão de aquecimento', () {
      final results = evaluator.evaluateDaily(
        const DailyMissionFacts(
          loggedExerciseSlugs: {'warmup_joint_mobility'},
          completedSessionCount: 0,
          warmupExerciseSlug: 'warmup_joint_mobility',
        ),
      );

      final warmup = results.firstWhere(
        (r) => r.definition.type == MissionType.completeWarmup,
      );
      final logAny = results.firstWhere(
        (r) => r.definition.type == MissionType.logAnySet,
      );
      expect(warmup.completed, isTrue);
      expect(logAny.completed, isTrue); // logar qualquer série já conta
      expect(
        results
            .firstWhere((r) => r.definition.type == MissionType.completeSession)
            .completed,
        isFalse,
      );
    });

    test('sessão concluída marca a missão correspondente', () {
      final results = evaluator.evaluateDaily(
        const DailyMissionFacts(
          loggedExerciseSlugs: {},
          completedSessionCount: 1,
          warmupExerciseSlug: 'warmup_joint_mobility',
        ),
      );

      expect(
        results
            .firstWhere((r) => r.definition.type == MissionType.completeSession)
            .completed,
        isTrue,
      );
    });
  });

  group('evaluateWeekly', () {
    test('frequência cumprida quando sessões >= necessário', () {
      final results = evaluator.evaluateWeekly(
        const WeeklyMissionFacts(
          completedSessionCount: 3,
          requiredSessionCount: 3,
          plannedPatterns: {},
          trainedPatterns: {},
          masteryConfirmedThisWeek: false,
        ),
      );

      final frequency = results.firstWhere(
        (r) => r.definition.type == MissionType.weeklyFrequency,
      );
      expect(frequency.completed, isTrue);
      expect(frequency.progressLabel, '3/3 sessões');
    });

    test('frequência não cumprida quando faltam sessões', () {
      final results = evaluator.evaluateWeekly(
        const WeeklyMissionFacts(
          completedSessionCount: 1,
          requiredSessionCount: 3,
          plannedPatterns: {},
          trainedPatterns: {},
          masteryConfirmedThisWeek: false,
        ),
      );

      expect(
        results
            .firstWhere((r) => r.definition.type == MissionType.weeklyFrequency)
            .completed,
        isFalse,
      );
    });

    test('treinar todos os padrões exige cobertura completa', () {
      final partial = evaluator.evaluateWeekly(
        const WeeklyMissionFacts(
          completedSessionCount: 0,
          requiredSessionCount: 0,
          plannedPatterns: {'push_horizontal', 'squat'},
          trainedPatterns: {'push_horizontal'},
          masteryConfirmedThisWeek: false,
        ),
      );
      final partialResult = partial.firstWhere(
        (r) => r.definition.type == MissionType.trainAllPatterns,
      );
      expect(partialResult.completed, isFalse);
      expect(partialResult.progressLabel, '1/2 padrões');

      final full = evaluator.evaluateWeekly(
        const WeeklyMissionFacts(
          completedSessionCount: 0,
          requiredSessionCount: 0,
          plannedPatterns: {'push_horizontal', 'squat'},
          trainedPatterns: {'push_horizontal', 'squat', 'pull_horizontal'},
          masteryConfirmedThisWeek: false,
        ),
      );
      expect(
        full
            .firstWhere((r) => r.definition.type == MissionType.trainAllPatterns)
            .completed,
        isTrue,
      );
    });

    test('sem padrões planejados, missão não é considerada cumprida', () {
      final results = evaluator.evaluateWeekly(
        const WeeklyMissionFacts(
          completedSessionCount: 0,
          requiredSessionCount: 0,
          plannedPatterns: {},
          trainedPatterns: {},
          masteryConfirmedThisWeek: false,
        ),
      );
      expect(
        results
            .firstWhere((r) => r.definition.type == MissionType.trainAllPatterns)
            .completed,
        isFalse,
      );
    });

    test('confirmar domínio reflete diretamente o fato', () {
      final results = evaluator.evaluateWeekly(
        const WeeklyMissionFacts(
          completedSessionCount: 0,
          requiredSessionCount: 0,
          plannedPatterns: {},
          trainedPatterns: {},
          masteryConfirmedThisWeek: true,
        ),
      );
      expect(
        results
            .firstWhere((r) => r.definition.type == MissionType.confirmMastery)
            .completed,
        isTrue,
      );
    });
  });
}
