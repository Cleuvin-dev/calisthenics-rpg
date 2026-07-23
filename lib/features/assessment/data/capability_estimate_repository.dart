import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/conservative_placement.dart';

class CapabilityEstimateRepository {
  CapabilityEstimateRepository(this._db);

  final AppDatabase _db;

  Future<void> save(ConservativePlacementResult result) {
    return _db.into(_db.capabilityEstimateRecords).insert(
          CapabilityEstimateRecordsCompanion.insert(
            pattern: result.pattern,
            level: result.level,
            levelName: result.levelName,
            confidence: result.confidence,
            ruleVersion: result.ruleVersion,
            reasonCode: result.reasonCode.name,
            inputAnchor: Value(result.inputAnchor?.name),
            computedAt: result.computedAt,
            validUntil: result.validUntil,
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
}
