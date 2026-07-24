/// Eventos que concedem XP (RPG_SYSTEM.md §2). Cobrem só a fatia
/// implementada nesta versão — Boss Test fica para depois.
enum XpEventType {
  sessionCompleted,
  allSetsLogged,
  masteryConfirmed,
  missionCompleted,
}

/// Um crédito a lançar no ledger. `idempotencyKey` é a chave de
/// deduplicação (ECONOMY_AND_ANTI_ABUSE.md §2 — repetir a chamada não
/// duplica o crédito). `repeatable` indica se o evento está sujeito ao
/// teto diário de XP repetível (§3) — domínio confirmado não está, pois
/// só acontece uma vez por nó por natureza da chave de idempotência.
class XpAward {
  const XpAward({
    required this.eventType,
    required this.amount,
    required this.sourceId,
    required this.idempotencyKey,
    required this.repeatable,
  });

  final XpEventType eventType;
  final int amount;
  final String sourceId;
  final String idempotencyKey;
  final bool repeatable;
}
