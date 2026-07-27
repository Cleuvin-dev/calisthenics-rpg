import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_reset.dart';
import '../../../core/database/app_database.dart';
import '../../assessment/data/capability_estimate_providers.dart';
import '../../missions/data/mission_providers.dart';
import '../../onboarding/data/training_preferences_providers.dart';
import '../../report/data/report_providers.dart';
import '../../rpg/data/rpg_providers.dart';
import '../../training_plan/data/training_plan_providers.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../data/progress_reset_providers.dart';
import '../data/settings_providers.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.preferences});

  final TrainingPreferenceRecord preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
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
                    title: Text('${preferences.daysPerWeek} dias por semana'),
                    subtitle: Text(
                      '${preferences.minutesPerSession} min por sessão · ${preferences.location}',
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
                    trailing: Text('${value.countdownSeconds}s'),
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
