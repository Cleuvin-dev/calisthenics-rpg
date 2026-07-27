import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/date_period.dart';
import '../../../shared/presentation/empty_state_card.dart';
import '../../onboarding/data/training_preferences_providers.dart';
import '../../rpg/data/rpg_providers.dart';
import '../../rpg/presentation/xp_evolution_chart.dart';
import '../../rpg/presentation/xp_level_badge.dart';
import '../../training_plan/data/training_plan_providers.dart';
import '../../training_plan/domain/exercise_catalog.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../data/body_metric_providers.dart';
import '../data/report_providers.dart';
import '../data/report_repository.dart';
import '../domain/body_metric.dart';
import 'body_metric_screen.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  ReportPeriod _period = ReportPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(reportSnapshotProvider(_period));
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório')),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(reportSnapshotProvider(_period)),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
        data: (data) => ListView(
          key: const PageStorageKey('report-scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ReportPeriod>(
                segments: ReportPeriod.values
                    .map(
                      (period) => ButtonSegment(
                        value: period,
                        label: Text(period.label),
                      ),
                    )
                    .toList(),
                selected: {_period},
                onSelectionChanged: (value) =>
                    setState(() => _period = value.single),
              ),
            ),
            const SizedBox(height: 16),
            const XpLevelBadge(),
            const SizedBox(height: 16),
            _MetricGrid(snapshot: data),
            const SizedBox(height: 20),
            Text(
              'Frequência e aderência ao plano',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _AdherenceCard(period: _period, sessionCount: data.sessions.length),
            const SizedBox(height: 20),
            Text(
              'Evolução de XP (7 dias)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _XpEvolutionCard(),
            const SizedBox(height: 20),
            Text(
              'Recordes pessoais',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _PersonalRecordsCard(),
            const SizedBox(height: 20),
            Text(
              'Volume por padrão de movimento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _VolumeByPatternCard(snapshot: data, period: _period),
            const SizedBox(height: 20),
            Text(
              'Peso, altura e IMC',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const _BodyMetricsCard(),
            const SizedBox(height: 20),
            Text(
              'Histórico de treinos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (data.sessions.isEmpty)
              const EmptyStateCard(
                icon: Icons.history_toggle_off,
                title: 'Nenhum treino concluído',
                message:
                    'Conclua sua primeira sessão para gerar frequência, volume, XP e histórico.',
              )
            else
              ...data.sessions.map((session) {
                final minutes = session.completedAt!
                    .difference(session.startedAt)
                    .inMinutes
                    .clamp(0, 24 * 60);
                final xp = data.xpForSession(session.id);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(session.dayLabel),
                    subtitle: Text(
                      xp == null
                          ? _formatDateTime(session.completedAt!)
                          : '${_formatDateTime(session.completedAt!)} · +$xp XP',
                    ),
                    trailing: Text('$minutes min'),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Text(
              'Progressão de habilidades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (data.capabilities.isEmpty)
              const EmptyStateCard(
                icon: Icons.account_tree_outlined,
                title: 'Sem avaliação registrada',
                message:
                    'Faça a avaliação física para iniciar o acompanhamento por habilidade.',
              )
            else
              ...data.capabilities.map(
                (capability) => Card(
                  child: ListTile(
                    title: Text(_patternLabel(capability.pattern)),
                    subtitle: Text(capability.levelName),
                    trailing: Text('Nv. ${capability.level}'),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AdherenceCard extends ConsumerWidget {
  const _AdherenceCard({required this.period, required this.sessionCount});

  final ReportPeriod period;
  final int sessionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(latestTrainingPlanProvider);
    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (record) {
        if (record == null) {
          return const EmptyStateCard(
            icon: Icons.event_repeat_outlined,
            title: 'Sem plano ativo',
            message: 'Gere um plano semanal para acompanhar a aderência.',
          );
        }
        final targetPerWeek = record.actualDaysPerWeek;
        final weeksInPeriod = period.days == null
            ? (sessionCount == 0 ? 1 : (period.days ?? 7) / 7)
            : (period.days! / 7).clamp(1, double.infinity);
        final targetSessions = (targetPerWeek * weeksInPeriod).round().clamp(
          1,
          1 << 30,
        );
        final adherence = (sessionCount / targetSessions * 100)
            .clamp(0, 100)
            .round();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$sessionCount de $targetSessions sessões esperadas '
                  '(meta: $targetPerWeek/semana)',
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: adherence / 100,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$adherence% de aderência no período'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _XpEvolutionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evolutionAsync = ref.watch(weeklyXpEvolutionProvider);
    return evolutionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (totals) {
        if (totals.every((v) => v == 0)) {
          return const EmptyStateCard(
            icon: Icons.show_chart,
            title: 'Sem XP nos últimos 7 dias',
            message: 'Conclua treinos ou missões para ver a evolução aqui.',
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'XP por dia, últimos 7 dias',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                XpEvolutionChart(dailyTotals: totals),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonalRecordsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestRepsAsync = ref.watch(bestRepsByExerciseProvider);
    return bestRepsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (bestReps) {
        if (bestReps.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.emoji_events_outlined,
            title: 'Nenhum recorde ainda',
            message:
                'Registre séries por repetição para começar a ver seus '
                'recordes pessoais aqui.',
          );
        }
        final entries = bestReps.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return Card(
          child: Column(
            children: entries.map((entry) {
              final exercise = catalogExerciseForSlug(entry.key);
              return ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(exercise?.namePtBr ?? entry.key),
                trailing: Text('${entry.value} reps'),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _VolumeByPatternCard extends StatelessWidget {
  const _VolumeByPatternCard({required this.snapshot, required this.period});

  final ReportSnapshot snapshot;
  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final volume = snapshot.volumeByPattern;
    if (volume.isEmpty || volume.values.every((v) => v == 0)) {
      return EmptyStateCard(
        icon: Icons.bar_chart,
        title: 'Sem volume registrado',
        message:
            'Nenhuma repetição registrada em ${period.label.toLowerCase()}.',
      );
    }
    final entries = volume.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Column(
        children: entries
            .map(
              (entry) => ListTile(
                title: Text(_patternLabel(entry.key)),
                trailing: Text('${entry.value} reps'),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BodyMetricsCard extends ConsumerWidget {
  const _BodyMetricsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(bodyMetricEntriesProvider);
    final preferencesAsync = ref.watch(latestTrainingPreferencesProvider);
    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyStateCard(
            icon: Icons.monitor_weight_outlined,
            title: 'Nenhum peso registrado',
            message:
                'Registre seu peso para acompanhar tendência, recordes e '
                'IMC (indicador geral, sem diagnóstico médico).',
            action: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BodyMetricScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Registrar peso'),
            ),
          );
        }
        final heightCm = preferencesAsync.maybeWhen(
          data: (record) => record?.heightCm,
          orElse: () => null,
        );
        final current = entries.first.weightKg;
        final bmi = calculateBmi(weightKg: current, heightCm: heightCm);
        final category = bmiCategoryFor(bmi);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: Text('${current.toStringAsFixed(1)} kg'),
            subtitle: Text(
              bmi == null
                  ? (heightCm == null
                        ? 'Altura não definida'
                        : 'IMC indisponível')
                  : 'IMC: ${bmi.toStringAsFixed(1)} · ${category!.label}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BodyMetricScreen()),
            ),
          ),
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.snapshot});
  final ReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final streak = currentStreak(
      snapshot.sessions
          .where((s) => s.completedAt != null)
          .map((s) => s.completedAt!),
      DateTime.now(),
    );
    final metrics = [
      ('Treinos', '${snapshot.sessions.length}', Icons.fitness_center),
      ('Minutos', '${snapshot.totalMinutes}', Icons.timer_outlined),
      ('Séries', '${snapshot.logs.length}', Icons.repeat),
      ('Repetições', '${snapshot.totalReps}', Icons.numbers),
      ('XP obtido', '${snapshot.totalXp}', Icons.auto_awesome),
      ('Sequência', '$streak dias', Icons.local_fire_department),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            metric.$3,
                            color: metric.$1 == 'XP obtido'
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          FittedBox(
                            child: Text(
                              metric.$2,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Text(metric.$1),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

String _formatDateTime(DateTime value) {
  const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return '${weekdays[value.weekday - 1]}, ${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} · '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _patternLabel(String pattern) => pattern.replaceAll('_', ' ');
