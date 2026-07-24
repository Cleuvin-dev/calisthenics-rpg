import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rpg_providers.dart';

/// Indicador compacto de nível/XP (RPG_SYSTEM.md §1 — "participação e
/// jornada", não libera exercício).
class XpLevelBadge extends ConsumerWidget {
  const XpLevelBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(levelProgressProvider);

    return levelAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (progress) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(child: Text('${progress.level}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nível ${progress.level}'),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.progress.clamp(0, 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${progress.currentLevelXp}/${progress.xpForNextLevel} XP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
