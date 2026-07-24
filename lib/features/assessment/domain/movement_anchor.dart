/// Ponto de referência autorrelatado genérico, para padrões que ainda
/// não têm uma escada dedicada como `push_horizontal_anchor.dart`
/// (que continua com seu próprio enum, por já estar em produção/testado).
class MovementAnchor {
  const MovementAnchor({
    required this.name,
    required this.skillLevel,
    required this.label,
  });

  /// Chave estável salva em `capability_estimate_records.inputAnchor`.
  final String name;
  final int skillLevel;
  final String label;
}
