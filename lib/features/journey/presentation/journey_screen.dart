import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../missions/data/mission_providers.dart';
import '../../missions/presentation/mission_list.dart';
import '../../rpg/data/rpg_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Jornada')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const XpLevelBadge(),
          const SizedBox(height: 12),
          completedSessionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (completed) => _NextSessionCard(
              plan: plan,
              completedDayLabels: completed.map((s) => s.dayLabel).toSet(),
              onTap: _openPlan,
            ),
          ),
          const SizedBox(height: 12),
          Card(
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
          const SizedBox(height: 12),
          dailyMissionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (missions) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MissionList(title: 'Missões de hoje', missions: missions),
            ),
          ),
          weeklyMissionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (missions) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MissionList(title: 'Missões da semana', missions: missions),
            ),
          ),
          recentXpAsync.when(
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
                          trailing: Text('+${entry.amount} XP'),
                        ),
                    ],
                  ),
                ),
              );
            },
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
