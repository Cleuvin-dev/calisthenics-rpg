/// Estado de revisão biomecânica de uma imagem de exercício
/// (EXERCISE_MEDIA_GUIDE.md, README do pacote de imagens): movimentos
/// avançados/invertidos continuam exigindo revisão profissional antes de
/// publicação comercial — este app nunca marca essa revisão como feita.
enum VisualReviewStatus {
  requiresProfessionalReview,
  reviewed,
  unknown;

  static VisualReviewStatus fromJson(String? value) {
    switch (value) {
      case 'requires_professional_review':
        return VisualReviewStatus.requiresProfessionalReview;
      case 'reviewed':
        return VisualReviewStatus.reviewed;
      default:
        return VisualReviewStatus.unknown;
    }
  }
}

/// Uma entrada do catálogo de mídia estática de exercícios (pacote de 195
/// imagens, `exercise_media_catalog.json`, um nó por movimento de
/// `05_EXERCISES/SKILL_TREES.md`). Associação com o catálogo de
/// prescrição do app (`CatalogExercise`) é feita pelo `slug`, nunca por
/// comparação de nome exibido.
class MediaCatalogEntry {
  const MediaCatalogEntry({
    required this.slug,
    required this.name,
    required this.category,
    required this.categorySlug,
    required this.level,
    required this.mediaKey,
    required this.assetPath,
    required this.mediaType,
    required this.visualReviewStatus,
    this.starterFile,
  });

  final String slug;
  final String name;
  final String category;
  final String categorySlug;
  final int level;
  final String mediaKey;
  final String assetPath;
  final String mediaType;
  final VisualReviewStatus visualReviewStatus;
  final String? starterFile;

  factory MediaCatalogEntry.fromJson(Map<String, dynamic> json) {
    return MediaCatalogEntry(
      slug: json['slug'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      categorySlug: json['category_slug'] as String,
      level: json['level'] as int,
      mediaKey: json['media_key'] as String,
      assetPath: json['asset_path'] as String,
      mediaType: json['media_type'] as String,
      visualReviewStatus: VisualReviewStatus.fromJson(
        json['visual_review_status'] as String?,
      ),
      starterFile: json['starter_file'] as String?,
    );
  }
}

/// Índice em memória do catálogo de mídia, montado uma vez a partir do
/// JSON (`ExerciseMediaCatalogRepository`). Guarda dois índices: por
/// `slug` (associação direta de um `CatalogExercise.mediaSlug`) e por
/// `(categorySlug, level)` (para telas que mostram a escada 0-7 de um
/// padrão, ex.: avaliação/Evolução — reaproveita o mesmo recorte de nível
/// que `fundamental_pattern_anchors.dart`/`push_horizontal_anchor.dart`
/// já usam, porque ambos vêm do mesmo SKILL_TREES.md).
class MediaCatalogIndex {
  MediaCatalogIndex(List<MediaCatalogEntry> entries)
    : entries = List.unmodifiable(entries),
      _bySlug = {for (final e in entries) e.slug: e},
      _byPatternLevel = {
        for (final e in entries) '${e.categorySlug}:${e.level}': e,
      };

  final List<MediaCatalogEntry> entries;
  final Map<String, MediaCatalogEntry> _bySlug;
  final Map<String, MediaCatalogEntry> _byPatternLevel;

  MediaCatalogEntry? bySlug(String slug) => _bySlug[slug];

  MediaCatalogEntry? byCategoryLevel(String categorySlug, int level) =>
      _byPatternLevel['$categorySlug:$level'];
}
