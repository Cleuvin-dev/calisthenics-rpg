import 'package:drift/drift.dart';

/// Registro de peso corporal com data (Relatório §6.4). Diferente das
/// tabelas de log append-only do projeto (`set_log_records`,
/// `xp_ledger_records`): o usuário pode editar/excluir uma pesagem
/// registrada errada, então esta tabela permite UPDATE/DELETE por linha.
@DataClassName('BodyMetricRecord')
class BodyMetricRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get weightKg => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
