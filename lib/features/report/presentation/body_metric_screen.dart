import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/presentation/empty_state_card.dart';
import '../../onboarding/data/training_preferences_providers.dart';
import '../data/body_metric_providers.dart';
import '../domain/body_metric.dart';

/// Histórico de peso, com altura/IMC ao topo (Relatório §6.4): inserir,
/// editar e excluir pesagens, cada uma com data — nunca só um valor
/// "atual" mutável, para permitir tendência/maior/menor reais.
class BodyMetricScreen extends ConsumerWidget {
  const BodyMetricScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(bodyMetricEntriesProvider);
    final preferencesAsync = ref.watch(latestTrainingPreferencesProvider);
    final heightCm = preferencesAsync.maybeWhen(
      data: (record) => record?.heightCm,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Peso e IMC')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar peso'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(bodyMetricEntriesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
        data: (entries) => ListView(
          key: const PageStorageKey('body-metric-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (entries.isEmpty)
              const EmptyStateCard(
                icon: Icons.monitor_weight_outlined,
                title: 'Nenhum peso registrado',
                message:
                    'Toque em "Adicionar peso" para começar a acompanhar '
                    'peso, tendência e IMC.',
              )
            else ...[
              _SummaryCard(entries: entries, heightCm: heightCm),
              const SizedBox(height: 20),
              Text('Histórico', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Text('${_formatWeight(entry.weightKg)} kg'),
                    subtitle: Text(_formatDate(entry.recordedAt)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _editEntry(context, ref, entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Excluir',
                          onPressed: () => _deleteEntry(context, ref, entry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_WeightEntryResult>(
      context: context,
      builder: (context) => const _WeightEntryDialog(),
    );
    if (result == null) return;
    await ref
        .read(bodyMetricRepositoryProvider)
        .add(weightKg: result.weightKg, recordedAt: result.recordedAt);
    ref.invalidate(bodyMetricEntriesProvider);
  }

  Future<void> _editEntry(
    BuildContext context,
    WidgetRef ref,
    BodyMetricRecord entry,
  ) async {
    final result = await showDialog<_WeightEntryResult>(
      context: context,
      builder: (context) => _WeightEntryDialog(
        initialWeightKg: entry.weightKg,
        initialDate: entry.recordedAt,
      ),
    );
    if (result == null) return;
    await ref
        .read(bodyMetricRepositoryProvider)
        .update(
          id: entry.id,
          weightKg: result.weightKg,
          recordedAt: result.recordedAt,
        );
    ref.invalidate(bodyMetricEntriesProvider);
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    BodyMetricRecord entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro de peso?'),
        content: Text(
          '${_formatWeight(entry.weightKg)} kg em ${_formatDate(entry.recordedAt)} '
          'será removido definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(bodyMetricRepositoryProvider).delete(entry.id);
    ref.invalidate(bodyMetricEntriesProvider);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.entries, required this.heightCm});

  final List<BodyMetricRecord> entries;
  final double? heightCm;

  @override
  Widget build(BuildContext context) {
    final current = entries.first.weightKg;
    final highest = entries
        .map((e) => e.weightKg)
        .reduce((a, b) => a > b ? a : b);
    final lowest = entries
        .map((e) => e.weightKg)
        .reduce((a, b) => a < b ? a : b);
    final trend = entries.length < 2 ? null : current - entries[1].weightKg;
    final bmi = calculateBmi(weightKg: current, heightCm: heightCm);
    final category = bmiCategoryFor(bmi);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(label: 'Atual', value: '${_formatWeight(current)} kg'),
                _Stat(label: 'Maior', value: '${_formatWeight(highest)} kg'),
                _Stat(label: 'Menor', value: '${_formatWeight(lowest)} kg'),
              ],
            ),
            if (trend != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    trend > 0
                        ? Icons.trending_up
                        : trend < 0
                        ? Icons.trending_down
                        : Icons.trending_flat,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trend == 0
                        ? 'Estável desde a última pesagem'
                        : '${trend > 0 ? '+' : ''}${_formatWeight(trend)} kg desde a última pesagem',
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            if (heightCm == null)
              const Text(
                'Altura não definida — configure em Definição > Perfil e '
                'avaliação para calcular o IMC.',
              )
            else if (bmi != null && category != null) ...[
              Text(
                'IMC: ${bmi.toStringAsFixed(1)} · ${category.label}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Indicador geral, sem diagnóstico médico.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _WeightEntryResult {
  const _WeightEntryResult({required this.weightKg, required this.recordedAt});
  final double weightKg;
  final DateTime recordedAt;
}

class _WeightEntryDialog extends StatefulWidget {
  const _WeightEntryDialog({this.initialWeightKg, this.initialDate});

  final double? initialWeightKg;
  final DateTime? initialDate;

  @override
  State<_WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<_WeightEntryDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialWeightKg?.toString() ?? '',
  );
  late DateTime _date = widget.initialDate ?? DateTime.now();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _parsedWeight =>
      double.tryParse(_controller.text.replaceAll(',', '.'));

  bool get _isValid {
    final weight = _parsedWeight;
    return weight != null && isPlausibleWeightKg(weight);
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            widget.initialWeightKg == null ? 'Adicionar peso' : 'Editar peso',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  errorText: _controller.text.isEmpty || _isValid
                      ? null
                      : 'Informe um valor entre ${minPlausibleWeightKg.round()} '
                            'e ${maxPlausibleWeightKg.round()} kg',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(_formatDate(_date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _isValid
                  ? () => Navigator.pop(
                      context,
                      _WeightEntryResult(
                        weightKg: _parsedWeight!,
                        recordedAt: _date,
                      ),
                    )
                  : null,
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

String _formatWeight(double weightKg) {
  final rounded = (weightKg * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(1);
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
