/// Tipo de item favoritável na Descobrir (§5.2).
enum FavoriteItemType {
  workout('workout'),
  exercise('exercise');

  const FavoriteItemType(this.value);
  final String value;
}

/// Chave composta usada para checar `Set<String>` de favoritos
/// carregados (evita comparar tupla `(itemType, itemSlug)` toda vez).
String favoriteKey(FavoriteItemType type, String slug) => '${type.value}:$slug';
