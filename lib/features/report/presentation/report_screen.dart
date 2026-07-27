import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/empty_state_card.dart';
import '../data/report_providers.dart';
import '../data/report_repository.dart';

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
            _MetricGrid(snapshot: data),
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
              ...data.sessions.map(
                (session) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(session.dayLabel),
                    subtitle: Text(_formatDateTime(session.completedAt!)),
                    trailing: Text(
                      '${session.completedAt!.difference(session.startedAt).inMinutes.clamp(0, 24 * 60)} min',
                    ),
                  ),
                ),
              ),
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.snapshot});
  final ReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Treinos', '${snapshot.sessions.length}', Icons.fitness_center),
      ('Minutos', '${snapshot.totalMinutes}', Icons.timer_outlined),
      ('Séries', '${snapshot.logs.length}', Icons.repeat),
      ('Repetições', '${snapshot.totalReps}', Icons.numbers),
      (
        'Tempo ativo',
        '${snapshot.totalActiveSeconds}s',
        Icons.hourglass_bottom,
      ),
      ('XP obtido', '${snapshot.totalXp}', Icons.auto_awesome),
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
