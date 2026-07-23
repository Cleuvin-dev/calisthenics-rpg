import 'screening_answers.dart';
import 'screening_result.dart';

/// Classificação determinística da triagem, conforme
/// SAFETY_AND_SCREENING.md §2-3. Os critérios exatos são regra de produto
/// pendente de aprovação profissional (§10); mantém-se conservadora por
/// padrão até essa revisão.
class ScreeningClassifier {
  const ScreeningClassifier();

  ScreeningResult classify(ScreeningAnswers answers) {
    if (answers.chestPainAtRestOrExertion ||
        answers.faintingOrSevereDizziness) {
      return ScreeningResult.emergency;
    }

    if (answers.hasCardiovascularCondition ||
        answers.medicationsAffectingExercise ||
        answers.priorMedicalAdviceToLimitActivity ||
        answers.boneJointNeurologicalOrRecentSurgery ||
        answers.pregnantOrPostpartum) {
      return ScreeningResult.needsProfessionalGuidance;
    }

    if (answers.hasCurrentPain) {
      return ScreeningResult.needsClarification;
    }

    return ScreeningResult.cleared;
  }
}
