import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exercise_media_catalog.dart';

/// Carrega `assets/data/exercise_media_catalog.json` uma única vez
/// (Riverpod mantém o resultado em cache) e monta o índice por
/// slug/categoria+nível. Erro de leitura/parse nunca deve travar o app —
/// widgets que consultam este provider caem para o placeholder animado
/// quando `hasValue` ainda não é verdadeiro.
final exerciseMediaCatalogProvider = FutureProvider<MediaCatalogIndex>((
  ref,
) async {
  final raw = await rootBundle.loadString(
    'assets/data/exercise_media_catalog.json',
  );
  final decoded = jsonDecode(raw) as List<dynamic>;
  final entries = decoded
      .map((e) => MediaCatalogEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  return MediaCatalogIndex(entries);
});
