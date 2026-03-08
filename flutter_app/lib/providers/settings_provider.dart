import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tray_settings_service.dart';

part 'settings_provider.g.dart';

bool get _isDesktopPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

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
  static const String _keyEarthquakeNotifications = 'earthquake_notifications';
  static const String _keyRoadClosureNotifications = 'road_closure_notifications';
  static const String _keyAppLocale = 'app_locale';
  static const String _keyPinnedRoutes = 'pinned_routes';
  static const String _keyRecentRoutes = 'recent_routes';

  // Tray widget settings (desktop only)
  static const String _keyTrayMenuBarLanguage = 'tray_menu_bar_language';
  static const String _keyTrayShowYear = 'tray_show_year';
  static const String _keyTrayLaunchAtLogin = 'tray_launch_at_login';
  static const String _keyTrayShowWidget = 'tray_show_widget';

  static const int maxPinnedItems = 6;
  static const int maxRecentItems = 5;

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
      earthquakeNotifications: prefs.getBool(_keyEarthquakeNotifications) ?? true, // Default on for safety
      roadClosureNotifications: prefs.getBool(_keyRoadClosureNotifications) ?? false,
      appLocale: prefs.getString(_keyAppLocale) ?? 'ne', // Default to Nepali
      pinnedRoutes: prefs.getStringList(_keyPinnedRoutes) ?? [],
      recentRoutes: prefs.getStringList(_keyRecentRoutes) ?? [],
      trayMenuBarLanguage: prefs.getString(_keyTrayMenuBarLanguage) ?? 'nepali',
      trayShowYear: prefs.getBool(_keyTrayShowYear) ?? false,
      trayLaunchAtLogin: prefs.getBool(_keyTrayLaunchAtLogin) ?? false,
      trayShowWidget: prefs.getBool(_keyTrayShowWidget) ?? true,
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

  Future<void> setEarthquakeNotifications(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEarthquakeNotifications, enabled);
    state = AsyncValue.data(current.copyWith(earthquakeNotifications: enabled));
  }

  Future<void> setRoadClosureNotifications(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRoadClosureNotifications, enabled);
    state = AsyncValue.data(current.copyWith(roadClosureNotifications: enabled));
  }

  Future<void> setAppLocale(String localeCode) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLocale, localeCode);
    state = AsyncValue.data(current.copyWith(appLocale: localeCode));
  }

  // ---------------------------------------------------------------------------
  // Tray widget settings
  // ---------------------------------------------------------------------------

  Future<void> setTrayMenuBarLanguage(String lang) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTrayMenuBarLanguage, lang);
    final next = current.copyWith(trayMenuBarLanguage: lang);
    state = AsyncValue.data(next);
    if (_isDesktopPlatform) await _writeTraySettings(next);
  }

  Future<void> setTrayShowYear(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTrayShowYear, enabled);
    final next = current.copyWith(trayShowYear: enabled);
    state = AsyncValue.data(next);
    if (_isDesktopPlatform) await _writeTraySettings(next);
  }

  Future<void> setTrayLaunchAtLogin(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTrayLaunchAtLogin, enabled);
    final next = current.copyWith(trayLaunchAtLogin: enabled);
    state = AsyncValue.data(next);
    if (_isDesktopPlatform) await _writeTraySettings(next);
  }

  Future<void> setTrayShowWidget(bool enabled) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTrayShowWidget, enabled);
    final next = current.copyWith(trayShowWidget: enabled);
    state = AsyncValue.data(next);
    if (_isDesktopPlatform) await _writeTraySettings(next);
  }

  Future<void> _writeTraySettings(SettingsData s) => TraySettingsService.write(
        TraySettings(
          menuBarLanguage: s.trayMenuBarLanguage,
          showYearInTray: s.trayShowYear,
          launchAtLogin: s.trayLaunchAtLogin,
          showTrayWidget: s.trayShowWidget,
        ),
      );

  /// Toggle a route's pinned status. Returns true if now pinned, false if unpinned.
  Future<bool> togglePin(String route) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    final pinned = List<String>.from(current.pinnedRoutes);

    bool nowPinned;
    if (pinned.contains(route)) {
      pinned.remove(route);
      nowPinned = false;
    } else {
      if (pinned.length >= maxPinnedItems) {
        // Remove oldest pin to make room
        pinned.removeAt(0);
      }
      pinned.add(route);
      nowPinned = true;
    }

    await prefs.setStringList(_keyPinnedRoutes, pinned);
    state = AsyncValue.data(current.copyWith(pinnedRoutes: pinned));
    return nowPinned;
  }

  /// Check if a route is pinned
  bool isPinned(String route) {
    final current = state.valueOrNull;
    return current?.pinnedRoutes.contains(route) ?? false;
  }

  /// Record a visit to a route for recent tracking
  Future<void> recordVisit(String route) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    final recent = List<String>.from(current.recentRoutes);

    // Remove if already in list (will re-add at end)
    recent.remove(route);

    // Add to end (most recent)
    recent.add(route);

    // Trim to max size
    while (recent.length > maxRecentItems) {
      recent.removeAt(0);
    }

    await prefs.setStringList(_keyRecentRoutes, recent);
    state = AsyncValue.data(current.copyWith(recentRoutes: recent));
  }

  /// Clear recent routes
  Future<void> clearRecent() async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyRecentRoutes, []);
    state = AsyncValue.data(current.copyWith(recentRoutes: []));
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
  final bool earthquakeNotifications;
  final bool roadClosureNotifications;
  final String appLocale; // 'ne', 'en', 'new'
  final List<String> pinnedRoutes;
  final List<String> recentRoutes;

  // Tray widget settings (desktop only)
  final String trayMenuBarLanguage; // 'nepali' | 'english'
  final bool trayShowYear;
  final bool trayLaunchAtLogin;
  final bool trayShowWidget;

  const SettingsData({
    required this.languagePreference,
    required this.viewModeDefault,
    required this.meaningModeEnabled,
    required this.autoCheckUpdates,
    required this.themeMode,
    required this.stickyDateNotification,
    required this.ipoNotifications,
    required this.earthquakeNotifications,
    required this.roadClosureNotifications,
    required this.appLocale,
    required this.pinnedRoutes,
    required this.recentRoutes,
    this.trayMenuBarLanguage = 'nepali',
    this.trayShowYear = false,
    this.trayLaunchAtLogin = false,
    this.trayShowWidget = true,
  });

  SettingsData copyWith({
    String? languagePreference,
    String? viewModeDefault,
    bool? meaningModeEnabled,
    bool? autoCheckUpdates,
    String? themeMode,
    bool? stickyDateNotification,
    bool? ipoNotifications,
    bool? earthquakeNotifications,
    bool? roadClosureNotifications,
    String? appLocale,
    List<String>? pinnedRoutes,
    List<String>? recentRoutes,
    String? trayMenuBarLanguage,
    bool? trayShowYear,
    bool? trayLaunchAtLogin,
    bool? trayShowWidget,
  }) {
    return SettingsData(
      languagePreference: languagePreference ?? this.languagePreference,
      viewModeDefault: viewModeDefault ?? this.viewModeDefault,
      meaningModeEnabled: meaningModeEnabled ?? this.meaningModeEnabled,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      themeMode: themeMode ?? this.themeMode,
      stickyDateNotification: stickyDateNotification ?? this.stickyDateNotification,
      ipoNotifications: ipoNotifications ?? this.ipoNotifications,
      earthquakeNotifications: earthquakeNotifications ?? this.earthquakeNotifications,
      roadClosureNotifications: roadClosureNotifications ?? this.roadClosureNotifications,
      appLocale: appLocale ?? this.appLocale,
      pinnedRoutes: pinnedRoutes ?? this.pinnedRoutes,
      recentRoutes: recentRoutes ?? this.recentRoutes,
      trayMenuBarLanguage: trayMenuBarLanguage ?? this.trayMenuBarLanguage,
      trayShowYear: trayShowYear ?? this.trayShowYear,
      trayLaunchAtLogin: trayLaunchAtLogin ?? this.trayLaunchAtLogin,
      trayShowWidget: trayShowWidget ?? this.trayShowWidget,
    );
  }
}
