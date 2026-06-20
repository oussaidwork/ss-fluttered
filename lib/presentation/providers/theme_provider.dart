import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that tracks the active [ThemeMode] (light / dark / system).
///
/// Persists the choice to `SharedPreferences` under the key `theme_mode`.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadSaved();
    return ThemeMode.dark;
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key) ?? 'dark';
      state = _fromString(raw);
    } catch (_) {
      // fallback to default
    }
  }

  /// Replace the current theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _persist();
  }

  /// Toggle between light and dark.
  Future<void> toggleTheme() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _toString(state));
    } catch (_) {
      // ignore persistence failures
    }
  }

  static String _toString(ThemeMode mode) => mode.name;
  static ThemeMode _fromString(String s) => ThemeMode.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ThemeMode.dark,
      );
}
