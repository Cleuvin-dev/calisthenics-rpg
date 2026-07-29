// Script único: vincula as 195 imagens novas (renomeadas como
// "Nivel N - Nome do exercício.png", entregues soltas em
// assets/images/exercicios/) às 195 entradas de
// assets/data/exercise_media_catalog.json, copiando cada arquivo para o
// asset_path que o catálogo já declara (assets/images/exercises/
// <category_slug>/<slug>.png) — a mesma estrutura que pubspec.yaml,
// MediaCatalogIndex e ExerciseMedia já esperavam antes de as imagens
// antigas serem apagadas do disco. Zero mudança em código/pubspec: só os
// arquivos físicos mudam de lugar/conteúdo.
//
// O vínculo é feito só pelo nome (normalizado), nunca pelo número em
// "Nivel N" — esse número é uma numeração global 1-23 do pacote de
// entrega, diferente da escala 0-7 por padrão de movimento que o campo
// "level" do catálogo usa.
//
// Rodar com: dart run tool/link_exercise_media.dart
import 'dart:convert';
import 'dart:io';

const _sourceDir = 'assets/images/exercicios';
const _catalogPath = 'assets/data/exercise_media_catalog.json';

/// Acentos/diacríticos portugueses mais comuns — Dart não tem normalização
/// Unicode (NFD) embutida, então a remoção é feita por mapa explícito.
const _accentMap = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

String _stripAccents(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accentMap[char] ?? char);
  }
  return buffer.toString();
}

/// Normalização de nome para comparação (EXERCISE_MEDIA_GUIDE.md /
/// pedido do usuário, seção 7.2): minúsculo, sem acento, hífen/barra/
/// underscore/pontuação viram separador, espaços colapsados.
String normalize(String input) {
  var value = _stripAccents(input.toLowerCase());
  value = value.replaceAll(RegExp(r'[_\-/]'), ' ');
  value = value.replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ');
  value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return value;
}

/// Parser tolerante do nome do arquivo: "Nivel N - Nome.ext". Aceita os
/// typos reais observados no pacote entregue (Ninvel, Nive, Nive,, Nnivel)
/// — qualquer prefixo que comece com N seguido só de letras, então
/// separador (espaço/vírgula), número, hífen opcional, nome, extensão.
final _fileNamePattern = RegExp(
  r'^N[A-Za-z]*[\s,]+(\d+)\s*[-,]?\s*(.+)\.(png|jpg|jpeg|webp)$',
  caseSensitive: false,
);

/// Casos sem correspondência exata por nome normalizado — cada um
/// conferido manualmente contra a única entrada do catálogo sem arquivo
/// (typo ou abreviação no nome do arquivo entregue, nunca ambiguidade
/// real entre duas entradas possíveis). Chave: nome normalizado do
/// arquivo. Valor: slug real no catálogo.
const _nameExceptions = {
  'elevaca ode panturrilha assistida bilateral':
      'elevacao_panturrilha_assistida_bilateral', // "Elevaçã ode" corrompido no nome do arquivo
  'german hang extremamente assistido':
      'german_hang_extremamente_assistido_aprovado', // nome abreviado (falta "e aprovado")
  'side plank elevada': 'side_plank_elevada_joelhos', // nome abreviado
  'elevacao de joelhos em suporte':
      'elevacao_joelhos_suporte_hang_assistido', // nome abreviado
  'korean dip progressoes especializadas':
      'korean_dip_progressoes_especializadas_se_aprovadas', // nome abreviado
  'elevacao de joelhos suspenso':
      'knee_raises_suspenso', // tradução PT no arquivo, catálogo usa termo em inglês
  'press to handstand progressisons':
      'press_to_handstand_progressions', // typo "progressisons"
  'leg raises parcial': 'leg_raises_parcial_controlado', // nome abreviado
  'leg raises ate a barra':
      'leg_raises_ate_barra_conforme_capacidade', // nome abreviado
  'one arm handstand progressions':
      'one_arm_handstand_progressions_apenas_trilha_elite', // nome abreviado
  'nordic com pausa': 'nordic_pausa_carga', // nome abreviado
  'pistol para caixa baixa': 'pistol_caixa_baixa_contrapeso', // nome abreviado
  'flexao na parece': 'flexao_na_parede', // typo "parece"
  'pistol explosivo':
      'pistol_explosivo_variacao_elite_aprovada', // nome abreviado
  'dead hand confortavel': 'dead_hang_confortavel', // typo "hand"/"hang"
  'pogos aterrissagem tecnica':
      'pogos_aterrissagem_tecnica_baixa_amplitude', // nome abreviado
  'saltos submaximos e aterrisagem':
      'saltos_submaximos_aterrissagem', // typo "aterrisagem"
  'agachamento com pausa': 'agachamento_pausa_tempo', // nome abreviado
  'tranferencia de peso e toe pulls':
      'transferencia_peso_toe_pulls', // typo "Tranferencia"
  'front lever rows progressives':
      'front_lever_rows_progressivas', // typo "progressives"
  'handstand livre de 3 5 segundos':
      'handstand_livre_3_5_s', // nome mais longo que o do catálogo
};

