import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/onboarding/data/training_preferences_repository.dart';
import 'package:calisthenics_rpg/features/onboarding/domain/training_preferences.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('meta de dias da semana persiste e volta a mesma seleção', () async {
    final repository = TrainingPreferencesRepository(db);
    const preferences = TrainingPreferences(
      daysPerWeek: 3,
      minutesPerSession: 30,
      location: TrainingLocation.home,
      equipment: {},
      preferredWeekdays: {1, 3, 5},
    );

    await repository.save(preferences);
    final latest = await repository.latest();

    expect(latest, isNotNull);
    expect(latest!.toDomain().preferredWeekdays, {1, 3, 5});
    expect(latest.daysPerWeek, 3);
  });

  test('sem meta de dias definida, volta conjunto vazio', () async {
    final repository = TrainingPreferencesRepository(db);
    const preferences = TrainingPreferences(
      daysPerWeek: 4,
      minutesPerSession: 45,
      location: TrainingLocation.gym,
      equipment: {Equipment.pullUpBar},
    );

    await repository.save(preferences);
    final latest = await repository.latest();

    expect(latest!.toDomain().preferredWeekdays, isEmpty);
  });

  test('altura persiste e volta a mesma altura', () async {
    final repository = TrainingPreferencesRepository(db);
    const preferences = TrainingPreferences(
      daysPerWeek: 3,
      minutesPerSession: 30,
      location: TrainingLocation.home,
      equipment: {},
      heightCm: 175,
    );

    await repository.save(preferences);
    final latest = await repository.latest();

    expect(latest!.toDomain().heightCm, 175);
  });

  test('sem altura definida, volta nula', () async {
    final repository = TrainingPreferencesRepository(db);
    const preferences = TrainingPreferences(
      daysPerWeek: 3,
      minutesPerSession: 30,
      location: TrainingLocation.home,
      equipment: {},
    );

    await repository.save(preferences);
    final latest = await repository.latest();

    expect(latest!.toDomain().heightCm, isNull);
  });
}
