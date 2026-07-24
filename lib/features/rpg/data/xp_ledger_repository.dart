import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/xp_events.dart';
import '../domain/xp_rules.dart';

class XpLedgerRepository {
  XpLedgerRepository(this._db);

  final AppDatabase _db;

  /// Concede um crédito não sujeito a teto diário (ex.: domínio
  /// confirmado — só acontece uma vez por nó). Idempotente: repetir a
  /// mesma `idempotencyKey` não duplica o crédito.
  Future<bool> grant(XpAward award, {required DateTime now}) async {
    final existing = await (_db.select(_db.xpLedgerRecords)
          ..where((t) => t.idempotencyKey.equals(award.idempotencyKey)))
        .getSingleOrNull();
    if (existing != null) return false;

    await _db.into(_db.xpLedgerRecords).insert(
          XpLedgerRecordsCompanion.insert(
            amount: award.amount,
            eventType: award.eventType.name,
            sourceId: award.sourceId,
            idempotencyKey: award.idempotencyKey,
            ruleVersion: xpRuleVersion,
            createdAt: now,
          ),
        );
    return true;
  }

  /// Concede um crédito repetível, recortado pelo teto diário
  /// (ECONOMY_AND_ANTI_ABUSE.md §3). Retorna o valor efetivamente
  /// concedido (pode ser menor que `award.amount`, ou zero se o teto do
  /// dia já foi atingido).
  Future<int> grantRepeatable(XpAward award, {required DateTime now}) async {
    final existing = await (_db.select(_db.xpLedgerRecords)
          ..where((t) => t.idempotencyKey.equals(award.idempotencyKey)))
        .getSingleOrNull();
    if (existing != null) return 0;

    final grantedToday = await xpGrantedToday(now);
    final headroom = dailyRepeatableXpCap - grantedToday;
    if (headroom <= 0) return 0;

    final amount = award.amount > headroom ? headroom : award.amount;
    await _db.into(_db.xpLedgerRecords).insert(
          XpLedgerRecordsCompanion.insert(
            amount: amount,
            eventType: award.eventType.name,
            sourceId: award.sourceId,
            idempotencyKey: award.idempotencyKey,
            ruleVersion: xpRuleVersion,
            createdAt: now,
          ),
        );
    return amount;
  }

  /// Concede uma lista de créditos, roteando cada um para [grant] ou
  /// [grantRepeatable] conforme `award.repeatable`. Retorna o total
  /// efetivamente concedido.
  Future<int> grantAwards(List<XpAward> awards, {required DateTime now}) async {
    var total = 0;
    for (final award in awards) {
      if (award.repeatable) {
        total += await grantRepeatable(award, now: now);
      } else {
        final granted = await grant(award, now: now);
        if (granted) total += award.amount;
      }
    }
    return total;
  }

  Future<int> totalXp() async {
    final sumExpr = _db.xpLedgerRecords.amount.sum();
    final query = _db.selectOnly(_db.xpLedgerRecords)..addColumns([sumExpr]);
    final row = await query.getSingle();
    return row.read(sumExpr) ?? 0;
  }

  /// Soma de XP concedido por eventos repetíveis no mesmo dia local de
  /// [reference] — usado para aplicar o teto diário.
  Future<int> xpGrantedToday(DateTime reference) async {
    final startOfDay = DateTime(reference.year, reference.month, reference.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sumExpr = _db.xpLedgerRecords.amount.sum();
    final query = _db.selectOnly(_db.xpLedgerRecords)
      ..addColumns([sumExpr])
      ..where(
        _db.xpLedgerRecords.createdAt.isBetweenValues(startOfDay, endOfDay) &
            _db.xpLedgerRecords.eventType.isIn([
              XpEventType.sessionCompleted.name,
              XpEventType.allSetsLogged.name,
            ]),
      );
    final row = await query.getSingle();
    return row.read(sumExpr) ?? 0;
  }

  Future<List<XpLedgerRecord>> recent({int limit = 20}) {
    final query = _db.select(_db.xpLedgerRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }
}
