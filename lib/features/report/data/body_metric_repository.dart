import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Histórico de pesagens (Relatório §6.4) — ao contrário dos ledgers
/// append-only do projeto, permite editar/excluir uma linha (o usuário
/// pode ter digitado um valor errado).
class BodyMetricRepository {
  BodyMetricRepository(this._db);

  final AppDatabase _db;

  Future<int> add({required double weightKg, required DateTime recordedAt}) {
    final now = DateTime.now();
    return _db
        .into(_db.bodyMetricRecords)
        .insert(
          BodyMetricRecordsCompanion.insert(
            recordedAt: recordedAt,
            weightKg: weightKg,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update({
    required int id,
    required double weightKg,
    required DateTime recordedAt,
  }) {
    return (_db.update(
      _db.bodyMetricRecords,
    )..where((t) => t.id.equals(id))).write(
      BodyMetricRecordsCompanion(
        weightKg: Value(weightKg),
        recordedAt: Value(recordedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(int id) {
    return (_db.delete(
      _db.bodyMetricRecords,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Mais recente primeiro.
  Future<List<BodyMetricRecord>> all() {
    final query = _db.select(_db.bodyMetricRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]);
    return query.get();
  }
}
