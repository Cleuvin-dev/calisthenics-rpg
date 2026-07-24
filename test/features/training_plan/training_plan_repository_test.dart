import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/onboarding/domain/training_preferences.dart';
import 'package:calisthenics_rpg/features/training_plan/data/training_plan_repository.dart';
import 'package:calisthenics_rpg/features/training_plan/domain/weekly_plan_generator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TrainingPlanRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TrainingPlanRepository(db);
  });

  tearDown(() => db.close());

  test('latest retorna null quando não há plano', () async {
    expect(await repository.latest(), isNull);
  });

  test('save e latest fazem round-trip do plano gerado', () async {
    const generator = WeeklyPlanGenerator();
    final plan = generator.generate(
      preferences: const TrainingPreferences(
        daysPerWeek: 3,
        minutesPerSession: 30,
        location: TrainingLocation.home,
        equipment: {},
      ),
      pushHorizontalCapabilityLevel: 2,
      now: DateTime(2026, 7, 24),
    );

    await repository.save(plan);
    final latest = await repository.latest();

    expect(latest, isNotNull);
    expect(latest!.actualDaysPerWeek, 3);
    expect(latest.ruleVersion, weeklyPlanGeneratorRuleVersion);

    final decoded = latest.toDomain();
    expect(decoded.sessions.length, 3);
    expect(decoded.sessions.first.items, isNotEmpty);
  });

  test('latest retorna sempre o plano mais recente', () async {
    const generator = WeeklyPlanGenerator();
    const prefs = TrainingPreferences(
      daysPerWeek: 2,
      minutesPerSession: 20,
      location: TrainingLocation.home,
      equipment: {},
    );

    await repository.save(generator.generate(
      preferences: prefs,
      pushHorizontalCapabilityLevel: 0,
      now: DateTime(2026, 1, 1),
    ));
    await repository.save(generator.generate(
      preferences: prefs,
      pushHorizontalCapabilityLevel: 6,
      now: DateTime(2026, 6, 1),
    ));

    final latest = await repository.latest();
    expect(latest!.generatedAt, DateTime(2026, 6, 1));
  });
}
