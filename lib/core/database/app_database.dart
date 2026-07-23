import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/capability_estimate_records.dart';
import 'tables/outbox_events.dart';
import 'tables/safety_screenings.dart';
import 'tables/training_preference_records.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  OutboxEvents,
  SafetyScreenings,
  TrainingPreferenceRecords,
  CapabilityEstimateRecords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'calisthenics_rpg.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
