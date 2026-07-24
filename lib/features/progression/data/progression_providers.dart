import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import '../../assessment/data/capability_estimate_providers.dart';
import 'progression_repository.dart';

final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  return ProgressionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(capabilityEstimateRepositoryProvider),
  );
});
