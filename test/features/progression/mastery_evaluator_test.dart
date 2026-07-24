import 'package:calisthenics_rpg/features/progression/domain/mastery_evaluator.dart';
import 'package:calisthenics_rpg/features/progression/domain/mastery_rules.dart';
import 'package:calisthenics_rpg/features/workout_session/domain/workout_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = MasteryEvaluator();
  const rule = MasteryRule(
    exerciseSlug: 'push_up_wall',
    minRepsPerSet: 6,
    minQualifyingSets: 2,
    confirmationsRequired: 2,
    minHoursBetweenConfirmations: 48,
  );

  SetLog set({
    required int reps,
    PerceivedEffort effort = PerceivedEffort.adequate,
    int setNumber = 1,
    DateTime? at,
  }) {
    return SetLog(
      exerciseSlug: 'push_up_wall',
      pattern: 'push_horizontal',
      setNumber: setNumber,
      repsCompleted: reps,
      perceivedEffort: effort,
      completedAt: at ?? DateTime(2026, 1, 1),
    );
  }

  test('sem sessões, não promove e não tem progresso parcial', () {
    final result = evaluator.evaluate(rule: rule, sessions: const []);
    expect(result.promoted, isFalse);
    expect(result.hasPartialProgress, isFalse);
    expect(result.qualifyingConfirmations, 0);
  });

  test('uma sessão qualificada gera progresso parcial, não promoção', () {
    final result = evaluator.evaluate(
      rule: rule,
      sessions: [
        SessionEvidence(
          completedAt: DateTime(2026, 1, 1),
          sets: [set(reps: 8), set(reps: 7, setNumber: 2)],
        ),
      ],
    );

    expect(result.qualifyingConfirmations, 1);
    expect(result.promoted, isFalse);
    expect(result.hasPartialProgress, isTrue);
  });

  test('duas sessões qualificadas com intervalo suficiente promovem', () {
    final result = evaluator.evaluate(
      rule: rule,
      sessions: [
        SessionEvidence(
          completedAt: DateTime(2026, 1, 1, 8),
          sets: [set(reps: 8), set(reps: 7, setNumber: 2)],
        ),
        SessionEvidence(
          completedAt: DateTime(2026, 1, 3, 8), // 48h depois
          sets: [set(reps: 9), set(reps: 8, setNumber: 2)],
        ),
      ],
    );

    expect(result.qualifyingConfirmations, 2);
    expect(result.promoted, isTrue);
  });

  test('segunda sessão antes do intervalo mínimo não conta como '
      'confirmação separada', () {
    final result = evaluator.evaluate(
      rule: rule,
      sessions: [
        SessionEvidence(
          completedAt: DateTime(2026, 1, 1, 8),
          sets: [set(reps: 8), set(reps: 7, setNumber: 2)],
        ),
        SessionEvidence(
          completedAt: DateTime(2026, 1, 1, 12), // 4h depois, não 48h
          sets: [set(reps: 9), set(reps: 8, setNumber: 2)],
        ),
      ],
    );

    expect(result.qualifyingConfirmations, 1);
    expect(result.promoted, isFalse);
  });

  test('série com dor desqualifica a sessão inteira, mesmo com boas reps',
      () {
    final result = evaluator.evaluate(
      rule: rule,
      sessions: [
        SessionEvidence(
          completedAt: DateTime(2026, 1, 1),
          sets: [
            set(reps: 8),
            set(reps: 7, setNumber: 2, effort: PerceivedEffort.pain),
          ],
        ),
      ],
    );

    expect(result.qualifyingConfirmations, 0);
    expect(result.hasPartialProgress, isFalse);
  });

  test('reps abaixo do mínimo não contam como série qualificada', () {
    final result = evaluator.evaluate(
      rule: rule,
      sessions: [
        SessionEvidence(
          completedAt: DateTime(2026, 1, 1),
          sets: [set(reps: 3), set(reps: 4, setNumber: 2)],
        ),
      ],
    );

    expect(result.qualifyingConfirmations, 0);
  });

  test('esforço "não completei" não conta mesmo com reps suficientes', () {
    final result = evaluator.evaluate(
      rule: rule,
      sessions: [
        SessionEvidence(
          completedAt: DateTime(2026, 1, 1),
          sets: [
            set(reps: 8, effort: PerceivedEffort.notCompleted),
            set(reps: 7, setNumber: 2, effort: PerceivedEffort.notCompleted),
          ],
        ),
      ],
    );

    expect(result.qualifyingConfirmations, 0);
  });
}
