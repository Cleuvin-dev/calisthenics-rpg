import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../domain/workout_catalog.dart';
import 'workout_detail_screen.dart';

/// Catálogo visual de treinos (SCREENS_AND_FLOWS.md §2, seção "Treino").
/// Lista de treinos nomeados e curados — só "Treino A · Fundação" nesta
/// entrega (ver `workout_catalog.dart`).
class WorkoutCatalogScreen extends StatelessWidget {
  const WorkoutCatalogScreen({super.key, required this.placement});

  final CapabilityEstimateRecord placement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final workout in workoutCatalog)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(workout.namePtBr),
                subtitle: Text(
                  '${workout.objectivePtBr}\n'
                  '${workout.level.labelPtBr} · ${workout.exercises.length} '
                  'exercícios · ~${workout.estimatedMinutes} min',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      workout: workout,
                      placement: placement,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
