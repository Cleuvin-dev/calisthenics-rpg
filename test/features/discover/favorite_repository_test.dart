import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/discover/data/favorite_repository.dart';
import 'package:calisthenics_rpg/features/discover/domain/favorite.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FavoriteRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FavoriteRepository(db);
  });

  tearDown(() => db.close());

  test('toggle adiciona e remove o mesmo item', () async {
    await repository.toggle(
      itemType: FavoriteItemType.exercise,
      itemSlug: 'push_up_incline',
    );
    expect(await repository.allKeys(), {
      favoriteKey(FavoriteItemType.exercise, 'push_up_incline'),
    });

    await repository.toggle(
      itemType: FavoriteItemType.exercise,
      itemSlug: 'push_up_incline',
    );
    expect(await repository.allKeys(), isEmpty);
  });

  test('workout e exercise com o mesmo slug não colidem', () async {
    await repository.toggle(
      itemType: FavoriteItemType.workout,
      itemSlug: 'foundation',
    );
    await repository.toggle(
      itemType: FavoriteItemType.exercise,
      itemSlug: 'foundation',
    );

    expect(await repository.allKeys(), {
      favoriteKey(FavoriteItemType.workout, 'foundation'),
      favoriteKey(FavoriteItemType.exercise, 'foundation'),
    });
  });

  test('múltiplos favoritos independentes', () async {
    await repository.toggle(
      itemType: FavoriteItemType.exercise,
      itemSlug: 'push_up_incline',
    );
    await repository.toggle(
      itemType: FavoriteItemType.workout,
      itemSlug: 'foundation',
    );

    final keys = await repository.allKeys();
    expect(keys, hasLength(2));

    await repository.toggle(
      itemType: FavoriteItemType.exercise,
      itemSlug: 'push_up_incline',
    );
    expect(await repository.allKeys(), {
      favoriteKey(FavoriteItemType.workout, 'foundation'),
    });
  });
}
