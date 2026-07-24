import 'dart:io';

import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Confirma que subir de schemaVersion 5 para 6 (colunas de dose/
/// idempotência em `set_log_records` + tabela nova
/// `active_timed_set_records`) preserva dados já gravados por um usuário
/// real, em vez de recriar a tabela (TEST_STRATEGY.md, ADR de migração
/// aditiva registrado no plano desta entrega).
void main() {
  test('migração 5 → 6 preserva linhas existentes de set_log_records',
      () async {
    final dir = await Directory.systemTemp.createTemp('calisthenics_v6_');
    final file = File(p.join(dir.path, 'legacy.sqlite'));
    addTearDown(() => dir.delete(recursive: true));

    // 1. Monta um banco no formato da versão 5 (sem as colunas novas de
    //    dose/idempotência e sem active_timed_set_records) e insere uma
    //    linha, simulando um usuário com histórico real antes desta
    //    entrega.
    final legacy = NativeDatabase(file);
    await legacy.ensureOpen(_NoopUser());
    await legacy.runCustom('''
      CREATE TABLE workout_session_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        day_label TEXT NOT NULL,
        status TEXT NOT NULL,
        plan_rule_version TEXT NOT NULL,
        catalog_version TEXT NOT NULL,
        items_json TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        completed_at INTEGER NULL
      );
    ''');
    await legacy.runCustom('''
      CREATE TABLE set_log_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_slug TEXT NOT NULL,
        pattern TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps_completed INTEGER NOT NULL,
        perceived_effort TEXT NOT NULL,
        completed_at INTEGER NOT NULL
      );
    ''');
    await legacy.runInsert(
      'INSERT INTO workout_session_records '
      '(day_label, status, plan_rule_version, catalog_version, items_json, '
      'started_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['Full Body A', 'completed', 'v1', 'v1', '[]', 1750000000],
    );
    await legacy.runInsert(
      'INSERT INTO set_log_records '
      '(workout_session_id, exercise_slug, pattern, set_number, '
      'reps_completed, perceived_effort, completed_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [1, 'push_up_wall', 'push_horizontal', 1, 8, 'adequate', 1750000100],
    );
    await legacy.runCustom('PRAGMA user_version = 5');
    await legacy.close();

    // 2. Reabre o mesmo arquivo com o AppDatabase real
    //    (schemaVersion 6) — dispara a migração de verdade.
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    final logs = await upgraded.select(upgraded.setLogRecords).get();
    expect(logs, hasLength(1));
    expect(logs.single.repsCompleted, 8);
    expect(logs.single.exerciseSlug, 'push_up_wall');
    // Colunas novas: dado antigo não tinha essa informação, então fica
    // nulo em vez de perder a linha inteira ou quebrar a migração.
    expect(logs.single.targetReps, isNull);
    expect(logs.single.clientEventId, isNull);

    // Tabela nova criada e utilizável sem erro.
    final active = await upgraded.select(upgraded.activeTimedSetRecords).get();
    expect(active, isEmpty);
  });
}

class _NoopUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 5;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
