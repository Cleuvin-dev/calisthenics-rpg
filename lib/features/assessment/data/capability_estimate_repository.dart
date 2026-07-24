import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/conservative_placement.dart';

class CapabilityEstimateRepository {
  CapabilityEstimateRepository(this._db);

  final AppDatabase _db;

  Future<void> save(ConservativePlacementResult result) {
    return saveEstimate(
      pattern: result.pattern,
      level: result.level,
      levelName: result.levelName,
      confidence: result.confidence,
      ruleVersion: result.ruleVersion,
      reasonCode: result.reasonCode.name,
      inputAnchor: result.inputAnchor?.name,
      computedAt: result.computedAt,
      validUntil: result.validUntil,
    );
  }

  /// Grava uma nova estimativa de capacidade, qualquer que seja a origem
  /// (colocação conservadora, confirmação de domínio etc.). Append-only,
  /// como todo registro auditável desta tabela.
  Future<void> saveEstimate({
    required String pattern,
    required int level,
    required String levelName,
    required String confidence,
    required String ruleVersion,
    required String reasonCode,
    String? inputAnchor,
    required DateTime computedAt,
    required DateTime validUntil,
  }) {
    return _db.into(_db.capabilityEstimateRecords).insert(
          CapabilityEstimateRecordsCompanion.insert(
            pattern: pattern,
            level: level,
            levelName: levelName,
            confidence: confidence,
            ruleVersion: ruleVersion,
            reasonCode: reasonCode,
            inputAnchor: Value(inputAnchor),
            computedAt: computedAt,
            validUntil: validUntil,
          ),
        );
  }

  /// Última estimativa registrada para o padrão, se houver.
  Future<CapabilityEstimateRecord?> latestFor(String pattern) {
    final query = _db.select(_db.capabilityEstimateRecords)
      ..where((t) => t.pattern.equals(pattern))
      ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Estimativas com um `reasonCode` específico e `computedAt` em
  /// `[start, end)` — usado pela missão semanal "confirmar domínio".
  Future<List<CapabilityEstimateRecord>> confirmedBetween({
    required String reasonCode,
    required DateTime start,
    required DateTime end,
  }) {
    final query = _db.select(_db.capabilityEstimateRecords)
      ..where(
        (t) =>
            t.reasonCode.equals(reasonCode) &
            t.computedAt.isBetweenValues(start, end),
      );
    return query.get();
  }
}
