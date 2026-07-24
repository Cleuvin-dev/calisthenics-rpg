import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assessment/data/capability_estimate_providers.dart';
import '../../rpg/data/rpg_providers.dart';
import '../../training_plan/data/training_plan_providers.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../domain/mission.dart';
import 'mission_repository.dart';

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository(
    ref.watch(workoutSessionRepositoryProvider),
    ref.watch(trainingPlanRepositoryProvider),
    ref.watch(capabilityEstimateRepositoryProvider),
    ref.watch(xpLedgerRepositoryProvider),
  );
});

/// Leitura pura e reativa — não concede XP. Ver `MissionRepository.
/// grantCompletedDaily/Weekly` para a ação explícita de conceder,
/// disparada ao abrir a tela Jornada.
final dailyMissionsProvider = FutureProvider<List<MissionEvaluationResult>>((ref) {
  return ref.watch(missionRepositoryProvider).evaluateDaily(DateTime.now());
});

final weeklyMissionsProvider = FutureProvider<List<MissionEvaluationResult>>((ref) {
  return ref.watch(missionRepositoryProvider).evaluateWeekly(DateTime.now());
});
