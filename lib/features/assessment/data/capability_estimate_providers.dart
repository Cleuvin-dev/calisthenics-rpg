import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import 'capability_estimate_repository.dart';

final capabilityEstimateRepositoryProvider =
    Provider<CapabilityEstimateRepository>((ref) {
  return CapabilityEstimateRepository(ref.watch(appDatabaseProvider));
});

final latestCapabilityEstimateProvider =
    FutureProvider.family<CapabilityEstimateRecord?, String>((ref, pattern) {
  return ref.watch(capabilityEstimateRepositoryProvider).latestFor(pattern);
});
