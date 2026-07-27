import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import 'report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(appDatabaseProvider));
});

final reportSnapshotProvider =
    FutureProvider.family<ReportSnapshot, ReportPeriod>((ref, period) {
      return ref.watch(reportRepositoryProvider).load(period);
    });
