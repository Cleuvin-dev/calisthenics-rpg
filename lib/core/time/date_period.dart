/// Limites de dia/semana usados por missões (RPG_SYSTEM.md §8) e pela
/// tela Jornada. Semana começa na segunda-feira.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime endOfDay(DateTime date) =>
    startOfDay(date).add(const Duration(days: 1));

DateTime startOfWeek(DateTime date) {
  final day = startOfDay(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime endOfWeek(DateTime date) =>
    startOfWeek(date).add(const Duration(days: 7));

/// Dias consecutivos (incluindo hoje ou ontem, para não zerar a sequência
/// antes do fim do dia) com pelo menos uma data em [completions]. Usado
/// pela Jornada e pelo Relatório para a mesma "sequência atual" — derivado
/// só de datas de sessões concluídas reais, nada é inventado.
int currentStreak(Iterable<DateTime> completions, DateTime now) {
  final completedDays = completions.map(startOfDay).toSet();

  var cursor = startOfDay(now);
  if (!completedDays.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var streak = 0;
  while (completedDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
