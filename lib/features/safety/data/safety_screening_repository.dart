import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/screening_answers.dart';
import '../domain/screening_result.dart';

class SafetyScreeningRepository {
  SafetyScreeningRepository(this._db);

  final AppDatabase _db;

  Future<void> save(ScreeningAnswers answers, ScreeningResult result) {
    return _db.into(_db.safetyScreenings).insert(
          SafetyScreeningsCompanion.insert(
            hasCardiovascularCondition: answers.hasCardiovascularCondition,
            chestPainAtRestOrExertion: answers.chestPainAtRestOrExertion,
            faintingOrSevereDizziness: answers.faintingOrSevereDizziness,
            boneJointNeurologicalOrRecentSurgery:
                answers.boneJointNeurologicalOrRecentSurgery,
            medicationsAffectingExercise:
                answers.medicationsAffectingExercise,
            pregnantOrPostpartum: answers.pregnantOrPostpartum,
            hasCurrentPain: answers.hasCurrentPain,
            currentPainLocation: Value(answers.currentPainLocation),
            priorMedicalAdviceToLimitActivity:
                answers.priorMedicalAdviceToLimitActivity,
            consentAccepted: answers.consentAccepted,
            result: result.name,
            completedAt: DateTime.now(),
          ),
        );
  }

  /// Última triagem registrada, se houver.
  Future<SafetyScreeningRecord?> latest() {
    final query = _db.select(_db.safetyScreenings)
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }
}
