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
}
