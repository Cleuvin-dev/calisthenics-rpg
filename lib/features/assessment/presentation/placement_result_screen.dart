import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../domain/conservative_placement.dart';
import 'assessment_skip_test_screen.dart';

/// Saída explicável da colocação (INITIAL_ASSESSMENT.md §9): variação
/// atual, motivo, confiança e validade — sem prometer domínio.
class PlacementResultScreen extends StatelessWidget {
  const PlacementResultScreen({super.key, required this.estimate});

  final CapabilityEstimateRecord estimate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sua colocação inicial')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Empurrar horizontal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              estimate.levelName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              estimate.reasonCode == PlacementReasonCode.skippedEntirely.name
                  ? 'Por que essa variação: você optou por não responder '
                      'agora, então usamos o nó mais conservador possível.'
                  : 'Por que essa variação: colocação conservadora, um '
                      'nível abaixo do que você relatou, porque o teste '
                      'prático foi pulado.',
            ),
            const SizedBox(height: 8),
            const Text('Confiança: baixa (autorrelato, sem teste prático)'),
            const SizedBox(height: 8),
            Text(
              'Válida até: ${_formatDate(estimate.validUntil)} — depois '
              'disso, uma nova confirmação é recomendada.',
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AssessmentSkipTestScreen(),
                ),
              ),
              child: const Text('Refazer colocação'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Esta é a primeira história implementada até agora: triagem, '
              'agenda/equipamento e colocação conservadora. Motor de '
              'treino, sessões e XP ainda não existem.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
