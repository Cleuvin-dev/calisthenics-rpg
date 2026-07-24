import 'movement_anchor.dart';

/// Escadas de autorrelato para os padrões fundamentais além de
/// `push_horizontal` (que já tem seu próprio enum testado,
/// `push_horizontal_anchor.dart`). Níveis e nomes vêm de
/// `05_EXERCISES/SKILL_TREES.md`, mesmo recorte 0-7 (ou menos, quando a
/// árvore completa do padrão é mais curta) usado para push_horizontal —
/// só a parte relevante para a colocação conservadora desta fase.
///
/// A bateria de INITIAL_ASSESSMENT.md §4 usa "barra assistida" como
/// último degrau de "Puxar", mas isso já é puxada vertical
/// (SKILL_TREES.md §5), fora do escopo de `pull_horizontal` — por isso
/// os degraus aqui ficam só na escada horizontal (§4 da árvore).

const pullHorizontalPattern = 'pull_horizontal';
const squatPattern = 'squat';
const hingePosteriorChainPattern = 'hinge_posterior_chain';
const coreAntiExtensionPattern = 'core_anti_extension';

const pullHorizontalAnchors = [
  MovementAnchor(name: 'elasticRow', skillLevel: 1, label: 'Remada em pé com elástico'),
  MovementAnchor(
    name: 'inclineRow',
    skillLevel: 3,
    label: 'Remada australiana inclinada',
  ),
  MovementAnchor(
    name: 'horizontalRow',
    skillLevel: 5,
    label: 'Remada horizontal com pernas estendidas',
  ),
  MovementAnchor(
    name: 'assistedArcherRow',
    skillLevel: 7,
    label: 'Archer row assistida',
  ),
];

const pullHorizontalLevelNames = <int, String>{
  0: 'Retração escapular guiada',
  1: 'Remada em pé com elástico',
  2: 'Remada australiana muito inclinada',
  3: 'Remada australiana inclinada',
  4: 'Remada australiana horizontal com joelhos flexionados',
  5: 'Remada horizontal com pernas estendidas',
  6: 'Remada com pés elevados',
  7: 'Archer row assistida',
};

const squatAnchors = [
  MovementAnchor(
    name: 'mediumBenchSitStand',
    skillLevel: 1,
    label: 'Sentar e levantar de banco médio',
  ),
  MovementAnchor(
    name: 'assistedComfortableRange',
    skillLevel: 3,
    label: 'Agachamento assistido em amplitude confortável',
  ),
  MovementAnchor(name: 'freeSquat', skillLevel: 5, label: 'Agachamento livre'),
];

const squatLevelNames = <int, String>{
  0: 'Sentar e levantar de banco alto',
  1: 'Sentar e levantar de banco médio',
  2: 'Agachamento assistido parcial',
  3: 'Agachamento assistido em amplitude confortável',
  4: 'Agachamento livre até caixa',
  5: 'Agachamento livre',
};

const hingePosteriorChainAnchors = [
  MovementAnchor(
    name: 'fullGluteBridge',
    skillLevel: 1,
    label: 'Ponte de glúteos completa',
  ),
  MovementAnchor(
    name: 'unloadedGoodMorning',
    skillLevel: 3,
    label: 'Good morning sem carga/elástico',
  ),
  MovementAnchor(
    name: 'unilateralBridge',
    skillLevel: 5,
    label: 'Ponte unilateral',
  ),
];

const hingePosteriorChainLevelNames = <int, String>{
  0: 'Ponte de glúteos curta',
  1: 'Ponte de glúteos completa',
  2: 'Hinge na parede',
  3: 'Good morning sem carga/elástico',
  4: 'Ponte unilateral assistida',
  5: 'Ponte unilateral',
};

const coreAntiExtensionAnchors = [
  MovementAnchor(
    name: 'simplifiedDeadBug',
    skillLevel: 2,
    label: 'Dead bug simplificado',
  ),
  MovementAnchor(
    name: 'inclinePlank',
    skillLevel: 4,
    label: 'Prancha inclinada',
  ),
  MovementAnchor(name: 'fullPlank', skillLevel: 6, label: 'Prancha completa'),
];

const coreAntiExtensionLevelNames = <int, String>{
  0: 'Respiração e brace em decúbito',
  1: 'Heel slides',
  2: 'Dead bug simplificado',
  3: 'Dead bug alternado',
  4: 'Prancha inclinada',
  5: 'Prancha de joelhos',
  6: 'Prancha completa',
  7: 'Hollow tuck hold',
};

/// Metadados dos quatro padrões cobertos por este arquivo, para telas
/// que precisam iterar sobre "todos os padrões além de push_horizontal".
class FundamentalPatternLadder {
  const FundamentalPatternLadder({
    required this.pattern,
    required this.titlePtBr,
    required this.anchors,
    required this.levelNames,
  });

  final String pattern;
  final String titlePtBr;
  final List<MovementAnchor> anchors;
  final Map<int, String> levelNames;
}

const fundamentalPatternLadders = [
  FundamentalPatternLadder(
    pattern: pullHorizontalPattern,
    titlePtBr: 'Puxar horizontal',
    anchors: pullHorizontalAnchors,
    levelNames: pullHorizontalLevelNames,
  ),
  FundamentalPatternLadder(
    pattern: squatPattern,
    titlePtBr: 'Agachar',
    anchors: squatAnchors,
    levelNames: squatLevelNames,
  ),
  FundamentalPatternLadder(
    pattern: hingePosteriorChainPattern,
    titlePtBr: 'Cadeia posterior',
    anchors: hingePosteriorChainAnchors,
    levelNames: hingePosteriorChainLevelNames,
  ),
  FundamentalPatternLadder(
    pattern: coreAntiExtensionPattern,
    titlePtBr: 'Core (anti-extensão)',
    anchors: coreAntiExtensionAnchors,
    levelNames: coreAntiExtensionLevelNames,
  ),
];
