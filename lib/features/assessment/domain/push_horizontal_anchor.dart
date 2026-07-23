/// Pontos de referência autorrelatados para empurrar horizontal, seguindo
/// a escada documentada em INITIAL_ASSESSMENT.md §4
/// ("parede → bancada → joelhos → chão") e os nós correspondentes em
/// SKILL_TREES.md §2.
enum PushHorizontalAnchor {
  wall(skillLevel: 1, label: 'Flexão na parede'),
  inclineHighSurface(
    skillLevel: 3,
    label: 'Flexão inclinada (bancada/superfície alta)',
  ),
  knees(skillLevel: 5, label: 'Flexão de joelhos'),
  floor(skillLevel: 7, label: 'Flexão tradicional (chão)');

  const PushHorizontalAnchor({required this.skillLevel, required this.label});

  final int skillLevel;
  final String label;
}

/// Nomes dos nós de SKILL_TREES.md §2 (Empurrar horizontal), níveis 0-7 —
/// únicos relevantes para a colocação conservadora desta história (a
/// árvore completa vai até o nível 22).
const pushHorizontalLevelNames = <int, String>{
  0: 'Empurrar a parede em pé',
  1: 'Flexão na parede',
  2: 'Flexão em superfície muito alta',
  3: 'Flexão inclinada média',
  4: 'Flexão inclinada baixa',
  5: 'Flexão de joelhos',
  6: 'Negativa de flexão',
  7: 'Flexão tradicional',
};
