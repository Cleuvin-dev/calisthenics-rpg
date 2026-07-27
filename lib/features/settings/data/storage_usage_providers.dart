import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage_usage_service.dart';

final storageUsageProvider = FutureProvider<int>((ref) {
  return StorageUsageService().totalBytes();
});
