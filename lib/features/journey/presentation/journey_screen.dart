import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/presentation/fade_slide_in.dart';
import '../../missions/data/mission_providers.dart';
import '../../missions/presentation/mission_list.dart';
import '../../rpg/data/rpg_providers.dart';
import '../../rpg/presentation/xp_evolution_chart.dart';
import '../../rpg/presentation/xp_level_badge.dart';
import '../../training_plan/data/training_plan_repository.dart';
import '../../training_plan/domain/training_plan.dart';
import '../../training_plan/presentation/training_plan_screen.dart';
import '../../workout_session/data/workout_session_providers.dart';

/// Dashboard principal (SCREENS_AND_FLOWS.md §1/§3 — "Jornada", primeiro
/// dos cinco destinos de navegação). Hierarquia da tela: missão
/// principal, próxima habilidade/progresso, nível/XP, missões, histórico
/// curto. Ainda não há os outros quatro destinos (Habilidades, Evolução,
/// Perfil) nem navegação por abas — só "Jornada" e "Treino" existem.
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

  @override
  Widget build(BuildContext context) {
    final plan = widget.record.toDomain();
    final completedSessionsAsync = ref.watch(completedSessionsThisWeekProvider);
    final dailyMissionsAsync = ref.watch(dailyMissionsProvider);
    final weeklyMissionsAsync = ref.watch(weeklyMissionsProvider);
    final recentXpAsync = ref.watch(recentXpProvider);
    final evolutionAsync = ref.watch(weeklyXpEvolutionProvider);

    var cardIndex = 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Jornada')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(index: cardIndex++, child: const XpLevelBadge()),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: cardIndex++,
            child: completedSessionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (completed) => Column(
                children: [
                  _StatusCard(
                    plan: plan,
                    completedCount: completed.length,
                  ),
                  const SizedBox(height: 12),
                  _NextSessionCard(
                    plan: plan,
                    completedDayLabels: completed.map((s) => s.dayLabel).toSet(),
                    onTap: _openPlan,
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
          FadeSlideIn(
            index: cardIndex++,
            child: dailyMissionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (missions) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MissionList(title: 'Missões de hoje', missions: missions),
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
                child: MissionList(title: 'Missões da semana', missions: missions),
              ),
            ),
          ),
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
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _openPlan,
            child: const Text('Ver plano da semana completo'),
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
  const _StatusCard({required this.plan, required this.completedCount});

  final WeeklyPlan plan;
  final int completedCount;

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
                  Text('$completedCount de ${plan.actualDaysPerWeek} sessões '
                      '(meta: $required)'),
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

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        title: Text(
          nextSession == null
              ? 'Todas as sessões desta semana concluídas'
              : '${nextSession.dayLabel} — ${nextSession.targetMinutes} min',
        ),
        subtitle: Text(
          nextSession == null
              ? 'Você pode adiantar a próxima semana ou descansar.'
              : 'Sua próxima missão de treino',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
