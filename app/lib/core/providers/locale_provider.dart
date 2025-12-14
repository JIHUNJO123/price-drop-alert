import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language provider for managing app locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  static const _key = 'app_locale';

  /// Supported locales
  static const supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('pt'), // Portuguese
    Locale('de'), // German
    Locale('fr'), // French
    Locale('ja'), // Japanese
    Locale('ko'), // Korean
  ];

  /// Language names for display
  static const languageNames = {
    'en': 'English',
    'es': 'Español',
    'pt': 'Português',
    'de': 'Deutsch',
    'fr': 'Français',
    'ja': '日本語',
    'ko': '한국어',
  };

  /// Get display name for locale
  static String getLanguageName(String code) {
    return languageNames[code] ?? code;
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = Locale(code);
    }
    // null means use system locale
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    state = locale;
  }

  /// Check if using system locale (null state)
  bool get isSystemLocale => state == null;
}
