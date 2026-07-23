/// Respostas da triagem de segurança (SAFETY_AND_SCREENING.md §2).
/// Textos exatos das perguntas ficam na tela; aqui só os fatos coletados.
class ScreeningAnswers {
  const ScreeningAnswers({
    required this.hasCardiovascularCondition,
    required this.chestPainAtRestOrExertion,
    required this.faintingOrSevereDizziness,
    required this.boneJointNeurologicalOrRecentSurgery,
    required this.medicationsAffectingExercise,
    required this.pregnantOrPostpartum,
    required this.hasCurrentPain,
    this.currentPainLocation,
    required this.priorMedicalAdviceToLimitActivity,
    required this.consentAccepted,
  });

  final bool hasCardiovascularCondition;
  final bool chestPainAtRestOrExertion;
  final bool faintingOrSevereDizziness;
  final bool boneJointNeurologicalOrRecentSurgery;
  final bool medicationsAffectingExercise;
  final bool pregnantOrPostpartum;
  final bool hasCurrentPain;
  final String? currentPainLocation;
  final bool priorMedicalAdviceToLimitActivity;
  final bool consentAccepted;
}
