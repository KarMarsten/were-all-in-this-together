import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeModePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeModePreference.system:
        return ThemeMode.system;
      case AppThemeModePreference.light:
        return ThemeMode.light;
      case AppThemeModePreference.dark:
        return ThemeMode.dark;
    }
  }

  String get label {
    switch (this) {
      case AppThemeModePreference.system:
        return 'System';
      case AppThemeModePreference.light:
        return 'Light';
      case AppThemeModePreference.dark:
        return 'Dark';
    }
  }

  String get description {
    switch (this) {
      case AppThemeModePreference.system:
        return 'Match this device';
      case AppThemeModePreference.light:
        return 'Bright, airy colors';
      case AppThemeModePreference.dark:
        return 'Lower-glare colors';
    }
  }

  static AppThemeModePreference fromWireName(String? value) {
    for (final pref in AppThemeModePreference.values) {
      if (pref.name == value) return pref;
    }
    return AppThemeModePreference.system;
  }
}

abstract class ThemeModePreferenceRepository {
  Future<AppThemeModePreference> load();

  Future<void> save(AppThemeModePreference preference);
}

class SharedPreferencesThemeModePreferenceRepository
    implements ThemeModePreferenceRepository {
  SharedPreferencesThemeModePreferenceRepository({
    required Future<SharedPreferences> Function() preferencesLoader,
  }) : _load = preferencesLoader;

  final Future<SharedPreferences> Function() _load;

  static const String _key = 'appearance.themeMode';

  @override
  Future<AppThemeModePreference> load() async {
    final prefs = await _load();
    return AppThemeModePreference.fromWireName(prefs.getString(_key));
  }

  @override
  Future<void> save(AppThemeModePreference preference) async {
    final prefs = await _load();
    await prefs.setString(_key, preference.name);
  }
}

final themeModePreferenceRepositoryProvider =
    Provider<ThemeModePreferenceRepository>((ref) {
  return SharedPreferencesThemeModePreferenceRepository(
    preferencesLoader: SharedPreferences.getInstance,
  );
});

final themeModePreferenceProvider =
    FutureProvider<AppThemeModePreference>((ref) async {
  final repo = ref.watch(themeModePreferenceRepositoryProvider);
  return repo.load();
});
