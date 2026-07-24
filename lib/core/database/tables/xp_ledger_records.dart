import 'package:drift/drift.dart';

/// Ledger imutável de XP, equivalente local a `xp_ledger` (DATA_MODEL.md
/// §2.3/§3). Saldo é sempre a soma do ledger, nunca um campo mutável
/// separado. `idempotencyKey` é única — repetir uma concessão não
/// duplica o crédito (ECONOMY_AND_ANTI_ABUSE.md §2).
@DataClassName('XpLedgerRecord')
class XpLedgerRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get eventType => text()(); // XpEventType.name
  TextColumn get sourceId => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get ruleVersion => text()();
  DateTimeColumn get createdAt => dateTime()();
}
