import 'package:drift/drift.dart';

/// Favoritos de treino/exercício na Descobrir (§5.2, filtro
/// "favoritos"). É preferência pessoal, não progresso — sobrevive ao
/// reset (mesmo espírito de `training_preference_records`), então
/// `ProgressResetService` deliberadamente não toca nesta tabela.
@DataClassName('FavoriteRecord')
class FavoriteRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `'workout'` ou `'exercise'` — ver `FavoriteItemType` em
  /// `features/discover/domain/favorite.dart`.
  TextColumn get itemType => text()();
  TextColumn get itemSlug => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {itemType, itemSlug},
  ];
}
