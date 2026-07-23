import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/safety_screening_providers.dart';
import '../domain/screening_answers.dart';
import '../domain/screening_classifier.dart';

class SafetyScreeningScreen extends ConsumerStatefulWidget {
  const SafetyScreeningScreen({super.key});

  @override
  ConsumerState<SafetyScreeningScreen> createState() =>
      _SafetyScreeningScreenState();
}

class _SafetyScreeningScreenState
    extends ConsumerState<SafetyScreeningScreen> {
  bool _cardio = false;
  bool _chestPain = false;
  bool _fainting = false;
  bool _boneJoint = false;
  bool _medications = false;
  bool _pregnant = false;
  bool _currentPain = false;
  final _painLocationController = TextEditingController();
  bool _priorAdvice = false;
  bool _consent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _painLocationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('É preciso aceitar o termo da triagem para continuar.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final answers = ScreeningAnswers(
      hasCardiovascularCondition: _cardio,
      chestPainAtRestOrExertion: _chestPain,
      faintingOrSevereDizziness: _fainting,
      boneJointNeurologicalOrRecentSurgery: _boneJoint,
      medicationsAffectingExercise: _medications,
      pregnantOrPostpartum: _pregnant,
      hasCurrentPain: _currentPain,
      currentPainLocation:
          _currentPain && _painLocationController.text.trim().isNotEmpty
              ? _painLocationController.text.trim()
              : null,
      priorMedicalAdviceToLimitActivity: _priorAdvice,
      consentAccepted: _consent,
    );

    final result = const ScreeningClassifier().classify(answers);

    await ref.read(safetyScreeningRepositoryProvider).save(answers, result);

    ref.invalidate(latestSafetyScreeningProvider);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Triagem de segurança')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Este questionário ajuda a definir um ponto de partida seguro. '
            'Ele não substitui avaliação médica e não é diagnóstico.',
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title:
                const Text('Tenho ou já tive doença cardiovascular conhecida'),
            value: _cardio,
            onChanged: (v) => setState(() => _cardio = v),
          ),
          SwitchListTile(
            title: const Text('Sinto dor no peito em repouso ou esforço'),
            value: _chestPain,
            onChanged: (v) => setState(() => _chestPain = v),
          ),
          SwitchListTile(
            title: const Text(
              'Já desmaiei ou tive tontura importante / falta de ar incomum',
            ),
            value: _fainting,
            onChanged: (v) => setState(() => _fainting = v),
          ),
          SwitchListTile(
            title: const Text(
              'Tenho condição óssea, articular, neurológica ou cirurgia '
              'recente',
            ),
            value: _boneJoint,
            onChanged: (v) => setState(() => _boneJoint = v),
          ),
          SwitchListTile(
            title:
                const Text('Uso medicamento que afeta resposta ao exercício'),
            value: _medications,
            onChanged: (v) => setState(() => _medications = v),
          ),
          SwitchListTile(
            title: const Text('Estou grávido(a) ou em pós-parto'),
            value: _pregnant,
            onChanged: (v) => setState(() => _pregnant = v),
          ),
          SwitchListTile(
            title: const Text('Sinto dor atualmente'),
            value: _currentPain,
            onChanged: (v) => setState(() => _currentPain = v),
          ),
          if (_currentPain)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: TextField(
                controller: _painLocationController,
                decoration:
                    const InputDecoration(labelText: 'Local da dor (opcional)'),
              ),
            ),
          SwitchListTile(
            title: const Text(
              'Já recebi recomendação médica para limitar atividade física',
            ),
            value: _priorAdvice,
            onChanged: (v) => setState(() => _priorAdvice = v),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text(
              'Li e aceito que este app não diagnostica nem substitui '
              'avaliação profissional',
            ),
            value: _consent,
            onChanged: (v) => setState(() => _consent = v),
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
