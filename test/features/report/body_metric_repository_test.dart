import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/report/data/body_metric_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BodyMetricRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BodyMetricRepository(db);
  });

  tearDown(() => db.close());

  test('add grava e all() devolve mais recente primeiro', () async {
    await repository.add(weightKg: 80, recordedAt: DateTime(2026, 7, 1));
    await repository.add(weightKg: 78, recordedAt: DateTime(2026, 7, 15));

    final entries = await repository.all();

    expect(entries, hasLength(2));
    expect(entries.first.weightKg, 78);
    expect(entries.last.weightKg, 80);
  });

  test('update altera peso e data de uma linha existente', () async {
    final id = await repository.add(
      weightKg: 80,
      recordedAt: DateTime(2026, 7, 1),
    );

    await repository.update(
      id: id,
      weightKg: 79.5,
      recordedAt: DateTime(2026, 7, 2),
    );

    final entries = await repository.all();
    expect(entries, hasLength(1));
    expect(entries.single.weightKg, 79.5);
    expect(entries.single.recordedAt, DateTime(2026, 7, 2));
  });

  test('delete remove só a linha indicada', () async {
    final firstId = await repository.add(
      weightKg: 80,
      recordedAt: DateTime(2026, 7, 1),
    );
    await repository.add(weightKg: 78, recordedAt: DateTime(2026, 7, 15));

    await repository.delete(firstId);

    final entries = await repository.all();
    expect(entries, hasLength(1));
    expect(entries.single.weightKg, 78);
  });
}
