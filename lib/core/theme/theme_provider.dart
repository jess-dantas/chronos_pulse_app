import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeMode? initialMode})
      : _themeMode = initialMode ?? ThemeMode.light;

  static const _chaveTema = 'chronos_theme_mode';

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static Future<ThemeMode> carregarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_chaveTema);
    return valor == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveTema, _themeMode.name);
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _persistir();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      await _persistir();
    }
  }
}