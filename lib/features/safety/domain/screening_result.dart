/// Categorias de resultado da triagem (SAFETY_AND_SCREENING.md §3).
enum ScreeningResult {
  cleared,
  needsClarification,
  needsProfessionalGuidance,
  emergency,
}

extension ScreeningResultBlocking on ScreeningResult {
  /// `true` para os resultados que impedem teste/colocação, conforme a
  /// tabela de §3 ("Requer orientação profissional" e "Emergência").
  bool get blocksAssessment =>
      this == ScreeningResult.emergency ||
      this == ScreeningResult.needsProfessionalGuidance;
}
