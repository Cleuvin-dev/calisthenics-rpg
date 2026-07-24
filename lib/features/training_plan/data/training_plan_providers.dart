import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import 'training_plan_repository.dart';

final trainingPlanRepositoryProvider = Provider<TrainingPlanRepository>((ref) {
  return TrainingPlanRepository(ref.watch(appDatabaseProvider));
});

final latestTrainingPlanProvider = FutureProvider<TrainingPlanRecord?>((ref) {
  return ref.watch(trainingPlanRepositoryProvider).latest();
});
