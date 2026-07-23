import 'package:calisthenics_rpg/features/safety/domain/screening_answers.dart';
import 'package:calisthenics_rpg/features/safety/domain/screening_classifier.dart';
import 'package:calisthenics_rpg/features/safety/domain/screening_result.dart';
import 'package:flutter_test/flutter_test.dart';

ScreeningAnswers _answers({
  bool cardio = false,
  bool chestPain = false,
  bool fainting = false,
  bool boneJoint = false,
  bool medications = false,
  bool pregnant = false,
  bool currentPain = false,
  bool priorAdvice = false,
}) {
  return ScreeningAnswers(
    hasCardiovascularCondition: cardio,
    chestPainAtRestOrExertion: chestPain,
    faintingOrSevereDizziness: fainting,
    boneJointNeurologicalOrRecentSurgery: boneJoint,
    medicationsAffectingExercise: medications,
    pregnantOrPostpartum: pregnant,
    hasCurrentPain: currentPain,
    priorMedicalAdviceToLimitActivity: priorAdvice,
    consentAccepted: true,
  );
}

void main() {
  const classifier = ScreeningClassifier();

  test('sem sinais de risco resulta em liberado', () {
    expect(classifier.classify(_answers()), ScreeningResult.cleared);
  });

  test('dor no peito resulta em emergência', () {
    expect(
      classifier.classify(_answers(chestPain: true)),
      ScreeningResult.emergency,
    );
  });

  test('desmaio/tontura importante resulta em emergência', () {
    expect(
      classifier.classify(_answers(fainting: true)),
      ScreeningResult.emergency,
    );
  });

  test('condição cardiovascular resulta em orientação profissional', () {
    expect(
      classifier.classify(_answers(cardio: true)),
      ScreeningResult.needsProfessionalGuidance,
    );
  });

  test('gravidez/pós-parto resulta em orientação profissional', () {
    expect(
      classifier.classify(_answers(pregnant: true)),
      ScreeningResult.needsProfessionalGuidance,
    );
  });

  test('recomendação médica prévia resulta em orientação profissional', () {
    expect(
      classifier.classify(_answers(priorAdvice: true)),
      ScreeningResult.needsProfessionalGuidance,
    );
  });

  test('dor atual isolada resulta em esclarecimento', () {
    expect(
      classifier.classify(_answers(currentPain: true)),
      ScreeningResult.needsClarification,
    );
  });

  test('emergência tem prioridade sobre orientação profissional', () {
    expect(
      classifier.classify(_answers(chestPain: true, cardio: true)),
      ScreeningResult.emergency,
    );
  });

  test('resultados de bloqueio conforme SAFETY_AND_SCREENING.md §3-4', () {
    expect(ScreeningResult.emergency.blocksAssessment, isTrue);
    expect(
      ScreeningResult.needsProfessionalGuidance.blocksAssessment,
      isTrue,
    );
    expect(ScreeningResult.needsClarification.blocksAssessment, isFalse);
    expect(ScreeningResult.cleared.blocksAssessment, isFalse);
  });
}
