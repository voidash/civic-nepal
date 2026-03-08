import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Bridges Flutter tray settings to native tray apps by writing
/// tray_settings.json to the shared NagarikPatro app-data directory.
///
///  • Windows: %APPDATA%\NagarikPatro\tray_settings.json
///  • macOS  : ~/Library/Application Support/NagarikPatro/tray_settings.json
///
/// The native tray apps watch this file for changes and update immediately.
class TraySettingsService {
  static const _fileName = 'tray_settings.json';

  static Directory? _dir() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData == null) return null;
      return Directory('$appData\\NagarikPatro');
    }
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home == null) return null;
      return Directory('$home/Library/Application Support/NagarikPatro');
    }
    return null;
  }

  static File? _file() {
    final dir = _dir();
    return dir == null ? null : File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  /// Read current tray settings (synchronous, safe to call on any isolate).
  static TraySettings read() {
    try {
      final file = _file();
      if (file == null || !file.existsSync()) return const TraySettings();
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return TraySettings.fromJson(map);
    } catch (e) {
      debugPrint('TraySettingsService.read: $e');
      return const TraySettings();
    }
  }

  /// Write tray settings to disk. Creates parent directory if needed.
  static Future<void> write(TraySettings settings) async {
    try {
      final dir = _dir();
      if (dir == null) return;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      const enc = JsonEncoder.withIndent('  ');
      await _file()!.writeAsString(enc.convert(settings.toJson()));
    } catch (e) {
      debugPrint('TraySettingsService.write: $e');
    }
  }
}

/// Tray settings value object — the schema native apps read.
class TraySettings {
  /// Which language to display the Nepali date in the tray label. 'nepali' | 'english'
  final String menuBarLanguage;

  /// Show the BS year alongside the date in the tray label / tooltip.
  final bool showYearInTray;

  /// Whether the native tray app should register as a login item.
  final bool launchAtLogin;

  /// Whether the tray icon should be visible at all.
  final bool showTrayWidget;

  const TraySettings({
    this.menuBarLanguage = 'nepali',
    this.showYearInTray = false,
    this.launchAtLogin = false,
    this.showTrayWidget = true,
  });

  factory TraySettings.fromJson(Map<String, dynamic> json) => TraySettings(
        menuBarLanguage: (json['menuBarLanguage'] as String?) ?? 'nepali',
        showYearInTray: (json['showYearInTray'] as bool?) ?? false,
        launchAtLogin: (json['launchAtLogin'] as bool?) ?? false,
        showTrayWidget: (json['showTrayWidget'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'menuBarLanguage': menuBarLanguage,
        'showYearInTray': showYearInTray,
        'launchAtLogin': launchAtLogin,
        'showTrayWidget': showTrayWidget,
      };

  TraySettings copyWith({
    String? menuBarLanguage,
    bool? showYearInTray,
    bool? launchAtLogin,
    bool? showTrayWidget,
  }) =>
      TraySettings(
        menuBarLanguage: menuBarLanguage ?? this.menuBarLanguage,
        showYearInTray: showYearInTray ?? this.showYearInTray,
        launchAtLogin: launchAtLogin ?? this.launchAtLogin,
        showTrayWidget: showTrayWidget ?? this.showTrayWidget,
      );
}
