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
  static const String _keyStickyDateNotification = 'sticky_date_notification';
  static const String _keyIpoNotifications = 'ipo_notifications';
  static const String _keyAppLocale = 'app_locale';

  @override
  Future<SettingsData> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsData(
      languagePreference: prefs.getString(_keyLanguage) ?? 'both',
      viewModeDefault: prefs.getString(_keyViewMode) ?? 'paragraph',
      meaningModeEnabled: prefs.getBool(_keyMeaningMode) ?? true,
      autoCheckUpdates: prefs.getBool(_keyAutoCheckUpdates) ?? true,
      themeMode: prefs.getString(_keyThemeMode) ?? 'system',
      stickyDateNotification: prefs.getBool(_keyStickyDateNotification) ?? false,
      ipoNotifications: prefs.getBool(_keyIpoNotifications) ?? true,
      appLocale: prefs.getString(_keyAppLocale) ?? 'ne', // Default to Nepali
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

  Future<void> setStickyDateNotification(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStickyDateNotification, enabled);
    state = AsyncValue.data(current.copyWith(stickyDateNotification: enabled));
  }

  Future<void> setIpoNotifications(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIpoNotifications, enabled);
    state = AsyncValue.data(current.copyWith(ipoNotifications: enabled));
  }

  Future<void> setAppLocale(String localeCode) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLocale, localeCode);
    state = AsyncValue.data(current.copyWith(appLocale: localeCode));
  }
}

/// Immutable settings data class
class SettingsData {
  final String languagePreference;
  final String viewModeDefault;
  final bool meaningModeEnabled;
  final bool autoCheckUpdates;
  final String themeMode; // 'light', 'dark', 'system'
  final bool stickyDateNotification;
  final bool ipoNotifications;
  final String appLocale; // 'ne', 'en', 'new'

  const SettingsData({
    required this.languagePreference,
    required this.viewModeDefault,
    required this.meaningModeEnabled,
    required this.autoCheckUpdates,
    required this.themeMode,
    required this.stickyDateNotification,
    required this.ipoNotifications,
    required this.appLocale,
  });

  SettingsData copyWith({
    String? languagePreference,
    String? viewModeDefault,
    bool? meaningModeEnabled,
    bool? autoCheckUpdates,
    String? themeMode,
    bool? stickyDateNotification,
    bool? ipoNotifications,
    String? appLocale,
  }) {
    return SettingsData(
      languagePreference: languagePreference ?? this.languagePreference,
      viewModeDefault: viewModeDefault ?? this.viewModeDefault,
      meaningModeEnabled: meaningModeEnabled ?? this.meaningModeEnabled,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      themeMode: themeMode ?? this.themeMode,
      stickyDateNotification: stickyDateNotification ?? this.stickyDateNotification,
      ipoNotifications: ipoNotifications ?? this.ipoNotifications,
      appLocale: appLocale ?? this.appLocale,
    );
  }
}
