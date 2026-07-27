import 'dart:io';

import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Confirma que subir de schemaVersion 8 para 9 (tabela nova
/// `favorite_records`, favoritos de treino/exercício na Descobrir)
/// preserva dados já gravados por um usuário real, em vez de recriar
/// nenhuma tabela existente.
void main() {
  test(
    'migração 8 → 9 preserva linhas existentes e cria favorite_records',
    () async {
      final dir = await Directory.systemTemp.createTemp('calisthenics_v9_');
      final file = File(p.join(dir.path, 'legacy.sqlite'));
      addTearDown(() => dir.delete(recursive: true));

      // 1. Monta um banco no formato da versão 8 (sem favorite_records) e
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
        updated_at INTEGER NOT NULL,
        preferred_weekdays_json TEXT,
        height_cm REAL
      );
    ''');
      await legacy.runInsert(
        'INSERT INTO training_preference_records '
        '(days_per_week, minutes_per_session, location, equipment_json, '
        'updated_at, preferred_weekdays_json, height_cm) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [3, 30, 'home', '[]', 1750000000, null, 175.0],
      );
      await legacy.runCustom('PRAGMA user_version = 8');
      await legacy.close();

      // 2. Reabre o mesmo arquivo com o AppDatabase real (schemaVersion 9)
      //    — dispara a migração de verdade.
      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);

      final rows = await upgraded
          .select(upgraded.trainingPreferenceRecords)
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.heightCm, 175.0);

      // Tabela nova, vazia, sem erro.
      expect(await upgraded.select(upgraded.favoriteRecords).get(), isEmpty);

      // Pode gravar depois da migração.
      await upgraded
          .into(upgraded.favoriteRecords)
          .insert(
            FavoriteRecordsCompanion.insert(
              itemType: 'exercise',
              itemSlug: 'push_up_incline',
              createdAt: DateTime(2026, 7, 27),
            ),
          );
      expect(
        await upgraded.select(upgraded.favoriteRecords).get(),
        hasLength(1),
      );
    },
  );
}

class _NoopUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 8;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
