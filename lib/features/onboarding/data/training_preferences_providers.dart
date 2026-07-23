import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import 'training_preferences_repository.dart';

final trainingPreferencesRepositoryProvider =
    Provider<TrainingPreferencesRepository>((ref) {
  return TrainingPreferencesRepository(ref.watch(appDatabaseProvider));
});

final latestTrainingPreferencesProvider =
    FutureProvider<TrainingPreferenceRecord?>((ref) {
  return ref.watch(trainingPreferencesRepositoryProvider).latest();
});
