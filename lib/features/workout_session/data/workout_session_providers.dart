import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import 'workout_session_repository.dart';

final workoutSessionRepositoryProvider =
    Provider<WorkoutSessionRepository>((ref) {
  return WorkoutSessionRepository(ref.watch(appDatabaseProvider));
});

final latestActiveWorkoutSessionProvider =
    FutureProvider<WorkoutSessionRecord?>((ref) {
  return ref.watch(workoutSessionRepositoryProvider).latestActive();
});

final workoutSessionByIdProvider =
    FutureProvider.family<WorkoutSessionRecord?, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.workoutSessionRecords)
    ..where((t) => t.id.equals(id));
  return query.getSingleOrNull();
});

final setLogsForSessionProvider =
    FutureProvider.family<List<SetLogRecord>, int>((ref, workoutSessionId) {
  return ref
      .watch(workoutSessionRepositoryProvider)
      .setLogsFor(workoutSessionId);
});
