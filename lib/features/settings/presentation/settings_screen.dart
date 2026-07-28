import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_reset.dart';
import '../../../core/database/app_database.dart';
import '../../assessment/data/capability_estimate_providers.dart';
import '../../missions/data/mission_providers.dart';
import '../../onboarding/data/training_preferences_providers.dart';
import '../../onboarding/data/training_preferences_repository.dart';
import '../../onboarding/domain/training_preferences.dart';
import '../../report/data/body_metric_providers.dart';
import '../../report/data/report_providers.dart';
import '../../report/domain/body_metric.dart';
import '../../report/presentation/body_metric_screen.dart';
import '../../rpg/data/rpg_providers.dart';
import '../../training_plan/data/training_plan_providers.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../data/progress_reset_providers.dart';
import '../data/settings_providers.dart';
import '../data/settings_repository.dart';
import '../data/storage_usage_providers.dart';
import '../data/storage_usage_service.dart' show formatBytes;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.preferences});

  final TrainingPreferenceRecord preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final latestPreferencesAsync = ref.watch(latestTrainingPreferencesProvider);
    final activePreferences = latestPreferencesAsync.maybeWhen(
      data: (latest) => latest ?? preferences,
      orElse: () => preferences,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Definição')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(userSettingsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
        data: (value) => ListView(
          key: const PageStorageKey('settings-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _SectionHeader('Perfil e avaliação'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(value.displayName),
                    subtitle: const Text('Perfil local · sem conta online'),
                    onTap: () => _editName(context, ref, value),
                    trailing: const Icon(Icons.edit_outlined),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(
                      '${activePreferences.daysPerWeek} dias por semana',
                    ),
                    subtitle: Text(
                      '${activePreferences.minutesPerSession} min por sessão · '
                      '${activePreferences.location}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_repeat_outlined),
                    title: const Text('Dias de treino na semana'),
                    subtitle: Text(
                      _weekdaysSummary(
                        activePreferences.toDomain().preferredWeekdays,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editWeekdays(context, ref, activePreferences),
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Objetivo de treino'),
                    subtitle: Text(
                      activePreferences.toDomain().objective.label,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _editObjective(context, ref, activePreferences),
                  ),
                  ListTile(
                    leading: const Icon(Icons.height),
                    title: const Text('Altura'),
                    subtitle: Text(
                      activePreferences.heightCm == null
                          ? 'Não definida — necessária para calcular o IMC'
                          : '${activePreferences.heightCm!.toStringAsFixed(0)} cm',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editHeight(context, ref, activePreferences),
                  ),
                  ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: const Text('Peso e IMC'),
                    subtitle: const Text('Ver histórico e registrar pesagem'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BodyMetricScreen(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: const Text('Refazer avaliação física'),
                    subtitle: const Text(
                      'Disponível após reiniciar ou em uma futura reavaliação dedicada',
                    ),
                    enabled: false,
                  ),
                ],
              ),
            ),
            const _SectionHeader('Treino'),
            Card(
              child: Column(
                children: [
                  _SwitchTile(
                    title: 'Som',
                    value: value.soundEnabled,
                    onChanged: (v) =>
                        _update(ref, value.copyWith(soundEnabled: v)),
                  ),
                  _SwitchTile(
                    title: 'Vibração',
                    value: value.vibrationEnabled,
                    onChanged: (v) =>
                        _update(ref, value.copyWith(vibrationEnabled: v)),
                  ),
                  _SwitchTile(
                    title: 'Instruções por voz',
                    value: value.voiceEnabled,
                    onChanged: (v) =>
                        _update(ref, value.copyWith(voiceEnabled: v)),
                  ),
                  _SwitchTile(
                    title: 'Iniciar descanso automaticamente',
                    value: value.autoStartRest,
                    onChanged: (v) =>
                        _update(ref, value.copyWith(autoStartRest: v)),
                  ),
                  ListTile(
                    title: const Text('Descanso padrão'),
                    trailing: Text('${value.defaultRestSeconds}s'),
                  ),
                  ListTile(
                    title: const Text('Contagem regressiva'),
                    subtitle: const Text(
                      'Antes de iniciar cada série por tempo',
                    ),
                    trailing: Text('${value.countdownSeconds}s'),
                    onTap: () => _editCountdown(context, ref, value),
                  ),
                ],
              ),
            ),
            const _SectionHeader('Aparência e acessibilidade'),
            Card(
              child: Column(
                children: [
                  _SwitchTile(
                    title: 'Alto contraste',
                    value: value.highContrast,
                    onChanged: (v) =>
                        _update(ref, value.copyWith(highContrast: v)),
                  ),
                  _SwitchTile(
                    title: 'Reduzir animações',
                    value: value.reduceMotion,
                    onChanged: (v) =>
                        _update(ref, value.copyWith(reduceMotion: v)),
                  ),
                  ListTile(
                    title: const Text('Tamanho do texto'),
                    subtitle: Slider(
                      value: value.textScale,
                      min: 0.9,
                      max: 1.4,
                      divisions: 5,
                      label: '${(value.textScale * 100).round()}%',
                      onChanged: (v) =>
                          _update(ref, value.copyWith(textScale: v)),
                    ),
                  ),
                  ListTile(
                    title: const Text('Idioma'),
                    trailing: Text(value.language),
                  ),
                ],
              ),
            ),
            const _SectionHeader('Dados'),
            Card(
              child: Column(
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final usage = ref.watch(storageUsageProvider);
                      return ListTile(
                        leading: const Icon(Icons.storage_outlined),
                        title: const Text('Uso de armazenamento'),
                        trailing: usage.when(
                          loading: () => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, _) => const Text('—'),
                          data: (bytes) => Text(formatBytes(bytes)),
                        ),
                      );
                    },
                  ),
                  const ListTile(
                    leading: Icon(Icons.file_download_outlined),
                    title: Text('Exportar dados'),
                    subtitle: Text('Ainda não suportado nesta versão'),
                    enabled: false,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.restart_alt,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Reiniciar progresso e métricas',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text('Mantém perfil e preferências'),
                    onTap: () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const ResetProgressDialog(),
                    ),
                  ),
                ],
              ),
            ),
            const _SectionHeader('Sobre e suporte'),
            const Card(
              child: Column(
                children: [
                  ListTile(title: Text('Versão'), trailing: Text('1.0.0')),
                  ListTile(
                    title: Text('Privacidade'),
                    subtitle: Text('Documentação local do projeto'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editWeekdays(
    BuildContext context,
    WidgetRef ref,
    TrainingPreferenceRecord current,
  ) async {
    final currentDomain = current.toDomain();
    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (context) =>
          _WeekdaysDialog(initialSelection: currentDomain.preferredWeekdays),
    );
    if (selected == null) return;

    final updated = TrainingPreferences(
      daysPerWeek: selected.length,
      minutesPerSession: currentDomain.minutesPerSession,
      location: currentDomain.location,
      equipment: currentDomain.equipment,
      preferredWeekdays: selected,
      heightCm: currentDomain.heightCm,
      objective: currentDomain.objective,
    );
    await ref.read(trainingPreferencesRepositoryProvider).save(updated);
    ref.invalidate(latestTrainingPreferencesProvider);
  }

  Future<void> _editHeight(
    BuildContext context,
    WidgetRef ref,
    TrainingPreferenceRecord current,
  ) async {
    final currentDomain = current.toDomain();
    final heightCm = await showDialog<double>(
      context: context,
      builder: (context) =>
          _HeightDialog(initialHeightCm: currentDomain.heightCm),
    );
    if (heightCm == null) return;

    final updated = TrainingPreferences(
      daysPerWeek: currentDomain.daysPerWeek,
      minutesPerSession: currentDomain.minutesPerSession,
      location: currentDomain.location,
      equipment: currentDomain.equipment,
      preferredWeekdays: currentDomain.preferredWeekdays,
      heightCm: heightCm,
      objective: currentDomain.objective,
    );
    await ref.read(trainingPreferencesRepositoryProvider).save(updated);
    ref.invalidate(latestTrainingPreferencesProvider);
  }

  Future<void> _editObjective(
    BuildContext context,
    WidgetRef ref,
    TrainingPreferenceRecord current,
  ) async {
    final currentDomain = current.toDomain();
    final objective = await showDialog<TrainingObjective>(
      context: context,
      builder: (context) =>
          _ObjectiveDialog(initialObjective: currentDomain.objective),
    );
    if (objective == null) return;

    final updated = TrainingPreferences(
      daysPerWeek: currentDomain.daysPerWeek,
      minutesPerSession: currentDomain.minutesPerSession,
      location: currentDomain.location,
      equipment: currentDomain.equipment,
      preferredWeekdays: currentDomain.preferredWeekdays,
      heightCm: currentDomain.heightCm,
      objective: objective,
    );
    await ref.read(trainingPreferencesRepositoryProvider).save(updated);
    ref.invalidate(latestTrainingPreferencesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Objetivo salvo. Toque em "Gerar novamente" no plano da '
            'semana para aplicar a nova dose.',
          ),
        ),
      );
    }
  }

  String _weekdaysSummary(Set<int> preferredWeekdays) {
    if (preferredWeekdays.isEmpty) return 'Ainda não definido';
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final sorted = preferredWeekdays.toList()..sort();
    return sorted.map((weekday) => labels[weekday - 1]).join(', ');
  }

  Future<void> _editCountdown(
    BuildContext context,
    WidgetRef ref,
    UserSettings current,
  ) async {
    final seconds = await showDialog<int>(
      context: context,
      builder: (context) =>
          _CountdownDialog(initialSeconds: current.countdownSeconds),
    );
    if (seconds == null) return;
    await _update(ref, current.copyWith(countdownSeconds: seconds));
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    UserSettings current,
  ) async {
    final controller = TextEditingController(text: current.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome ou apelido'),
        content: TextField(
          controller: controller,
          maxLength: 40,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await _update(ref, current.copyWith(displayName: name));
    }
  }

  Future<void> _update(WidgetRef ref, UserSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    ref.invalidate(userSettingsProvider);
  }
}

class ResetProgressDialog extends ConsumerStatefulWidget {
  const ResetProgressDialog({super.key});

  @override
  ConsumerState<ResetProgressDialog> createState() =>
      _ResetProgressDialogState();
}

class _ResetProgressDialogState extends ConsumerState<ResetProgressDialog> {
  final _controller = TextEditingController();
  bool _acknowledged = false;
  bool _busy = false;
  String? _error;

  bool get _canContinue =>
      _acknowledged && _controller.text == 'REINICIAR' && !_busy;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Reiniciar progresso e métricas'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Serão apagados XP, nível derivado, missões, sessões, históricos, recordes, habilidades, plano ativo, avaliações, métricas corporais, desafios e caches derivados.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Serão preservados seu perfil local, idioma, acessibilidade, som, voz, vibração, consentimentos e o catálogo. Isto não exclui uma conta.',
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acknowledged,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _acknowledged = value ?? false),
                title: const Text(
                  'Entendo que meu progresso não poderá ser recuperado sem um backup',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                enabled: !_busy,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Digite REINICIAR',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _canContinue ? _confirmFinal : null,
          child: const Text('Apagar progresso'),
        ),
      ],
    );
  }

  Future<void> _confirmFinal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação final'),
        content: const Text(
          'Esta ação começa uma nova jornada e não pode ser desfeita sem backup.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar e apagar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _executeReset();
  }

  Future<void> _executeReset() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(progressResetServiceProvider).reset();
      ref.invalidate(latestCapabilityEstimateProvider);
      ref.invalidate(latestTrainingPlanProvider);
      ref.invalidate(latestActiveWorkoutSessionProvider);
      ref.invalidate(completedSessionsThisWeekProvider);
      ref.invalidate(recentCompletedSessionsProvider);
      ref.invalidate(levelProgressProvider);
      ref.invalidate(recentXpProvider);
      ref.invalidate(weeklyXpEvolutionProvider);
      ref.invalidate(dailyMissionsProvider);
      ref.invalidate(weeklyMissionsProvider);
      ref.invalidate(reportSnapshotProvider);
      ref.invalidate(bodyMetricEntriesProvider);
      ref.invalidate(latestTrainingPreferencesProvider);
      if (!mounted) return;
      ref.read(appResetEpochProvider.notifier).bump();
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Não foi possível reiniciar. Nenhum dado foi apagado: $error';
      });
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) =>
      SwitchListTile(title: Text(title), value: value, onChanged: onChanged);
}

