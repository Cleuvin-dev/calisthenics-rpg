import 'dart:io';

import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/onboarding/data/training_preferences_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Confirma que subir de schemaVersion 7 para 8 (coluna nova `height_cm`
/// em `training_preference_records` + tabela nova `body_metric_records`,
/// peso/altura/IMC) preserva preferências já gravadas por um usuário
/// real, em vez de recriar a tabela.
void main() {
  test(
    'migração 7 → 8 preserva linhas existentes e cria body_metric_records',
    () async {
      final dir = await Directory.systemTemp.createTemp('calisthenics_v8_');
      final file = File(p.join(dir.path, 'legacy.sqlite'));
      addTearDown(() => dir.delete(recursive: true));

      // 1. Monta um banco no formato da versão 7 (sem height_cm, sem
      //    body_metric_records) e insere uma linha, simulando um usuário
      //    com preferências já salvas antes desta entrega.
      final legacy = NativeDatabase(file);
      await legacy.ensureOpen(_NoopUser());
      await legacy.runCustom('''
      CREATE TABLE training_preference_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        days_per_week INTEGER NOT NULL,
        minutes_per_session INTEGER NOT NULL,
        location TEXT NOT NULL,
        equipment_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        preferred_weekdays_json TEXT
      );
    ''');
      await legacy.runInsert(
        'INSERT INTO training_preference_records '
        '(days_per_week, minutes_per_session, location, equipment_json, '
        'updated_at, preferred_weekdays_json) VALUES (?, ?, ?, ?, ?, ?)',
        [3, 30, 'home', '[]', 1750000000, null],
      );
      await legacy.runCustom('PRAGMA user_version = 7');
      await legacy.close();

      // 2. Reabre o mesmo arquivo com o AppDatabase real (schemaVersion 8)
      //    — dispara a migração de verdade.
      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);

      final rows = await upgraded
          .select(upgraded.trainingPreferenceRecords)
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.daysPerWeek, 3);
      // Coluna nova: dado antigo não tinha essa informação, então fica
      // nula em vez de perder a linha inteira ou quebrar a migração.
      expect(rows.single.heightCm, isNull);
      expect(rows.single.toDomain().heightCm, isNull);

      // Tabela nova, vazia, sem erro.
      expect(await upgraded.select(upgraded.bodyMetricRecords).get(), isEmpty);

      // Pode gravar depois da migração.
      await upgraded
          .into(upgraded.bodyMetricRecords)
          .insert(
            BodyMetricRecordsCompanion.insert(
              recordedAt: DateTime(2026, 7, 27),
              weightKg: 70,
              createdAt: DateTime(2026, 7, 27),
              updatedAt: DateTime(2026, 7, 27),
            ),
          );
      expect(
        await upgraded.select(upgraded.bodyMetricRecords).get(),
        hasLength(1),
      );
    },
  );
}

class _NoopUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 7;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
