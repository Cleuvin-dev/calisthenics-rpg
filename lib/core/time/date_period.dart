/// Limites de dia/semana usados por missões (RPG_SYSTEM.md §8) e pela
/// tela Jornada. Semana começa na segunda-feira.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime endOfDay(DateTime date) => startOfDay(date).add(const Duration(days: 1));

DateTime startOfWeek(DateTime date) {
  final day = startOfDay(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime endOfWeek(DateTime date) => startOfWeek(date).add(const Duration(days: 7));
