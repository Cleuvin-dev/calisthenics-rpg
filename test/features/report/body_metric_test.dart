import 'package:calisthenics_rpg/features/report/domain/body_metric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isPlausibleWeightKg', () {
    test('aceita a faixa 20..300 kg', () {
      expect(isPlausibleWeightKg(20), isTrue);
      expect(isPlausibleWeightKg(300), isTrue);
      expect(isPlausibleWeightKg(70), isTrue);
    });

    test('rejeita fora da faixa', () {
      expect(isPlausibleWeightKg(19.9), isFalse);
      expect(isPlausibleWeightKg(300.1), isFalse);
    });
  });

  group('isPlausibleHeightCm', () {
    test('aceita a faixa 100..250 cm', () {
      expect(isPlausibleHeightCm(100), isTrue);
      expect(isPlausibleHeightCm(250), isTrue);
      expect(isPlausibleHeightCm(175), isTrue);
    });

    test('rejeita fora da faixa', () {
      expect(isPlausibleHeightCm(99.9), isFalse);
      expect(isPlausibleHeightCm(250.1), isFalse);
    });
  });

  group('calculateBmi', () {
    test('null quando falta peso ou altura', () {
      expect(calculateBmi(weightKg: null, heightCm: 175), isNull);
      expect(calculateBmi(weightKg: 70, heightCm: null), isNull);
    });

    test('calcula peso / altura(m)^2', () {
      final bmi = calculateBmi(weightKg: 70, heightCm: 175);
      expect(bmi, closeTo(22.86, 0.01));
    });
  });

  group('bmiCategoryFor', () {
    test('null sem IMC', () {
      expect(bmiCategoryFor(null), isNull);
    });

    test('classifica pelas faixas padrão da OMS', () {
      expect(bmiCategoryFor(17), BmiCategory.underweight);
      expect(bmiCategoryFor(22), BmiCategory.normal);
      expect(bmiCategoryFor(27), BmiCategory.overweight);
      expect(bmiCategoryFor(32), BmiCategory.obese);
    });
  });
}
