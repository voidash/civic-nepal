import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

/// Provider for app settings
@riverpod
class Settings extends _$Settings {
  static const String _keyLanguage = 'language_preference';
  static const String _keyViewMode = 'view_mode_default';
  static const String _keyMeaningMode = 'meaning_mode_enabled';
  static const String _keyAutoCheckUpdates = 'auto_check_updates';
  static const String _keyThemeMode = 'theme_mode';

  @override
  Future<SettingsData> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsData(
      languagePreference: prefs.getString(_keyLanguage) ?? 'both',
      viewModeDefault: prefs.getString(_keyViewMode) ?? 'paragraph',
      meaningModeEnabled: prefs.getBool(_keyMeaningMode) ?? true,
      autoCheckUpdates: prefs.getBool(_keyAutoCheckUpdates) ?? true,
      themeMode: prefs.getString(_keyThemeMode) ?? 'system',
    );
  }

  Future<void> setLanguagePreference(String language) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
    state = AsyncValue.data(current.copyWith(languagePreference: language));
  }

  Future<void> setViewModeDefault(String mode) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyViewMode, mode);
    state = AsyncValue.data(current.copyWith(viewModeDefault: mode));
  }

  Future<void> setMeaningModeEnabled(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMeaningMode, enabled);
    state = AsyncValue.data(current.copyWith(meaningModeEnabled: enabled));
  }

  Future<void> setAutoCheckUpdates(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCheckUpdates, enabled);
    state = AsyncValue.data(current.copyWith(autoCheckUpdates: enabled));
  }

  Future<void> setThemeMode(String mode) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
    state = AsyncValue.data(current.copyWith(themeMode: mode));
  }
}

/// Immutable settings data class
class SettingsData {
  final String languagePreference;
  final String viewModeDefault;
  final bool meaningModeEnabled;
  final bool autoCheckUpdates;
  final String themeMode; // 'light', 'dark', 'system'

  const SettingsData({
    required this.languagePreference,
    required this.viewModeDefault,
    required this.meaningModeEnabled,
    required this.autoCheckUpdates,
    required this.themeMode,
  });

  SettingsData copyWith({
    String? languagePreference,
    String? viewModeDefault,
    bool? meaningModeEnabled,
    bool? autoCheckUpdates,
    String? themeMode,
  }) {
    return SettingsData(
      languagePreference: languagePreference ?? this.languagePreference,
      viewModeDefault: viewModeDefault ?? this.viewModeDefault,
      meaningModeEnabled: meaningModeEnabled ?? this.meaningModeEnabled,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
