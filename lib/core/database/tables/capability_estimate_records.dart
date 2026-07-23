import 'package:drift/drift.dart';

/// Resultado de colocação por padrão de movimento, equivalente local a
/// `capability_estimates` (DATA_MODEL.md). Auditável: entradas, confiança,
/// versão de regra e motivo ficam gravados, nunca sobrescritos.
@DataClassName('CapabilityEstimateRecord')
class CapabilityEstimateRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pattern => text()(); // ex.: push_horizontal
  IntColumn get level => integer()();
  TextColumn get levelName => text()();
  TextColumn get confidence => text()(); // low|medium|high
  TextColumn get ruleVersion => text()();
  TextColumn get reasonCode => text()();
  TextColumn get inputAnchor => text().nullable()();
  DateTimeColumn get computedAt => dateTime()();
  DateTimeColumn get validUntil => dateTime()();
}
