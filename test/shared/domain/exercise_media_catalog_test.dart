import 'dart:convert';
import 'dart:io';

import 'package:calisthenics_rpg/features/training_plan/domain/exercise_catalog.dart';
import 'package:calisthenics_rpg/shared/domain/exercise_media_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lê o JSON diretamente do disco (não via `rootBundle`): em
/// `testWidgets`, o canal de plataforma de assets só é entregue com
/// tempo de parede real, mas aqui é só um teste de dados puro, sem
/// widget nem plugin — leitura de arquivo comum é suficiente e mais
/// rápida.
List<MediaCatalogEntry> _loadCatalog() {
  final raw = File(
    'assets/data/exercise_media_catalog.json',
  ).readAsStringSync();
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((e) => MediaCatalogEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Testes obrigatórios de `App_RPG_Exercise_Images/CLAUDE_CODE_PROMPT.md`
/// que fazem sentido no nível de dados (não de widget): slug único,
/// asset existente, sem caminho absoluto/URL, mídia compartilhada sem
/// duplicar arquivo.
void main() {
  late List<MediaCatalogEntry> entries;

  setUpAll(() {
    entries = _loadCatalog();
  });

  test('catálogo carrega as 195 imagens do pacote', () {
    expect(entries, hasLength(195));
  });

  test('todo exercício publicado possui slug único', () {
    final slugs = entries.map((e) => e.slug).toList();
    expect(slugs.toSet(), hasLength(slugs.length));
  });

  test('todo asset_path registrado existe no disco', () {
    for (final entry in entries) {
      expect(
        File(entry.assetPath).existsSync(),
        isTrue,
        reason: '${entry.assetPath} (slug ${entry.slug}) não existe',
      );
    }
  });

  test('não existem caminhos absolutos ou URLs em asset_path', () {
    for (final entry in entries) {
      expect(entry.assetPath.startsWith('assets/'), isTrue);
      expect(entry.assetPath.contains('://'), isFalse);
      expect(entry.assetPath.startsWith('/'), isFalse);
    }
  });

  test('exercícios que compartilham a mesma imagem entre duas árvores não '
      'duplicam arquivo (ex.: Wall walk parcial, Handstand livre '
      'consistente — README do pacote)', () {
    final assetPaths = entries.map((e) => e.assetPath).toSet();
    // 195 entradas, 195 caminhos distintos: nenhuma imagem física é
    // gerada duas vezes para nós compartilhados entre árvores.
    expect(assetPaths, hasLength(195));
  });

  test(
    'índice por categoria+nível encontra os nós já citados pelas escadas '
    'de avaliação existentes (push_horizontal, squat, core_anti_extension)',
    () {
      final index = MediaCatalogIndex(entries);
      expect(
        index.byCategoryLevel('empurrar_horizontal', 3)?.slug,
        'flexao_inclinada_media',
      );
      expect(
        index.byCategoryLevel('agachamento_unilateral', 5)?.slug,
        'agachamento_livre',
      );
      expect(
        index.byCategoryLevel('core_anterior_compressao', 6)?.slug,
        'prancha_completa',
      );
    },
  );

  test('todo mediaSlug já associado no catálogo de prescrição '
      '(exercise_catalog.dart) existe no catálogo de 195 imagens', () {
    final index = MediaCatalogIndex(entries);
    final associated = exerciseCatalog
        .where((e) => e.mediaSlug != null)
        .toList();

    // Regressão: se alguém digitar um mediaSlug errado em
    // exercise_catalog.dart, este teste falha em vez de só cair
    // silenciosamente no placeholder em produção.
    expect(associated, isNotEmpty);
    for (final exercise in associated) {
      expect(
        index.bySlug(exercise.mediaSlug!),
        isNotNull,
        reason:
            '${exercise.slug} referencia mediaSlug inexistente '
            '"${exercise.mediaSlug}"',
      );
    }
  });
}
