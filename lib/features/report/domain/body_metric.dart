/// Regras puras de peso/altura/IMC (Relatório §6.3/§6.4): validação de
/// valores plausíveis e cálculo de IMC como indicador geral, sem
/// diagnóstico médico — a categoria é só um rótulo informativo.
const double minPlausibleWeightKg = 20;
const double maxPlausibleWeightKg = 300;
const double minPlausibleHeightCm = 100;
const double maxPlausibleHeightCm = 250;

bool isPlausibleWeightKg(double weightKg) =>
    weightKg >= minPlausibleWeightKg && weightKg <= maxPlausibleWeightKg;

bool isPlausibleHeightCm(double heightCm) =>
    heightCm >= minPlausibleHeightCm && heightCm <= maxPlausibleHeightCm;

/// `null` quando peso ou altura ainda não existem — nunca inventa valor.
double? calculateBmi({required double? weightKg, required double? heightCm}) {
  if (weightKg == null || heightCm == null || heightCm <= 0) return null;
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

enum BmiCategory {
  underweight('Abaixo do peso'),
  normal('Peso adequado'),
  overweight('Sobrepeso'),
  obese('Obesidade');

  const BmiCategory(this.label);
  final String label;
}

BmiCategory? bmiCategoryFor(double? bmi) {
  if (bmi == null) return null;
  if (bmi < 18.5) return BmiCategory.underweight;
  if (bmi < 25) return BmiCategory.normal;
  if (bmi < 30) return BmiCategory.overweight;
  return BmiCategory.obese;
}
