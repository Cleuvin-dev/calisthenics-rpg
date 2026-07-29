import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/presentation/exercise_media.dart';
import '../../assessment/presentation/placement_result_screen.dart';
import '../../onboarding/data/training_preferences_repository.dart';
import '../../rpg/presentation/xp_level_badge.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../../workout_session/domain/workout_session.dart';
import '../../workout_session/presentation/workout_player_screen.dart';
import '../data/training_plan_providers.dart';
import '../data/training_plan_repository.dart';
import '../domain/training_plan.dart';
import '../domain/weekly_plan_generator.dart';

/// Exibe a semana gerada pelo motor de treino, com o motivo de cada item
/// (TRAINING_ENGINE.md §11 — explicabilidade). Duas abas: "Próximo
/// treino" (só os exercícios do dia que o usuário fará agora — mesma
/// resolução de [nextPendingSession] usada no card da Jornada) e "Semana
/// completa" (todos os dias, para quem quer planejar à frente). Pedido
/// explícito do usuário: por padrão não mostrar todos os exercícios da
/// semana de uma vez, mas sem tirar o acesso a eles.
class TrainingPlanScreen extends ConsumerStatefulWidget {
  const TrainingPlanScreen({
    super.key,
    required this.record,
    required this.preferences,
    required this.placement,
    this.initialTabIndex = 0,
  });

  final TrainingPlanRecord record;
  final TrainingPreferenceRecord preferences;
  final CapabilityEstimateRecord placement;

  /// 0 = "Próximo treino", 1 = "Semana completa".
  final int initialTabIndex;

  @override
  ConsumerState<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends ConsumerState<TrainingPlanScreen>
    with SingleTickerProviderStateMixin {
  bool _regenerating = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _regenerate() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);

