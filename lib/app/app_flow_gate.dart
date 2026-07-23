import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/assessment/data/capability_estimate_providers.dart';
import '../features/assessment/presentation/assessment_skip_test_screen.dart';
import '../features/assessment/presentation/placement_result_screen.dart';
import '../features/onboarding/data/training_preferences_providers.dart';
import '../features/onboarding/presentation/onboarding_preferences_screen.dart';
import '../features/safety/data/safety_screening_providers.dart';
import '../features/safety/domain/screening_result.dart';
import '../features/safety/presentation/safety_blocked_screen.dart';
import '../features/safety/presentation/safety_screening_screen.dart';

/// Decide reativamente qual etapa da primeira história vertical mostrar,
/// com base no que já existe no banco local: triagem -> onboarding ->
/// colocação -> resumo. Cada tela, ao salvar, invalida o provider
/// correspondente e este widget reconstrói para a próxima etapa.
class AppFlowGate extends ConsumerWidget {
  const AppFlowGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screeningAsync = ref.watch(latestSafetyScreeningProvider);

    return screeningAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) => _ErrorScreen(message: '$error'),
      data: (screening) {
        if (screening == null) {
          return const SafetyScreeningScreen();
        }

        final result = ScreeningResult.values.byName(screening.result);
        if (result.blocksAssessment) {
          return SafetyBlockedScreen(result: result);
        }

        return const _AfterScreeningGate();
      },
    );
  }
}

class _AfterScreeningGate extends ConsumerWidget {
  const _AfterScreeningGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(latestTrainingPreferencesProvider);

    return preferencesAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) => _ErrorScreen(message: '$error'),
      data: (preferences) {
        if (preferences == null) {
          return const OnboardingPreferencesScreen();
        }
        return const _AfterPreferencesGate();
      },
    );
  }
}

class _AfterPreferencesGate extends ConsumerWidget {
  const _AfterPreferencesGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync =
        ref.watch(latestCapabilityEstimateProvider('push_horizontal'));

    return placementAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) => _ErrorScreen(message: '$error'),
      data: (placement) {
        if (placement == null) {
          return const AssessmentSkipTestScreen();
        }
        return PlacementResultScreen(estimate: placement);
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Erro: $message')));
  }
}
