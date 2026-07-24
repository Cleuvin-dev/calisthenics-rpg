import 'package:flutter/material.dart';

import '../domain/mission.dart';

class MissionList extends StatelessWidget {
  const MissionList({super.key, required this.title, required this.missions});

  final String title;
  final List<MissionEvaluationResult> missions;

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final mission in missions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  mission.completed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: mission.completed
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(mission.definition.titlePtBr),
                subtitle: mission.progressLabel == null
                    ? null
                    : Text(mission.progressLabel!),
                trailing: Text('+${mission.definition.xpReward} XP'),
              ),
          ],
        ),
      ),
    );
  }
}
