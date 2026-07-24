import 'package:flutter/material.dart';

/// Tema escuro com identidade de "game" (pedido do usuário): violeta
/// vibrante como cor principal, dourado/âmbar reservado para XP e
/// conquistas (via `colorScheme.tertiary`), cantos arredondados e
/// tipografia com mais peso visual. Sem dependências externas de fonte
/// ou ícone — só `ThemeData`/`ColorScheme` puros do Flutter.
ThemeData buildCalisthenicsRpgTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C4DFF),
    brightness: Brightness.dark,
  ).copyWith(
    tertiary: const Color(0xFFFFC947),
    tertiaryContainer: const Color(0xFF5C4400),
    onTertiaryContainer: const Color(0xFFFFDFA0),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHigh,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.tertiary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
    ),
  );
}

/// Cor de destaque para XP/recompensas em qualquer tela — dourado, para
/// diferenciar visualmente de progressão física (que usa a cor
/// primária).
extension XpColor on ColorScheme {
  Color get xpAccent => tertiary;
}
