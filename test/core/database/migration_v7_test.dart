import 'dart:io';

import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/onboarding/data/training_preferences_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Confirma que subir de schemaVersion 6 para 7 (coluna nova
/// `preferred_weekdays_json` em `training_preference_records`, meta de
/// treino por dia da semana) preserva preferências já gravadas por um
/// usuário real, em vez de recriar a tabela.
void main() {
  test(
    'migração 6 → 7 preserva linhas existentes de training_preference_records',
    () async {
      final dir = await Directory.systemTemp.createTemp('calisthenics_v7_');
      final file = File(p.join(dir.path, 'legacy.sqlite'));
      addTearDown(() => dir.delete(recursive: true));

      // 1. Monta um banco no formato da versão 6 (sem a coluna nova) e
      //    insere uma linha, simulando um usuário com preferências já
      //    salvas antes desta entrega.
      final legacy = NativeDatabase(file);
      await legacy.ensureOpen(_NoopUser());
      await legacy.runCustom('''
      CREATE TABLE training_preference_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        days_per_week INTEGER NOT NULL,
        minutes_per_session INTEGER NOT NULL,
        location TEXT NOT NULL,
        equipment_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
      await legacy.runInsert(
        'INSERT INTO training_preference_records '
        '(days_per_week, minutes_per_session, location, equipment_json, '
        'updated_at) VALUES (?, ?, ?, ?, ?)',
        [3, 30, 'home', '[]', 1750000000],
      );
      await legacy.runCustom('PRAGMA user_version = 6');
      await legacy.close();

      // 2. Reabre o mesmo arquivo com o AppDatabase real (schemaVersion 7)
      //    — dispara a migração de verdade.
      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);

      final rows = await upgraded.select(upgraded.trainingPreferenceRecords).get();
      expect(rows, hasLength(1));
      expect(rows.single.daysPerWeek, 3);
      expect(rows.single.location, 'home');
      // Coluna nova: dado antigo não tinha essa informação, então fica
      // nula em vez de perder a linha inteira ou quebrar a migração.
      expect(rows.single.preferredWeekdaysJson, isNull);
      expect(rows.single.toDomain().preferredWeekdays, isEmpty);
    },
  );
}

class _NoopUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 6;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
