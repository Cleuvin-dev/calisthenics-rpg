/// Missões diárias/semanais (RPG_SYSTEM.md §8). Cobre só o subconjunto
/// derivável dos dados que já existem hoje — sem check-in, sem sessão de
/// recuperação prescrita distinta, sem tela de "revisar progresso".
/// Deliberadamente sem missões de volume ("7 dias seguidos", "500
/// repetições"), conforme a mesma seção proíbe.
const missionRuleVersion = 'missions-v1';

enum MissionPeriod { daily, weekly }

enum MissionType {
  completeWarmup,
  logAnySet,
  completeSession,
  weeklyFrequency,
  trainAllPatterns,
  confirmMastery,
}

class MissionDefinition {
  const MissionDefinition({
    required this.type,
    required this.period,
    required this.titlePtBr,
    required this.xpReward,
  });

  final MissionType type;
  final MissionPeriod period;
  final String titlePtBr;

  /// RPG_SYSTEM.md §2: diária 10-25, semanal 75.
  final int xpReward;
}

const dailyMissionDefinitions = <MissionDefinition>[
  MissionDefinition(
    type: MissionType.completeWarmup,
    period: MissionPeriod.daily,
    titlePtBr: 'Concluir o aquecimento',
    xpReward: 10,
  ),
  MissionDefinition(
    type: MissionType.logAnySet,
    period: MissionPeriod.daily,
    titlePtBr: 'Registrar ao menos uma série',
    xpReward: 10,
  ),
  MissionDefinition(
    type: MissionType.completeSession,
    period: MissionPeriod.daily,
    titlePtBr: 'Concluir uma sessão de treino',
    xpReward: 10,
  ),
];

const weeklyMissionDefinitions = <MissionDefinition>[
  MissionDefinition(
    type: MissionType.weeklyFrequency,
    period: MissionPeriod.weekly,
    titlePtBr: 'Cumprir a frequência do plano',
    xpReward: 75,
  ),
  MissionDefinition(
    type: MissionType.trainAllPatterns,
    period: MissionPeriod.weekly,
    titlePtBr: 'Treinar todos os padrões previstos',
    xpReward: 75,
  ),
  MissionDefinition(
    type: MissionType.confirmMastery,
    period: MissionPeriod.weekly,
    titlePtBr: 'Confirmar domínio de uma habilidade',
    xpReward: 75,
  ),
];

class MissionEvaluationResult {
  const MissionEvaluationResult({
    required this.definition,
    required this.completed,
    this.progressLabel,
  });

  final MissionDefinition definition;
  final bool completed;

  /// Texto opcional de progresso, ex.: "3/4 dias".
  final String? progressLabel;
}
