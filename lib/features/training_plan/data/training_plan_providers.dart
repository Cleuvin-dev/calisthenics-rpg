import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../assessment/data/capability_estimate_providers.dart';
import '../../assessment/domain/fundamental_pattern_anchors.dart';
import 'training_plan_repository.dart';

final trainingPlanRepositoryProvider = Provider<TrainingPlanRepository>((ref) {
  return TrainingPlanRepository(ref.watch(appDatabaseProvider));
});

final latestTrainingPlanProvider = FutureProvider<TrainingPlanRecord?>((ref) {
  return ref.watch(trainingPlanRepositoryProvider).latest();
});

/// Monta o nível de capacidade por padrão pro `WeeklyPlanGenerator`:
/// `push_horizontal` (colocação obrigatória, já disponível no chamador) +
/// os 4 padrões opcionais de `fundamentalPatternLadders`, lidos da
/// colocação mais recente de cada um (`null` quando o usuário nunca se
/// autoavaliou nesse padrão — o gerador cai para o nível mais
/// conservador nesse caso).
Future<Map<String, int?>> resolveCapabilityLevelsByPattern(
  WidgetRef ref,
  int pushHorizontalLevel,
) async {
  final levels = <String, int?>{'push_horizontal': pushHorizontalLevel};
  for (final ladder in fundamentalPatternLadders) {
    final placement = await ref.read(
      latestCapabilityEstimateProvider(ladder.pattern).future,
    );
    levels[ladder.pattern] = placement?.level;
  }
  return levels;
}
