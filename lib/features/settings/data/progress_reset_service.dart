import '../../../core/database/app_database.dart';

class ProgressResetResult {
  const ProgressResetResult({required this.deletedRows});
  final int deletedRows;
}

/// Limpa somente progresso/métricas numa única transação Drift. Repetir a
/// operação é seguro: tabelas já vazias apenas retornam zero linhas.
class ProgressResetService {
  ProgressResetService(this._db, {this.beforeCommitForTesting});

  final AppDatabase _db;
  final Future<void> Function()? beforeCommitForTesting;

  Future<ProgressResetResult> reset() {
    return _db.transaction(() async {
      var deleted = 0;
      // Dependentes primeiro; todas estas tabelas representam progresso,
      // histórico ou cache derivado. Preferências, perfil e triagem ficam.
      deleted += await _db.delete(_db.activeTimedSetRecords).go();
      deleted += await _db.delete(_db.setLogRecords).go();
      deleted += await _db.delete(_db.workoutSessionRecords).go();
      deleted += await _db.delete(_db.xpLedgerRecords).go();
      deleted += await _db.delete(_db.capabilityEstimateRecords).go();
      deleted += await _db.delete(_db.trainingPlanRecords).go();
      deleted += await _db.delete(_db.outboxEvents).go();
      await beforeCommitForTesting?.call();
      return ProgressResetResult(deletedRows: deleted);
    });
  }
}
