import 'package:drift/drift.dart';

/// Plano semanal gerado pelo motor de treino, equivalente local a
/// `training_plans`/`plan_sessions`/`planned_exercises` (DATA_MODEL.md
/// §2.3). Simplificado para uma linha por plano no MVP local-only: as
/// sessões e itens ficam serializados em [planJson] em vez de tabelas
/// relacionadas, já que o plano é recomputável a partir de preferências +
/// capacidade e não precisa de consulta relacional ainda.
@DataClassName('TrainingPlanRecord')
class TrainingPlanRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get requestedDaysPerWeek => integer()();
  IntColumn get actualDaysPerWeek => integer()();
  IntColumn get minutesPerSession => integer()();
  TextColumn get ruleVersion => text()();
  TextColumn get catalogVersion => text()();
  TextColumn get planJson => text()(); // WeeklyPlan.toJson()
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get validUntil => dateTime()();
}
