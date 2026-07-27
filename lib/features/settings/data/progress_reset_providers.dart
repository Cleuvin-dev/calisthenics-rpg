import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import 'progress_reset_service.dart';

final progressResetServiceProvider = Provider<ProgressResetService>((ref) {
  return ProgressResetService(ref.watch(appDatabaseProvider));
});
