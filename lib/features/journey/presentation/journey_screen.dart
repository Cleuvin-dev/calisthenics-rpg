import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_period.dart';
import '../../../shared/presentation/fade_slide_in.dart';
import '../../evolution/presentation/evolution_screen.dart';
import '../../missions/data/mission_providers.dart';
import '../../missions/presentation/mission_list.dart';
import '../../onboarding/data/training_preferences_providers.dart';
import '../../onboarding/data/training_preferences_repository.dart'
    show TrainingPreferenceRecordDecoding;
import '../../rpg/data/rpg_providers.dart';
import '../../rpg/presentation/xp_evolution_chart.dart';
import '../../rpg/presentation/xp_level_badge.dart';
import '../../training_plan/data/training_plan_repository.dart';
import '../../training_plan/domain/training_plan.dart';
import '../../training_plan/presentation/training_plan_screen.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../../workout_session/data/workout_session_repository.dart'
    show WorkoutSessionRecordDecoding;
import '../../workout_session/domain/workout_session.dart';
import '../../workout_session/presentation/workout_player_screen.dart';

/// Dashboard principal (SCREENS_AND_FLOWS.md §1/§3 — "Jornada", primeiro
/// dos cinco destinos de navegação). Hierarquia da tela: missão
/// principal, próxima habilidade/progresso, nível/XP, missões, histórico
/// curto. "Evolução" já existe (acessível pelo ícone do AppBar), mas
/// Habilidades e Perfil ainda não — e nenhuma navegação por abas ainda,
/// só pushes de tela.
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({
    super.key,
    required this.record,
    required this.preferences,
    required this.placement,
  });

  final TrainingPlanRecord record;
  final TrainingPreferenceRecord preferences;
  final CapabilityEstimateRecord placement;

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  @override
  void initState() {
    super.initState();
    // Concessão de XP de missões é uma ação explícita, não um efeito
    // colateral escondido dentro de um provider de leitura — dispara ao
    // entrar na tela, como o resto do app faz em pontos de conclusão.
    WidgetsBinding.instance.addPostFrameCallback((_) => _grantMissions());
  }

  Future<void> _grantMissions() async {
    final repository = ref.read(missionRepositoryProvider);
    final now = DateTime.now();
    await repository.grantCompletedDaily(now);
    await repository.grantCompletedWeekly(now);

    if (!mounted) return;
    ref.invalidate(dailyMissionsProvider);
    ref.invalidate(weeklyMissionsProvider);
    ref.invalidate(levelProgressProvider);
    ref.invalidate(recentXpProvider);
    ref.invalidate(weeklyXpEvolutionProvider);
  }

  void _openPlan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingPlanScreen(
          record: widget.record,
          preferences: widget.preferences,
          placement: widget.placement,
        ),
      ),
    );
  }

  Future<void> _openSession(int workoutSessionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutPlayerScreen(
          workoutSessionId: workoutSessionId,
          pushHorizontalPlacement: widget.placement,
        ),
      ),
    );
    ref.invalidate(latestActiveWorkoutSessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.record.toDomain();
    final latestPreferencesAsync = ref.watch(latestTrainingPreferencesProvider);
    final preferredWeekdays = latestPreferencesAsync
        .maybeWhen(
          data: (latest) => latest ?? widget.preferences,
          orElse: () => widget.preferences,
        )
        .toDomain()
        .preferredWeekdays;
    final completedSessionsAsync = ref.watch(completedSessionsThisWeekProvider);
    final activeSessionAsync = ref.watch(latestActiveWorkoutSessionProvider);
    final dailyMissionsAsync = ref.watch(dailyMissionsProvider);
    final weeklyMissionsAsync = ref.watch(weeklyMissionsProvider);
    final recentXpAsync = ref.watch(recentXpProvider);
    final recentSessionsAsync = ref.watch(recentCompletedSessionsProvider);
    final evolutionAsync = ref.watch(weeklyXpEvolutionProvider);

    var cardIndex = 0;

    // Ordem definida em APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md
    // §4.1: nível/XP, sessão pausada, próximo treino, frequência,
    // próxima habilidade, missões, sequência atual, evolução de XP, plano.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jornada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Evolução',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EvolutionScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(index: cardIndex++, child: const XpLevelBadge()),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: cardIndex++,
            child: activeSessionAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (active) {
                if (active == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PausedSessionCard(
                    session: active,
                    onContinue: () => _openSession(active.id),
                  ),
                );
              },
            ),
          ),
          FadeSlideIn(
            index: cardIndex++,
            child: completedSessionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (completed) => Column(
                children: [
                  _NextSessionCard(
                    plan: plan,
                    completedDayLabels: completed
                        .map((s) => s.dayLabel)
                        .toSet(),
                    onTap: _openPlan,
                  ),
                  const SizedBox(height: 12),
                  _StatusCard(
                    plan: plan,
                    completedCount: completed.length,
                    preferredWeekdays: preferredWeekdays,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: cardIndex++,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próxima habilidade',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('Empurrar horizontal: ${widget.placement.levelName}'),
                    Text('Nível ${widget.placement.level} de 7 nesta escala'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: cardIndex++,
            child: dailyMissionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (missions) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MissionList(
                  title: 'Missões de hoje',
                  missions: missions,
                ),
              ),
            ),
          ),
          FadeSlideIn(
            index: cardIndex++,
            child: weeklyMissionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (missions) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MissionList(
                  title: 'Missões da semana',
                  missions: missions,
                ),
              ),
            ),
          ),
          FadeSlideIn(
            index: cardIndex++,
            child: recentSessionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (sessions) {
                final streak = currentStreak(
                  sessions
                      .where((s) => s.completedAt != null)
                      .map((s) => s.completedAt!),
                  DateTime.now(),
                );
                if (streak == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StreakCard(streakDays: streak),
                );
              },
            ),
          ),
          FadeSlideIn(
            index: cardIndex++,
            child: evolutionAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (totals) {
                if (totals.every((v) => v == 0)) return const SizedBox.shrink();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evolução de XP (7 dias)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        XpEvolutionChart(dailyTotals: totals),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _openPlan,
            child: const Text('Ver plano da semana completo'),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: cardIndex++,
            child: recentXpAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (entries) {
                if (entries.isEmpty) return const SizedBox.shrink();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Histórico recente',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final entry in entries)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(_eventLabel(entry.eventType)),
                            trailing: Text(
                              '+${entry.amount} XP',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _eventLabel(String eventType) {
    switch (eventType) {
      case 'sessionCompleted':
        return 'Sessão concluída';
      case 'allSetsLogged':
        return 'Todas as séries registradas';
      case 'masteryConfirmed':
        return 'Domínio confirmado';
      case 'missionCompleted':
        return 'Missão concluída';
      default:
        return eventType;
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.plan,
    required this.completedCount,
    required this.preferredWeekdays,
  });

  final WeeklyPlan plan;
  final int completedCount;
  final Set<int> preferredWeekdays;

  @override
  Widget build(BuildContext context) {
    final required = (plan.actualDaysPerWeek * 0.7).ceil();
    final onTrack = completedCount >= required;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              onTrack ? Icons.local_fire_department : Icons.trending_up,
              color: onTrack ? colorScheme.tertiary : colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequência da semana',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$completedCount de ${plan.actualDaysPerWeek} sessões '
                    '(meta: $required)',
                  ),
                  if (preferredWeekdays.isNotEmpty)
                    Text(
                      'Meta formalizada: ${_weekdayLabels(preferredWeekdays)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabels(Set<int> weekdays) {
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final sorted = weekdays.toList()..sort();
    return sorted.map((weekday) => labels[weekday - 1]).join(', ');
  }
}

class _PausedSessionCard extends ConsumerWidget {
  const _PausedSessionCard({required this.session, required this.onContinue});

  final WorkoutSessionRecord session;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(setLogsForSessionProvider(session.id));
    final colorScheme = Theme.of(context).colorScheme;
    final onContainer = colorScheme.onTertiaryContainer;

    return Card(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: logsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (logs) {
            final items = session.items;
            final totalSets = items.fold<int>(
              0,
              (sum, item) => sum + item.targetSets,
            );
            final completedByExercise = <String, int>{};
            for (final log in logs) {
              completedByExercise[log.exerciseSlug] =
                  (completedByExercise[log.exerciseSlug] ?? 0) + 1;
            }
            WorkoutSessionItem? current;
            var setNumber = 1;
            for (final item in items) {
              final done = completedByExercise[item.exerciseSlug] ?? 0;
              if (done < item.targetSets) {
                current = item;
                setNumber = done + 1;
                break;
              }
            }
            final lastSavedAt = logs.isEmpty
                ? session.startedAt
                : logs
                      .map((log) => log.completedAt)
                      .reduce((a, b) => a.isAfter(b) ? a : b);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sessão pausada: ${session.dayLabel}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: onContainer),
                ),
                const SizedBox(height: 4),
                if (current != null)
                  Text(
                    '${current.namePtBr} · série $setNumber de ${current.targetSets}',
                    style: TextStyle(color: onContainer),
                  ),
                Text(
                  '${logs.length} de $totalSets séries concluídas',
                  style: TextStyle(color: onContainer),
                ),
                Text(
                  'Último salvamento: ${_formatTime(lastSavedAt)}',
                  style: TextStyle(color: onContainer),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onContinue,
                  child: const Text('Continuar treino'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: colorScheme.tertiary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sequência atual',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    streakDays == 1
                        ? '1 dia treinando seguido'
                        : '$streakDays dias treinando seguidos',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.plan,
    required this.completedDayLabels,
    required this.onTap,
  });

  final WeeklyPlan plan;
  final Set<String> completedDayLabels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    PlannedSession? nextSession;
    for (final session in plan.sessions) {
      if (!completedDayLabels.contains(session.dayLabel)) {
        nextSession = session;
        break;
      }
    }

    final onPrimaryContainer = Theme.of(context).colorScheme.onPrimaryContainer;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        title: Text(
          nextSession == null
              ? 'Todas as sessões desta semana concluídas'
              : '${nextSession.dayLabel} — ${nextSession.targetMinutes} min',
          style: TextStyle(color: onPrimaryContainer),
        ),
        subtitle: Text(
          nextSession == null
              ? 'Você pode adiantar a próxima semana ou descansar.'
              : 'Sua próxima missão de treino',
          style: TextStyle(color: onPrimaryContainer),
        ),
        trailing: Icon(Icons.chevron_right, color: onPrimaryContainer),
        onTap: onTap,
      ),
    );
  }
}
