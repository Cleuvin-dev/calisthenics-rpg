import 'package:flutter/material.dart';

import '../core/database/app_database.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/journey/presentation/journey_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Shell raiz do app. O IndexedStack mantém árvore, estado e posição de
/// rolagem das quatro abas enquanto a navegação interna continua usando o
/// Navigator já adotado pelo projeto.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.record,
    required this.preferences,
    required this.placement,
  });

  final TrainingPlanRecord record;
  final TrainingPreferenceRecord preferences;
  final CapabilityEstimateRecord placement;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          JourneyScreen(
            key: const PageStorageKey('training-tab'),
            record: widget.record,
            preferences: widget.preferences,
            placement: widget.placement,
          ),
          DiscoverScreen(
            key: const PageStorageKey('discover-tab'),
            placement: widget.placement,
          ),
          const ReportScreen(key: PageStorageKey('report-tab')),
          SettingsScreen(
            key: const PageStorageKey('settings-tab'),
            preferences: widget.preferences,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Treino',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Descobrir',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Relatório',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Definição',
          ),
        ],
      ),
    );
  }
}
