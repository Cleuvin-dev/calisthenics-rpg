import 'package:flutter/material.dart';

import '../domain/screening_result.dart';
import 'safety_screening_screen.dart';

/// Bloqueia teste/colocação conforme SAFETY_AND_SCREENING.md §3-4.
/// Mensagens diretas, não alarmistas; nunca afirma "liberado clinicamente".
class SafetyBlockedScreen extends StatelessWidget {
  const SafetyBlockedScreen({super.key, required this.result});

  final ScreeningResult result;

  @override
  Widget build(BuildContext context) {
    final isEmergency = result == ScreeningResult.emergency;

    return Scaffold(
      appBar: AppBar(title: const Text('Antes de continuar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmergency
                  ? 'Suas respostas indicam um sinal que merece atenção '
                      'imediata.'
                  : 'Suas respostas indicam que você deve buscar orientação '
                      'profissional antes de iniciar testes físicos neste '
                      'app.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              isEmergency
                  ? 'Procure atendimento médico adequado antes de qualquer '
                      'atividade física. Este aplicativo não realiza '
                      'diagnóstico nem substitui avaliação profissional.'
                  : 'Converse com um profissional de saúde ou de Educação '
                      'Física habilitado antes de realizar testes de '
                      'esforço ou treinos neste app.',
            ),
            const SizedBox(height: 24),
            const Text(
              'A avaliação e o plano de treino continuam bloqueados até '
              'uma nova triagem.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SafetyScreeningScreen(),
                ),
              ),
              child: const Text('Refazer triagem'),
            ),
          ],
        ),
      ),
    );
  }
}
