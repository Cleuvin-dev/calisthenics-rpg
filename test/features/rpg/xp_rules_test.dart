import 'package:calisthenics_rpg/features/rpg/domain/xp_events.dart';
import 'package:calisthenics_rpg/features/rpg/domain/xp_rules.dart';
import 'package:calisthenics_rpg/features/workout_session/domain/workout_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = [
    WorkoutSessionItem(
      pattern: 'push_horizontal',
      exerciseSlug: 'push_up_wall',
      namePtBr: 'Flexão na parede',
      setsRepsGuidance: '2 séries de 6-10 repetições',
    ),
    WorkoutSessionItem(
      pattern: 'squat',
      exerciseSlug: 'sit_to_stand_squat',
      namePtBr: 'Agachamento livre',
      setsRepsGuidance: '2-3 séries de 8-15 repetições',
    ),
  ];

  test('sessão concluída sempre concede o crédito base', () {
    final awards = awardsForCompletedSession(
      workoutSessionId: 1,
      items: items,
      loggedExerciseSlugs: {},
    );

    expect(awards.length, 1);
    expect(awards.single.eventType, XpEventType.sessionCompleted);
    expect(awards.single.amount, sessionCompletedXp);
    expect(awards.single.repeatable, isTrue);
  });

  test('bônus de todas as séries só aparece quando todo item foi logado', () {
    final partialAwards = awardsForCompletedSession(
      workoutSessionId: 1,
      items: items,
      loggedExerciseSlugs: {'push_up_wall'},
    );
    expect(
      partialAwards.any((a) => a.eventType == XpEventType.allSetsLogged),
      isFalse,
    );

    final fullAwards = awardsForCompletedSession(
      workoutSessionId: 1,
      items: items,
      loggedExerciseSlugs: {'push_up_wall', 'sit_to_stand_squat'},
    );
    final bonus = fullAwards.firstWhere(
      (a) => a.eventType == XpEventType.allSetsLogged,
    );
    expect(bonus.amount, allSetsLoggedBonusXp);
    expect(bonus.repeatable, isTrue);
  });

  test('crédito de domínio só aparece quando há promoções', () {
    final withoutPromotion = awardsForCompletedSession(
      workoutSessionId: 1,
      items: items,
      loggedExerciseSlugs: {},
    );
    expect(
      withoutPromotion.any((a) => a.eventType == XpEventType.masteryConfirmed),
      isFalse,
    );

    final withPromotion = awardsForCompletedSession(
      workoutSessionId: 1,
      items: items,
      loggedExerciseSlugs: {},
      masteryPromotions: const {'push_horizontal': 1},
    );
    final masteryAward = withPromotion.firstWhere(
      (a) => a.eventType == XpEventType.masteryConfirmed,
    );
    expect(masteryAward.amount, masteryConfirmedXp);
    expect(masteryAward.repeatable, isFalse);
    expect(masteryAward.idempotencyKey, 'mastery-push_horizontal-level-1');
  });

  test('duas promoções na mesma sessão geram um crédito de domínio cada', () {
    final awards = awardsForCompletedSession(
      workoutSessionId: 1,
      items: items,
      loggedExerciseSlugs: {},
      masteryPromotions: const {'push_horizontal': 1, 'squat': 1},
    );

    final masteryAwards = awards
        .where((a) => a.eventType == XpEventType.masteryConfirmed)
        .toList();
    expect(masteryAwards.length, 2);
    expect(
      masteryAwards.map((a) => a.idempotencyKey),
      containsAll(['mastery-push_horizontal-level-1', 'mastery-squat-level-1']),
    );
  });

  test('idempotencyKey de sessão/bônus é estável por sessão', () {
    final awards = awardsForCompletedSession(
      workoutSessionId: 42,
      items: items,
      loggedExerciseSlugs: {'push_up_wall', 'sit_to_stand_squat'},
    );

    expect(
      awards.map((a) => a.idempotencyKey),
      containsAll(['session-completed-42', 'all-sets-logged-42']),
    );
  });
}
