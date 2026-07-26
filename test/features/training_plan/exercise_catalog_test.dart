import 'package:calisthenics_rpg/features/training_plan/domain/exercise_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica que os 5 padrões com escada em camadas (push_horizontal +
/// os 4 padrões novos) cobrem 0..maxLevel sem buraco nem sobreposição —
/// mesmo espírito do teste de mídia em `exercise_media_catalog_test.dart`,
/// mas para os limites de nível do catálogo de prescrição.
void main() {
  const patternsAndMaxLevel = {
    'push_horizontal': 7,
    'pull_horizontal': 7,
    'squat': 5,
    'hinge_posterior_chain': 5,
    'core_anti_extension': 7,
  };

  for (final entry in patternsAndMaxLevel.entries) {
    final pattern = entry.key;
    final maxLevel = entry.value;

    test('$pattern cobre os níveis 0 a $maxLevel sem buraco, cada um com '
        'exatamente uma variação sem equipamento obrigatório', () {
      for (var level = 0; level <= maxLevel; level++) {
        final matches = exercisesForPattern(pattern).where(
          (e) => e.suitableForLevel(level) && e.requiredEquipment.isEmpty,
        );
        expect(
          matches.length,
          1,
          reason:
              '$pattern nível $level deveria ter exatamente 1 variação sem '
              'equipamento, encontrado ${matches.length}',
        );
      }
    });

    test('$pattern tem uma variação disponível no nível seguinte ao '
        'máximo (fallback aberto no topo da escada)', () {
      final atMax = exerciseForPatternAndLevel(pattern, maxLevel);
      final beyondMax = exerciseForPatternAndLevel(pattern, maxLevel + 5);
      expect(atMax, isNotNull);
      expect(beyondMax, atMax);
    });
  }

  test('pull_horizontal nível 0-1 tem alternativa com elástico além da '
      'variação sem equipamento', () {
    final withEquipment = exercisesForPattern(
      'pull_horizontal',
    ).where((e) => e.suitableForLevel(0) && e.requiredEquipment.isNotEmpty);
    expect(withEquipment.length, 1);
    expect(withEquipment.first.slug, 'band_row');
  });
}
