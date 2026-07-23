import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import 'safety_screening_repository.dart';

final safetyScreeningRepositoryProvider =
    Provider<SafetyScreeningRepository>((ref) {
  return SafetyScreeningRepository(ref.watch(appDatabaseProvider));
});

final latestSafetyScreeningProvider =
    FutureProvider<SafetyScreeningRecord?>((ref) {
  return ref.watch(safetyScreeningRepositoryProvider).latest();
});
