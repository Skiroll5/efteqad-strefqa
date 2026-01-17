import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Theme Controller ---
final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController();
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode');
    if (themeString != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString());
  }
}

// --- Locale Controller ---
final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('ar')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }
}

// --- Statistics Settings Controller ---
final statisticsSettingsProvider =
    StateNotifierProvider<StatisticsSettingsController, int>((ref) {
      return StatisticsSettingsController();
    });

class StatisticsSettingsController extends StateNotifier<int> {
  StatisticsSettingsController() : super(3) {
    _loadThreshold();
  }

  Future<void> _loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt('atRiskThreshold');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setThreshold(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('atRiskThreshold', value);
  }
}

// --- Default Note Controller ---
final defaultNoteProvider =
    StateNotifierProvider<DefaultNoteController, String>((ref) {
      return DefaultNoteController();
    });

class DefaultNoteController extends StateNotifier<String> {
  DefaultNoteController() : super('مدارس الأحد') {
    _loadNote();
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('defaultAttendanceNote');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setNote(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultAttendanceNote', value);
  }
}
