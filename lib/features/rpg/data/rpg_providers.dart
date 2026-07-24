import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import '../domain/level_curve.dart';
import 'xp_ledger_repository.dart';

final xpLedgerRepositoryProvider = Provider<XpLedgerRepository>((ref) {
  return XpLedgerRepository(ref.watch(appDatabaseProvider));
});

final levelProgressProvider = FutureProvider<LevelProgress>((ref) async {
  final totalXp = await ref.watch(xpLedgerRepositoryProvider).totalXp();
  return const LevelCalculator().levelFor(totalXp);
});

final recentXpProvider = FutureProvider((ref) {
  return ref.watch(xpLedgerRepositoryProvider).recent(limit: 5);
});
