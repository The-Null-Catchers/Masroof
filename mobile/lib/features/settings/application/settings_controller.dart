import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

@immutable
class AppSettings {
  const AppSettings({required this.locale, required this.themeMode});

  final Locale locale;
  final ThemeMode themeMode;

  bool get isArabic => locale.languageCode == 'ar';

  AppSettings copyWith({Locale? locale, ThemeMode? themeMode}) =>
      AppSettings(locale: locale ?? this.locale, themeMode: themeMode ?? this.themeMode);
}

final settingsControllerProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Device-level preferences that apply before sign-in (language, theme).
class SettingsController extends Notifier<AppSettings> {
  static const _localeKey = 'settings.locale';
  static const _themeKey = 'settings.theme';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_localeKey);
    final device = PlatformDispatcher.instance.locale.languageCode;
    final code = saved ?? (device == 'en' ? 'en' : 'ar');
    final theme = ThemeMode.values.byName(prefs.getString(_themeKey) ?? ThemeMode.system.name);
    return AppSettings(locale: Locale(code), themeMode: theme);
  }

  Future<void> setLocale(String code) async {
    await ref.read(sharedPreferencesProvider).setString(_localeKey, code);
    state = state.copyWith(locale: Locale(code));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_themeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }
}
