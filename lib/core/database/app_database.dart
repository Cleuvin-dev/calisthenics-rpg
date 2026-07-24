import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/capability_estimate_records.dart';
import 'tables/outbox_events.dart';
import 'tables/safety_screenings.dart';
import 'tables/set_log_records.dart';
import 'tables/training_plan_records.dart';
import 'tables/training_preference_records.dart';
import 'tables/workout_session_records.dart';
import 'tables/xp_ledger_records.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  OutboxEvents,
  SafetyScreenings,
  TrainingPreferenceRecords,
  CapabilityEstimateRecords,
  TrainingPlanRecords,
  WorkoutSessionRecords,
  SetLogRecords,
  XpLedgerRecords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // inputAnchor virou opcional (colocação "não avaliado").
            // Sem dados reais em produção ainda: recria a tabela.
            await m.deleteTable(capabilityEstimateRecords.actualTableName);
            await m.createTable(capabilityEstimateRecords);
          }
          if (from < 3) {
            // Nova tabela do motor de treino.
            await m.createTable(trainingPlanRecords);
          }
          if (from < 4) {
            // Novas tabelas do player de sessão.
            await m.createTable(workoutSessionRecords);
            await m.createTable(setLogRecords);
          }
          if (from < 5) {
            // Nova tabela do ledger de XP.
            await m.createTable(xpLedgerRecords);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'calisthenics_rpg.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
