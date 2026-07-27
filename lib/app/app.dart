import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/data/settings_providers.dart';
import 'app_flow_gate.dart';
import 'theme.dart';

class CalisthenicsRpgApp extends ConsumerWidget {
  const CalisthenicsRpgApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider).value;
    final textScale = settings?.textScale ?? 1.0;
    return MaterialApp(
      title: 'Calisthenics RPG',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: buildCalisthenicsRpgTheme(
        highContrast: settings?.highContrast ?? false,
      ),
      theme: buildCalisthenicsRpgTheme(
        highContrast: settings?.highContrast ?? false,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              (mediaQuery.textScaler.scale(1) * textScale).clamp(0.8, 2.0),
            ),
            disableAnimations:
                settings?.reduceMotion ?? mediaQuery.disableAnimations,
          ),
          child: child!,
        );
      },
      home: const AppFlowGate(),
    );
  }
}
