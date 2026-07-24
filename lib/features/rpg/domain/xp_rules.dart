import '../../workout_session/domain/workout_session.dart';
import 'xp_events.dart';

/// Versão da regra de concessão de XP. Muda sempre que os valores base
/// ou os critérios de elegibilidade forem revisados.
const xpRuleVersion = 'xp-rules-v1';

/// Valores base de RPG_SYSTEM.md §2 — configuráveis, tetos evitam
/// farming (mesma seção).
const sessionCompletedXp = 40;
const allSetsLoggedBonusXp = 10;
const masteryConfirmedXp = 80;

/// Teto diário de XP proveniente de eventos repetíveis
/// (ECONOMY_AND_ANTI_ABUSE.md §3). Domínio confirmado não conta aqui —
/// já é limitado pela própria natureza de só acontecer uma vez por nó.
const dailyRepeatableXpCap = 200;

/// Decide os créditos de XP de uma sessão concluída. Pura e testável:
/// não sabe nada sobre banco, só sobre os fatos da sessão.
List<XpAward> awardsForCompletedSession({
  required int workoutSessionId,
  required List<WorkoutSessionItem> items,
  required Set<String> loggedExerciseSlugs,
  required bool masteryPromoted,
  String? masteryPattern,
  int? masteryNewLevel,
}) {
  final awards = <XpAward>[
    XpAward(
      eventType: XpEventType.sessionCompleted,
      amount: sessionCompletedXp,
      sourceId: '$workoutSessionId',
      idempotencyKey: 'session-completed-$workoutSessionId',
      repeatable: true,
    ),
  ];

  final allItemsLogged = items.isNotEmpty &&
      items.every((item) => loggedExerciseSlugs.contains(item.exerciseSlug));
  if (allItemsLogged) {
    awards.add(
      XpAward(
        eventType: XpEventType.allSetsLogged,
        amount: allSetsLoggedBonusXp,
        sourceId: '$workoutSessionId',
        idempotencyKey: 'all-sets-logged-$workoutSessionId',
        repeatable: true,
      ),
    );
  }

  if (masteryPromoted && masteryPattern != null && masteryNewLevel != null) {
    awards.add(
      XpAward(
        eventType: XpEventType.masteryConfirmed,
        amount: masteryConfirmedXp,
        sourceId: '$masteryPattern-level-$masteryNewLevel',
        idempotencyKey: 'mastery-$masteryPattern-level-$masteryNewLevel',
        repeatable: false,
      ),
    );
  }

  return awards;
}