class CatalogEntry {
  CatalogEntry({
    required this.slug,
    required this.name,
    required this.assetPath,
  });

  final String slug;
  final String name;
  final String assetPath;

  factory CatalogEntry.fromJson(Map<String, dynamic> json) => CatalogEntry(
    slug: json['slug'] as String,
    name: json['name'] as String,
    assetPath: json['asset_path'] as String,
  );
}

void main() {
  final catalogRaw = File(_catalogPath).readAsStringSync();
  final catalogJson = jsonDecode(catalogRaw) as List<dynamic>;
  final catalog = catalogJson
      .map((e) => CatalogEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  final byNormalizedName = <String, CatalogEntry>{};
  final dupNames = <String>[];
  for (final entry in catalog) {
    final key = normalize(entry.name);
    if (byNormalizedName.containsKey(key)) dupNames.add(key);
    byNormalizedName[key] = entry;
  }

  final sourceDir = Directory(_sourceDir);
  if (!sourceDir.existsSync()) {
    stderr.writeln('Pasta de origem não existe: $_sourceDir');
    exit(1);
  }
  final files = sourceDir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final unparsed = <String>[];
  final unmatched = <String>[];
  final duplicateSlugUse = <String>[];
  final usedSlugs = <String, String>{}; // slug -> file path já usado
  final copies = <(File src, CatalogEntry entry)>[];

  for (final file in files) {
    final fileName = file.uri.pathSegments.last;
    final match = _fileNamePattern.firstMatch(fileName);
    if (match == null) {
      unparsed.add(fileName);
      continue;
    }
    final rawName = match.group(2)!.trim();
    final key = normalize(rawName);
    final entry = byNormalizedName[key] ?? _resolveException(key, catalog);
    if (entry == null) {
      unmatched.add('$fileName  (nome normalizado: "$key")');
      continue;
    }
    if (usedSlugs.containsKey(entry.slug)) {
      duplicateSlugUse.add(
        '${entry.slug}: "${usedSlugs[entry.slug]}" e "$fileName" apontam '
        'para o mesmo exercício',
      );
      continue;
    }
    usedSlugs[entry.slug] = fileName;
    copies.add((file, entry));
  }

  final unusedCatalogEntries = catalog
      .where((e) => !usedSlugs.containsKey(e.slug))
      .toList();

  stdout.writeln('Arquivos encontrados: ${files.length}');
  stdout.writeln('Entradas no catálogo: ${catalog.length}');
  stdout.writeln('Vinculados com sucesso: ${copies.length}');
  stdout.writeln('Nomes duplicados no catálogo: ${dupNames.length}');
  stdout.writeln(
    'Arquivos com nome não reconhecido (parser): ${unparsed.length}',
  );
  stdout.writeln(
    'Arquivos sem correspondência no catálogo: ${unmatched.length}',
  );
  stdout.writeln(
    'Slugs usados por mais de um arquivo: ${duplicateSlugUse.length}',
  );
  stdout.writeln(
    'Entradas do catálogo sem arquivo correspondente: '
    '${unusedCatalogEntries.length}',
  );

  for (final n in unparsed) {
    stdout.writeln('  NÃO RECONHECIDO: $n');
  }
  for (final n in unmatched) {
    stdout.writeln('  SEM CORRESPONDÊNCIA: $n');
  }
  for (final n in duplicateSlugUse) {
    stdout.writeln('  SLUG DUPLICADO: $n');
  }
  for (final e in unusedCatalogEntries) {
    stdout.writeln('  SEM ARQUIVO: ${e.slug} (${e.name})');
  }

  final hasErrors =
      unparsed.isNotEmpty ||
      unmatched.isNotEmpty ||
      duplicateSlugUse.isNotEmpty ||
      unusedCatalogEntries.isNotEmpty ||
      dupNames.isNotEmpty;

  if (hasErrors) {
    stderr.writeln(
      '\nAbortado: nem todas as 195 imagens bateram 1 para 1. '
      'Nenhum arquivo foi copiado ou apagado.',
    );
    exit(1);
  }

  for (final (src, entry) in copies) {
    final dest = File(entry.assetPath);
    dest.parent.createSync(recursive: true);
    src.copySync(dest.path);
  }
  stdout.writeln(
    '\nOK: ${copies.length}/195 imagens copiadas para a estrutura por '
    'categoria (assets/images/exercises/<categoria>/<slug>.png).',
  );

  sourceDir.deleteSync(recursive: true);
  stdout.writeln('Pasta original removida: $_sourceDir');
}

CatalogEntry? _resolveException(
  String normalizedKey,
  List<CatalogEntry> catalog,
) {
  final slug = _nameExceptions[normalizedKey];
  if (slug == null) return null;
  for (final entry in catalog) {
    if (entry.slug == slug) return entry;
  }
  return null;
}
