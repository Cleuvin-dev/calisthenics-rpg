import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import 'body_metric_repository.dart';

final bodyMetricRepositoryProvider = Provider<BodyMetricRepository>((ref) {
  return BodyMetricRepository(ref.watch(appDatabaseProvider));
});

final bodyMetricEntriesProvider = FutureProvider<List<BodyMetricRecord>>((ref) {
  return ref.watch(bodyMetricRepositoryProvider).all();
});
