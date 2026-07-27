import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

enum ReportPeriod {
  sevenDays('7 dias', 7),
  thirtyDays('30 dias', 30),
  ninetyDays('90 dias', 90),
  allTime('Todo o período', null);

  const ReportPeriod(this.label, this.days);
  final String label;
  final int? days;
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.sessions,
    required this.logs,
    required this.xp,
    required this.capabilities,
  });

  final List<WorkoutSessionRecord> sessions;
  final List<SetLogRecord> logs;
  final List<XpLedgerRecord> xp;
  final List<CapabilityEstimateRecord> capabilities;

  int get totalMinutes => sessions.fold(0, (total, session) {
    final completedAt = session.completedAt;
    if (completedAt == null) return total;
    return total +
        completedAt.difference(session.startedAt).inMinutes.clamp(0, 24 * 60);
  });

  int get totalReps => logs.fold(0, (sum, log) => sum + log.repsCompleted);
  int get totalActiveSeconds =>
      logs.fold(0, (sum, log) => sum + ((log.activeDurationMs ?? 0) ~/ 1000));
  int get totalXp => xp.fold(0, (sum, entry) => sum + entry.amount);

  /// Repetições somadas por padrão de movimento, no período do snapshot.
  /// Séries só por tempo (repsCompleted 0) não distorcem o total porque
  /// simplesmente não contribuem com repetições.
  Map<String, int> get volumeByPattern {
    final volume = <String, int>{};
    for (final log in logs) {
      volume[log.pattern] = (volume[log.pattern] ?? 0) + log.repsCompleted;
    }
    return volume;
  }

  /// XP concedido especificamente por concluir cada sessão (evento
  /// `sessionCompleted`, `sourceId` igual ao id da sessão —
  /// xp_rules.dart), para mostrar o XP de cada linha do histórico sem
  /// inventar um valor.
  int? xpForSession(int sessionId) {
    for (final entry in xp) {
      if (entry.eventType == 'sessionCompleted' &&
          entry.sourceId == '$sessionId') {
        return entry.amount;
      }
    }
    return null;
  }
}

class ReportRepository {
  ReportRepository(this._db);
  final AppDatabase _db;

  Future<ReportSnapshot> load(ReportPeriod period, {DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final start = period.days == null
        ? null
        : DateTime(
            reference.year,
            reference.month,
            reference.day,
          ).subtract(Duration(days: period.days! - 1));

    final sessionQuery = _db.select(_db.workoutSessionRecords)
      ..where((t) {
        final completed = t.status.equals('completed');
        return start == null
            ? completed
            : completed & t.completedAt.isBiggerOrEqualValue(start);
      })
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]);
    final sessions = await sessionQuery.get();
    final ids = sessions.map((session) => session.id).toList();
    final logs = ids.isEmpty
        ? <SetLogRecord>[]
        : await (_db.select(
            _db.setLogRecords,
          )..where((t) => t.workoutSessionId.isIn(ids))).get();
    final xpQuery = _db.select(_db.xpLedgerRecords)
      ..where(
        (t) => start == null
            ? const Constant(true)
            : t.createdAt.isBiggerOrEqualValue(start),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final xp = await xpQuery.get();
    final allCapabilities = await (_db.select(
      _db.capabilityEstimateRecords,
    )..orderBy([(t) => OrderingTerm.desc(t.computedAt)])).get();
    final seenPatterns = <String>{};
    final capabilities = allCapabilities
        .where((entry) => seenPatterns.add(entry.pattern))
        .toList();
    return ReportSnapshot(
      sessions: sessions,
      logs: logs,
      xp: xp,
      capabilities: capabilities,
    );
  }
}
