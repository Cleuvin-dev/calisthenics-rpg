import 'package:flutter/material.dart';

/// Tema escuro com os tokens de cor de
/// `VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md` §4.2: verde-menta como cor
/// de ação principal, violeta reservado só para XP/recompensas (via
/// `colorScheme.tertiary`), superfícies em quase-preto com três níveis de
/// elevação. Sem dependências externas de fonte ou ícone — só
/// `ThemeData`/`ColorScheme` puros do Flutter.
const _surfaceCanvas = Color(0xFF080A0B);
const _surfaceCard = Color(0xFF141819);
const _surfaceElevated = Color(0xFF1B2021);
const _brandPrimary = Color(0xFF35E6A1);
const _brandPrimaryPressed = Color(0xFF20C987);
const _rpgXp = Color(0xFF8B5CF6);
const _textPrimary = Color(0xFFF7F9F8);
const _textSecondary = Color(0xFFA7B0AD);
const _stateWarning = Color(0xFFF4B740);
const _stateDanger = Color(0xFFF45B69);
const _divider = Color(0xFF2A302F);

ThemeData buildCalisthenicsRpgTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: _brandPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: _brandPrimary,
        onPrimary: const Color(0xFF06231A),
        primaryContainer: _brandPrimaryPressed,
        onPrimaryContainer: const Color(0xFF06231A),
        secondary: _brandPrimaryPressed,
        onSecondary: const Color(0xFF06231A),
        tertiary: _rpgXp,
        tertiaryContainer: const Color(0xFF2E1D66),
        onTertiaryContainer: const Color(0xFFE4DBFF),
        surface: _surfaceCanvas,
        onSurface: _textPrimary,
        onSurfaceVariant: _textSecondary,
        surfaceContainerHigh: _surfaceCard,
        surfaceContainerHighest: _surfaceElevated,
        error: _stateDanger,
        onError: const Color(0xFF3A0A10),
        outline: _divider,
        outlineVariant: _divider,
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

/// Cor de destaque para XP/recompensas em qualquer tela — violeta
/// (`rpg.xp` no documento), reservada só para isso, para diferenciar
/// visualmente de progressão física (que usa a cor primária verde-menta).
extension XpColor on ColorScheme {
  Color get xpAccent => tertiary;

  /// `state.warning` do documento — sem slot próprio no `ColorScheme`
  /// padrão do Material.
  Color get stateWarning => _stateWarning;
}
