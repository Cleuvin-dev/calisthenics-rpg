import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/assessment/data/capability_estimate_repository.dart';
import 'package:calisthenics_rpg/features/assessment/domain/conservative_placement.dart';
import 'package:calisthenics_rpg/features/assessment/domain/push_horizontal_anchor.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CapabilityEstimateRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CapabilityEstimateRepository(db);
  });

  tearDown(() => db.close());

  test('latestFor retorna null quando não há estimativa', () async {
    expect(await repository.latestFor('push_horizontal'), isNull);
  });

  test('latestFor retorna a estimativa mais recente do padrão', () async {
    const calculator = ConservativePlacementCalculator();

    await repository.save(calculator.calculate(
      anchor: PushHorizontalAnchor.wall,
      now: DateTime(2026, 1, 1),
    ));
    await repository.save(calculator.calculate(
      anchor: PushHorizontalAnchor.floor,
      now: DateTime(2026, 6, 1),
    ));

    final latest = await repository.latestFor('push_horizontal');

    expect(latest, isNotNull);
    expect(latest!.inputAnchor, PushHorizontalAnchor.floor.name);
    expect(latest.level, 6);
  });

  test('latestFor filtra por padrão', () async {
    const calculator = ConservativePlacementCalculator();

    await repository.save(calculator.calculate(
      anchor: PushHorizontalAnchor.wall,
      now: DateTime(2026, 1, 1),
    ));

    expect(await repository.latestFor('pull_vertical'), isNull);
  });
}
