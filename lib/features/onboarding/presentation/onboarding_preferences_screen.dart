import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/training_preferences_providers.dart';
import '../domain/training_preferences.dart';

class OnboardingPreferencesScreen extends ConsumerStatefulWidget {
  const OnboardingPreferencesScreen({super.key});

  @override
  ConsumerState<OnboardingPreferencesScreen> createState() =>
      _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState
    extends ConsumerState<OnboardingPreferencesScreen> {
  int _daysPerWeek = 3;
  int _minutesPerSession = 30;
  TrainingLocation _location = TrainingLocation.home;
  final Set<Equipment> _equipment = {};
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final preferences = TrainingPreferences(
      daysPerWeek: _daysPerWeek,
      minutesPerSession: _minutesPerSession,
      location: _location,
      equipment: _equipment,
    );

    await ref.read(trainingPreferencesRepositoryProvider).save(preferences);

    ref.invalidate(latestTrainingPreferencesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda e equipamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dias por semana: $_daysPerWeek'),
          Slider(
            value: _daysPerWeek.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            label: '$_daysPerWeek',
            onChanged: (v) => setState(() => _daysPerWeek = v.round()),
          ),
          Text('Minutos por sessão: $_minutesPerSession'),
          Slider(
            value: _minutesPerSession.toDouble(),
            min: 15,
            max: 90,
            divisions: 15,
            label: '$_minutesPerSession',
            onChanged: (v) => setState(() => _minutesPerSession = v.round()),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<TrainingLocation>(
            initialValue: _location,
            decoration: const InputDecoration(labelText: 'Local principal'),
            items: TrainingLocation.values
                .map(
                  (l) => DropdownMenuItem(value: l, child: Text(l.label)),
                )
                .toList(),
            onChanged: (v) => setState(() => _location = v ?? _location),
          ),
          const SizedBox(height: 16),
          const Text('Equipamento disponível'),
          ...Equipment.values.map(
            (e) => CheckboxListTile(
              title: Text(e.label),
              value: _equipment.contains(e),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _equipment.add(e);
                } else {
                  _equipment.remove(e);
                }
              }),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
