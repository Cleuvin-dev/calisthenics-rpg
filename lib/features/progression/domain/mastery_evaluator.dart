import '../../workout_session/domain/workout_session.dart';
import 'mastery_rules.dart';

/// Séries de uma sessão concluída para um exercício específico, na ordem
/// em que foram registradas.
class SessionEvidence {
  const SessionEvidence({required this.completedAt, required this.sets});

  final DateTime completedAt;
  final List<SetLog> sets;
}

class MasteryEvaluationResult {
  const MasteryEvaluationResult({
    required this.qualifyingConfirmations,
    required this.confirmationsRequired,
    required this.promoted,
  });

  final int qualifyingConfirmations;
  final int confirmationsRequired;
  final bool promoted;

  bool get hasPartialProgress => !promoted && qualifyingConfirmations > 0;
}

/// Confirma domínio de uma variação a partir do histórico de sessões
/// concluídas (PROGRESSION_RULES.md §2-3). Evidência com dor não conta
/// (DATA_MODEL.md §4 — "evidência usada em domínio não tem dor
/// impeditiva").
class MasteryEvaluator {
  const MasteryEvaluator();

  MasteryEvaluationResult evaluate({
    required MasteryRule rule,
    required List<SessionEvidence> sessions,
  }) {
    final qualifyingTimestamps = <DateTime>[];

    for (final session in sessions) {
      final hasPain =
          session.sets.any((s) => s.perceivedEffort == PerceivedEffort.pain);
      if (hasPain) continue;

      final qualifyingSets = session.sets.where(
        (s) =>
            s.repsCompleted >= rule.minRepsPerSet &&
            (s.perceivedEffort == PerceivedEffort.adequate ||
                s.perceivedEffort == PerceivedEffort.tooEasy),
      ).length;

      if (qualifyingSets >= rule.minQualifyingSets) {
        qualifyingTimestamps.add(session.completedAt);
      }
    }

    final confirmations = <DateTime>[];
    for (final timestamp in qualifyingTimestamps) {
      final gapSatisfied = confirmations.isEmpty ||
          timestamp.difference(confirmations.last).inHours >=
              rule.minHoursBetweenConfirmations;
      if (gapSatisfied) {
        confirmations.add(timestamp);
      }
      if (confirmations.length >= rule.confirmationsRequired) break;
    }

    return MasteryEvaluationResult(
      qualifyingConfirmations: confirmations.length,
      confirmationsRequired: rule.confirmationsRequired,
      promoted: confirmations.length >= rule.confirmationsRequired,
    );
  }
}
