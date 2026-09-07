import 'package:flutter/material.dart';

class AppTheme {
  static const Color primarySeed = Colors.deepPurple;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E2E),
    ),
    scaffoldBackgroundColor: const Color(0xFF12121A),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E2E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181825),
      centerTitle: false,
      elevation: 0,
    ),
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Superfície no tom lilás claro (avatares, chips, selos, cards de destaque).
  /// No modo claro mantém o tom atual (primary com `lightAlpha`);
  /// no modo escuro usa um lilás mais escuro para manter o destaque sobre o fundo escuro.
  static Color lilasSurface(BuildContext context, {double lightAlpha = 0.1}) =>
      isDark(context)
          ? const Color(0xFF342A5C)
          : primarySeed.withValues(alpha: lightAlpha);

  /// Ícones e textos aplicados sobre [lilasSurface].
  static Color onLilasSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFFC5B3E8) : const Color(0xFF4527A0);

  /// Borda lilás para superfícies (selos, cards selecionados).
  static Color lilasBorder(BuildContext context) =>
      isDark(context)
          ? onLilasSurface(context).withValues(alpha: 0.45)
          : Colors.deepPurple.shade200;

  /// Cor de fundo de ações primárias (botões principais e CTA).
  /// No modo escuro usa um lilás mais escuro, evitando o tom pastel claro
  /// gerado pelo colorScheme.primary (derivado do seed deepPurple).
  static Color primaryAction(BuildContext context) =>
      isDark(context) ? const Color(0xFF5E35B1) : primarySeed;
}
