import 'package:drift/drift.dart';

/// Fila local de eventos pendentes de sincronização, conforme
/// TECHNICAL_ARCHITECTURE.md §5 e DATA_MODEL.md (sync_receipts).
///
/// Cada linha representa um fato ocorrido no aparelho (ex.: série
/// registrada, sessão concluída) que ainda não foi confirmado pelo
/// backend. `eventId` é a chave de idempotência usada na sincronização.
class OutboxEvents extends Table {
  TextColumn get eventId => text()(); // uuid, chave de idempotência
  TextColumn get clientSessionId => text()();
  TextColumn get eventType => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending|sent|failed
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {eventId};
}
