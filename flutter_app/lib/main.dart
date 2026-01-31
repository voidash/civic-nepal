import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'l10n/app_localizations.dart';

/// Custom delegate that provides fallback for unsupported locales
/// Newari ('new') falls back to Nepali ('ne') for Material components
class _FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  // Supported locales by GlobalMaterialLocalizations (subset relevant to us)
  static const _supportedLocales = {'en', 'ne'};

  @override
  bool isSupported(Locale locale) => true; // We handle all locales with fallback

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    // Use the locale if supported, otherwise fall back to Nepali
    final effectiveLocale = _supportedLocales.contains(locale.languageCode)
        ? locale
        : const Locale('ne');
    return GlobalMaterialLocalizations.delegate.load(effectiveLocale);
  }

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

/// Custom delegate for Cupertino localizations with fallback
class _FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  static const _supportedLocales = {'en', 'ne'};

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final effectiveLocale = _supportedLocales.contains(locale.languageCode)
        ? locale
        : const Locale('ne');
    return GlobalCupertinoLocalizations.delegate.load(effectiveLocale);
  }

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}

void main() async {
  // Use hash URLs on web (e.g., /#/calendar) - works without server config
  // Path URLs (e.g., /calendar) require server-side SPA routing configuration
  // which isn't always available, so hash URLs are more reliable
  // To use path URLs, uncomment the line below and configure your web server
  // usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform-specific services (not available on web)
  if (!kIsWeb) {
    await NotificationService.initialize();
    await BackgroundService.initialize();
    await BackgroundService.registerIpoCheckTask();

    // Restore sticky notification if it was enabled
    await _restoreStickyNotificationIfEnabled();
  }

  runApp(
    const ProviderScope(
      child: NagarikCalendarApp(),
    ),
  );
}

/// Restores the sticky date notification if it was previously enabled
/// This ensures the notification persists after app restart or device reboot
Future<void> _restoreStickyNotificationIfEnabled() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('sticky_date_notification') ?? false;
    if (isEnabled) {
      await NotificationService.showStickyDateNotification();
    }
  } catch (e) {
    // Silently fail - notification restoration is not critical
  }
}

class NagarikCalendarApp extends ConsumerStatefulWidget {
  const NagarikCalendarApp({super.key});

  @override
  ConsumerState<NagarikCalendarApp> createState() => _NagarikCalendarAppState();
}

class _NagarikCalendarAppState extends ConsumerState<NagarikCalendarApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-show sticky notification when app comes to foreground
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      _restoreStickyNotificationIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    // Determine theme and locale from settings, with defaults during loading
    final themeMode = settingsAsync.when(
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
      data: (settings) => switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
    );

    final localeCode = settingsAsync.when(
      loading: () => 'ne',
      error: (_, __) => 'ne',
      data: (settings) => settings.appLocale,
    );

    final appLocale = AppLocale.fromCode(localeCode);

    // Always use MaterialApp.router to preserve URL on web
    // This ensures direct URL navigation works (e.g., /calendar loads calendar)
    return MaterialApp.router(
      title: 'NagarikCalendar',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeMode,
      locale: appLocale.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        _FallbackMaterialLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        _FallbackCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: [
        for (final locale in AppLocale.values) locale.locale,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}

// NagarikCalendar theme colors
const _primaryColor = Color(0xFF1976D2); // Material Blue 700
const _secondaryColor = Color(0xFF0D47A1); // Deep blue for accents
const _accentGold = Color(0xFFFFB300); // Amber accent

ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      tertiary: _accentGold,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
      surfaceContainerHighest: const Color(0xFFF5F5F5),
      primaryContainer: _primaryColor.withValues(alpha: 0.12),
      onPrimaryContainer: _primaryColor,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[200],
      thickness: 1,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[100],
      selectedColor: _primaryColor.withValues(alpha: 0.2),
      labelStyle: const TextStyle(fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: const Color(0xFF64B5F6), // Lighter blue for dark mode
      onSecondary: Colors.white,
      tertiary: _accentGold,
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFE0E0E0),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      primaryContainer: _primaryColor.withValues(alpha: 0.2),
      onPrimaryContainer: const Color(0xFF90CAF9), // Light blue tint
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E1E1E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: _primaryColor,
      unselectedItemColor: Color(0xFF9E9E9E),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF333333),
      thickness: 1,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      selectedColor: _primaryColor.withValues(alpha: 0.3),
      labelStyle: const TextStyle(fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
