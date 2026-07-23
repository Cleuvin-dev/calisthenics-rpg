import 'package:drift/drift.dart';

/// Triagem local de segurança (SAFETY_AND_SCREENING.md §2-3). Cada envio é
/// uma nova linha — histórico não é apagado; a mais recente é a vigente.
@DataClassName('SafetyScreeningRecord')
class SafetyScreenings extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get hasCardiovascularCondition => boolean()();
  BoolColumn get chestPainAtRestOrExertion => boolean()();
  BoolColumn get faintingOrSevereDizziness => boolean()();
  BoolColumn get boneJointNeurologicalOrRecentSurgery => boolean()();
  BoolColumn get medicationsAffectingExercise => boolean()();
  BoolColumn get pregnantOrPostpartum => boolean()();
  BoolColumn get hasCurrentPain => boolean()();
  TextColumn get currentPainLocation => text().nullable()();
  BoolColumn get priorMedicalAdviceToLimitActivity => boolean()();
  BoolColumn get consentAccepted => boolean()();
  TextColumn get result => text()(); // ScreeningResult.name
  DateTimeColumn get completedAt => dateTime()();
}
