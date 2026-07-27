import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/favorite.dart';

/// Favoritos de treino/exercício (Descobrir §5.2) — preferência pessoal,
/// não progresso: `ProgressResetService` não toca nesta tabela.
class FavoriteRepository {
  FavoriteRepository(this._db);

  final AppDatabase _db;

  Future<void> toggle({
    required FavoriteItemType itemType,
    required String itemSlug,
  }) async {
    final existing = await _find(itemType, itemSlug);
    if (existing != null) {
      await (_db.delete(
        _db.favoriteRecords,
      )..where((t) => t.id.equals(existing.id))).go();
    } else {
      await _db
          .into(_db.favoriteRecords)
          .insert(
            FavoriteRecordsCompanion.insert(
              itemType: itemType.value,
              itemSlug: itemSlug,
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  Future<FavoriteRecord?> _find(FavoriteItemType itemType, String itemSlug) {
    final query = _db.select(_db.favoriteRecords)
      ..where(
        (t) => t.itemType.equals(itemType.value) & t.itemSlug.equals(itemSlug),
      );
    return query.getSingleOrNull();
  }

  /// Chaves compostas (`favoriteKey`) de todos os favoritos, para checar
  /// pertencimento sem uma consulta por item na UI.
  Future<Set<String>> allKeys() async {
    final rows = await _db.select(_db.favoriteRecords).get();
    return rows.map((r) => '${r.itemType}:${r.itemSlug}').toSet();
  }
}
