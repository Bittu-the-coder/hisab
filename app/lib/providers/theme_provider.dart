import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier([ThemeMode initial = ThemeMode.system]) : super(initial);

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _save();
  }

  void set(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final key = state == ThemeMode.light ? 'light' : state == ThemeMode.dark ? 'dark' : 'system';
    await prefs.setString('theme_mode', key);
  }

  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('theme_mode') ?? 'system';
    switch (key) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final initial = ref.watch(initialThemeModeProvider);
  return ThemeModeNotifier(initial);
});