/// Deixa o usuário formalizar em quais dias da semana pretende treinar
/// (`DateTime.weekday`, 1=segunda..7=domingo) — vira a meta usada pela
/// frequência semanal na Jornada e pelo motor de plano.
class _WeekdaysDialog extends StatefulWidget {
  const _WeekdaysDialog({required this.initialSelection});

  final Set<int> initialSelection;

  @override
  State<_WeekdaysDialog> createState() => _WeekdaysDialogState();
}

class _WeekdaysDialogState extends State<_WeekdaysDialog> {
  static const _labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  late final Set<int> _selected = {...widget.initialSelection};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dias de treino na semana'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Escolha os dias que formam sua meta semanal.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              return FilterChip(
                label: Text(_labels[index]),
                selected: _selected.contains(weekday),
                onSelected: (value) => setState(() {
                  if (value) {
                    _selected.add(weekday);
                  } else {
                    _selected.remove(weekday);
                  }
                }),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Deixa o usuário trocar o objetivo de treino (força/perder gordura/
/// condicionamento) — um único objetivo ativo por vez, usado por
/// `WeeklyPlanGenerator` pra modular descanso/séries da próxima vez que
/// o plano for gerado.
class _ObjectiveDialog extends StatefulWidget {
  const _ObjectiveDialog({required this.initialObjective});

  final TrainingObjective initialObjective;

  @override
  State<_ObjectiveDialog> createState() => _ObjectiveDialogState();
}

class _ObjectiveDialogState extends State<_ObjectiveDialog> {
  late TrainingObjective _selected = widget.initialObjective;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Objetivo de treino'),
      content: RadioGroup<TrainingObjective>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final objective in TrainingObjective.values)
              RadioListTile<TrainingObjective>(
                title: Text(objective.label),
                value: objective,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Formaliza a altura de perfil (Definição §7.1), usada só para IMC no
/// Relatório — validação de valor plausível igual à do registro de peso.
class _HeightDialog extends StatefulWidget {
  const _HeightDialog({required this.initialHeightCm});

  final double? initialHeightCm;

  @override
  State<_HeightDialog> createState() => _HeightDialogState();
}

class _HeightDialogState extends State<_HeightDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialHeightCm?.toStringAsFixed(0) ?? '',
  );

  double? get _parsedHeight =>
      double.tryParse(_controller.text.replaceAll(',', '.'));

  bool get _isValid {
    final height = _parsedHeight;
    return height != null && isPlausibleHeightCm(height);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Altura'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(),
            decoration: InputDecoration(
              labelText: 'Altura (cm)',
              errorText: _controller.text.isEmpty || _isValid
                  ? null
                  : 'Informe um valor entre ${minPlausibleHeightCm.round()} '
                        'e ${maxPlausibleHeightCm.round()} cm',
            ),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _isValid
                  ? () => Navigator.pop(context, _parsedHeight)
                  : null,
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

/// Ajusta a contagem preparatória mostrada antes de séries por tempo em
/// `TimedSetPlayer` — 0 pula direto para o cronômetro, sem preparação.
class _CountdownDialog extends StatefulWidget {
  const _CountdownDialog({required this.initialSeconds});

  final int initialSeconds;

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  late double _seconds = widget.initialSeconds.toDouble();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contagem regressiva'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _seconds == 0
                ? 'Sem preparação (começa direto no cronômetro)'
                : '${_seconds.round()} segundos antes de começar',
          ),
          Slider(
            value: _seconds,
            min: 0,
            max: 10,
            divisions: 10,
            label: '${_seconds.round()}s',
            onChanged: (v) => setState(() => _seconds = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _seconds.round()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