    try {
      final capabilityLevelsByPattern = await resolveCapabilityLevelsByPattern(
        ref,
        widget.placement.level,
      );
      const generator = WeeklyPlanGenerator();
      final plan = generator.generate(
        preferences: widget.preferences.toDomain(),
        capabilityLevelsByPattern: capabilityLevelsByPattern,
        now: DateTime.now(),
      );

      await ref.read(trainingPlanRepositoryProvider).save(plan);

      ref.invalidate(latestTrainingPlanProvider);
    } catch (error) {
      // Sem isso, uma falha aqui deixava o botão preso girando pra
      // sempre (`_regenerating` nunca voltava a `false`) e o erro
      // desaparecia sem feedback nenhum pro usuário.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível gerar o plano: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
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

  Future<void> _startSession(PlannedSession session, WeeklyPlan plan) async {
    final repository = ref.read(workoutSessionRepositoryProvider);
    final active = await repository.latestActive();

    if (active != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Finalize ou pause a sessão em andamento antes '
              'de iniciar outra.',
            ),
          ),
        );
      }
      await _openSession(active.id);
      return;
    }

    final id = await repository.startSession(
      dayLabel: session.dayLabel,
      items: session.items
          .map(
            (i) => WorkoutSessionItem(
              pattern: i.pattern,
              exerciseSlug: i.exerciseSlug,
              namePtBr: i.namePtBr,
              setsRepsGuidance: i.setsRepsGuidance,
              // Sem repassar estes campos, toda sessão iniciada perdia a
              // dose real do plano (virava reps/1 série/60s por padrão)
              // e a imagem (mediaSlug nulo) — bug real encontrado
              // testando no aparelho físico.
              doseType: i.doseType,
              targetSets: i.targetSets,
              targetReps: i.targetReps,
              targetSeconds: i.targetSeconds,
              restSeconds: i.restSeconds,
              mediaSlug: i.mediaSlug,
            ),
          )
          .toList(),
      planRuleVersion: plan.ruleVersion,
      catalogVersion: plan.catalogVersion,
      now: DateTime.now(),
    );
    ref.invalidate(latestActiveWorkoutSessionProvider);
    await _openSession(id);
  }

  @override
  Widget build(BuildContext context) {
    // Observa o provider (não só `widget.record`) para refletir sozinha
    // quando o usuário regenera o plano nesta mesma tela — sem isso, a
    // tela ficava presa no plano com que foi aberta até sair e voltar.
    final latestPlanAsync = ref.watch(latestTrainingPlanProvider);
    final record = latestPlanAsync.maybeWhen(
      data: (latest) => latest ?? widget.record,
      orElse: () => widget.record,
    );
    final plan = record.toDomain();
    final activeSessionAsync = ref.watch(latestActiveWorkoutSessionProvider);
    final completedSessionsAsync = ref.watch(completedSessionsThisWeekProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano da semana'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Próximo treino'),
            Tab(text: 'Semana completa'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                const XpLevelBadge(),
                const SizedBox(height: 12),
                activeSessionAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (active) {
                    if (active == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        child: ListTile(
                          title: Text(
                            'Sessão em andamento: ${active.dayLabel}',
                          ),
                          subtitle: Text(
                            active.status == WorkoutSessionStatus.paused.name
                                ? 'Pausada'
                                : 'Em andamento',
                          ),
                          trailing: FilledButton(
                            onPressed: () => _openSession(active.id),
                            child: const Text('Continuar'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (plan.frequencyDowngradeReason != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(plan.frequencyDowngradeReason!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  '${plan.actualDaysPerWeek} sessões, '
                  '~${plan.minutesPerSession} min cada',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Gerado em ${_formatDate(plan.generatedAt)} · '
                  'válido até ${_formatDate(plan.validUntil)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                completedSessionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Erro: $error')),
                  data: (completed) => _NextTrainingTab(
                    plan: plan,
                    completedDayLabels: completed
                        .map((s) => s.dayLabel)
                        .toSet(),
                    onStart: (session) => _startSession(session, plan),
                    onViewFullWeek: () => _tabController.animateTo(1),
                  ),
                ),
                _FullWeekTab(
                  plan: plan,
                  onStart: (session) => _startSession(session, plan),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PlacementResultScreen(estimate: widget.placement),
                    ),
                  ),
                  child: const Text('Ver colocação inicial'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _regenerating ? null : _regenerate,
                  child: _regenerating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gerar novamente'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Aba "Próximo treino": só os exercícios da sessão que o usuário vai
/// fazer agora (mesma resolução de [nextPendingSession] do card da
/// Jornada) — não a semana toda.
class _NextTrainingTab extends StatelessWidget {
  const _NextTrainingTab({
    required this.plan,
    required this.completedDayLabels,
    required this.onStart,
    required this.onViewFullWeek,
  });

  final WeeklyPlan plan;
  final Set<String> completedDayLabels;
  final ValueChanged<PlannedSession> onStart;
  final VoidCallback onViewFullWeek;

  @override
  Widget build(BuildContext context) {
    final session = nextPendingSession(plan, completedDayLabels);

    if (session == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Todas as sessões desta semana concluídas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Você pode adiantar um treino da semana ou só '
                    'descansar até a próxima.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onViewFullWeek,
                    child: const Text('Ver semana completa'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SessionCard(session: session, onStart: () => onStart(session)),
      ],
    );
  }
}

/// Aba "Semana completa": todos os dias e exercícios, para quem quer
/// planejar à frente — comportamento que a tela inteira já tinha antes
/// de existirem as abas.
class _FullWeekTab extends StatelessWidget {
  const _FullWeekTab({required this.plan, required this.onStart});

  final WeeklyPlan plan;
  final ValueChanged<PlannedSession> onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final session in plan.sessions)
          _SessionCard(session: session, onStart: () => onStart(session)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onStart});

  final PlannedSession session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.dayLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.tonal(
                  onPressed: onStart,
                  child: const Text('Iniciar sessão'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in session.items) _ExerciseRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.item});

  final PlannedExerciseItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExerciseMedia(
            exerciseSlug: item.exerciseSlug,
            pattern: item.pattern,
            namePtBr: item.namePtBr,
            mediaSlug: item.mediaSlug,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namePtBr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(item.setsRepsGuidance),
                Text(
                  _reasonText(item.reasonCode),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reasonText(PlanReasonCode code) {
    switch (code) {
      case PlanReasonCode.foundationGap:
        return 'Incluído para cobrir um padrão fundamental da semana.';
      case PlanReasonCode.weeklyBalance:
        return 'Incluído para equilibrar o estímulo entre os dias.';
      case PlanReasonCode.equipmentSubstitution:
        return 'Trocado por uma variação sem equipamento, pois o '
            'equipamento preferido não está disponível.';
    }
  }
}
