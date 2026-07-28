/// Local principal de treino (REQUIREMENTS.md FR-002).
enum TrainingLocation {
  home(label: 'Casa'),
  park(label: 'Parque'),
  gym(label: 'Academia');

  const TrainingLocation({required this.label});
  final String label;
}

/// Equipamento disponível (REQUIREMENTS.md FR-002).
enum Equipment {
  none(label: 'Nenhum'),
  elasticBand(label: 'Elástico'),
  pullUpBar(label: 'Barra fixa'),
  parallelBars(label: 'Paralelas'),
  elevatedSurface(label: 'Superfície elevada (banco/mesa)'),
  fullGym(label: 'Academia completa');

  const Equipment({required this.label});
  final String label;
}

/// Objetivo de treino escolhido pelo usuário — modula a dose prescrita
/// por `WeeklyPlanGenerator` (`restSeconds`/`targetSets`), sem trocar o
/// catálogo de exercícios nem os padrões selecionados. Um único
/// objetivo ativo por vez (decisão do usuário, 2026-07-27).
enum TrainingObjective {
  strength(label: 'Força muscular'),
  fatLoss(label: 'Perder gordura'),
  conditioning(label: 'Condicionamento físico');

  const TrainingObjective({required this.label});
  final String label;
}

/// Agenda e equipamento informados no onboarding.
class TrainingPreferences {
  const TrainingPreferences({
    required this.daysPerWeek,
    required this.minutesPerSession,
    required this.location,
    required this.equipment,
    this.preferredWeekdays = const {},
    this.heightCm,
    this.objective = TrainingObjective.strength,
  });

  /// 2..6, conforme REQUIREMENTS.md FR-015.
  final int daysPerWeek;

  /// 15..90, conforme REQUIREMENTS.md FR-015.
  final int minutesPerSession;

  final TrainingLocation location;
  final Set<Equipment> equipment;

  /// Dias da semana escolhidos como meta de treino (`DateTime.weekday`,
  /// 1=segunda..7=domingo). Vazio quando o usuário ainda não formalizou
  /// dias específicos, apenas a quantidade em [daysPerWeek].
  final Set<int> preferredWeekdays;

  /// Altura em centímetros, para IMC. Nulo até o usuário informar.
  final double? heightCm;

  /// Padrão `strength` — mesma dose que o catálogo já prescrevia antes
  /// deste campo existir, então preferências antigas sem valor gravado
  /// mantêm o comportamento de sempre.
  final TrainingObjective objective;
}
