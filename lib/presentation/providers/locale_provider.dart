import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that tracks the current locale for i18n.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Supported locales for the application.
const List<Locale> supportedLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('ar'),
];

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSavedLocale();
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale') ?? 'en';
      if (supportedLocales.any((l) => l.languageCode == code)) {
        state = Locale(code);
      }
    } catch (_) {
      // Fall back to default
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) return;
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', locale.languageCode);
    } catch (_) {
      // Ignore persistence errors
    }
  }

  /// Returns the text direction for the current locale.
  TextDirection get textDirection =>
      state.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
}
