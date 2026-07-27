import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import 'favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(appDatabaseProvider));
});

final favoriteKeysProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(favoriteRepositoryProvider).allKeys();
});
