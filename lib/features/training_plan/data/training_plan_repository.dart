import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/training_plan.dart';

class TrainingPlanRepository {
  TrainingPlanRepository(this._db);

  final AppDatabase _db;

  Future<void> save(WeeklyPlan plan) {
    return _db.into(_db.trainingPlanRecords).insert(
          TrainingPlanRecordsCompanion.insert(
            requestedDaysPerWeek: plan.requestedDaysPerWeek,
            actualDaysPerWeek: plan.actualDaysPerWeek,
            minutesPerSession: plan.minutesPerSession,
            ruleVersion: plan.ruleVersion,
            catalogVersion: plan.catalogVersion,
            planJson: jsonEncode(plan.toJson()),
            generatedAt: plan.generatedAt,
            validUntil: plan.validUntil,
          ),
        );
  }

  /// Último plano gerado, se houver.
  Future<TrainingPlanRecord?> latest() {
    final query = _db.select(_db.trainingPlanRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }
}

extension TrainingPlanRecordDecoding on TrainingPlanRecord {
  WeeklyPlan toDomain() =>
      WeeklyPlan.fromJson(jsonDecode(planJson) as Map<String, dynamic>);
}
