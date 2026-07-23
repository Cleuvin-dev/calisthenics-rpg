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

/// Agenda e equipamento informados no onboarding.
class TrainingPreferences {
  const TrainingPreferences({
    required this.daysPerWeek,
    required this.minutesPerSession,
    required this.location,
    required this.equipment,
  });

  /// 2..6, conforme REQUIREMENTS.md FR-015.
  final int daysPerWeek;

  /// 15..90, conforme REQUIREMENTS.md FR-015.
  final int minutesPerSession;

  final TrainingLocation location;
  final Set<Equipment> equipment;
}
