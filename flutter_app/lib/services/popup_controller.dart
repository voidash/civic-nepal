import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Controls the Flutter window between two modes:
///
///  • **Popup mode** — small (320×520), borderless, always-on-top, positioned
///    near the screen edge (bottom-right on Windows, top-right on macOS).
///    Hidden by default; shown/hidden by the native tray app via TrayServer.
///
///  • **Full-app mode** — normal window (1280×720), centred, with title bar.
///    Activated when the user clicks "Open Nagarik Patro" in the popup.
///
/// The controller is a singleton; call [initialize] once before [runApp].
class PopupController extends WindowListener {
  static final instance = PopupController._();
  PopupController._();

  static const _popupSize = Size(320, 520);
  static const _fullSize = Size(1280, 720);

  // Injected by main.dart so we can navigate without a BuildContext.
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // Platform channel for macOS Dock visibility toggle.
  static const _channel = MethodChannel('com.nagarikpatro/app');

  bool _isPopupMode = true;

  Future<void> initialize() async {
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: _popupSize,
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      // Start hidden — tray icon click will show it.
      await windowManager.hide();
    });

    windowManager.addListener(this);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> showPopup() async {
    _isPopupMode = true;
    await _applyPopupStyle();
    await _positionPopup();
    await windowManager.show();
    await windowManager.focus();
    if (Platform.isMacOS) _setDockHidden(true);
  }

  Future<void> hidePopup() async {
    await windowManager.hide();
  }

  Future<void> toggle() async {
    if (await windowManager.isVisible()) {
      await hidePopup();
    } else {
      await showPopup();
    }
  }

  Future<void> expandToFullApp() async {
    _isPopupMode = false;
    if (Platform.isMacOS) _setDockHidden(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setSize(_fullSize);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();

    // Navigate to the main app shell.
    _navigatorKey?.currentContext?.let((ctx) {
      // Use Navigator directly to avoid circular import on go_router.
      Navigator.of(ctx, rootNavigator: true)
          .pushNamedAndRemoveUntil('/home', (_) => false);
    });
  }

  // ---------------------------------------------------------------------------
  // WindowListener — intercept close to hide instead of quit
  // ---------------------------------------------------------------------------

  @override
  void onWindowClose() async {
    if (_isPopupMode) {
      // Popup closed → just hide, keep app alive for tray.
      await windowManager.hide();
    } else {
      // Full-app closed → shrink back to popup mode and hide.
      _isPopupMode = true;
      if (Platform.isMacOS) _setDockHidden(true);
      await _applyPopupStyle();
      await windowManager.hide();
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _applyPopupStyle() async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setSize(_popupSize);
  }

  Future<void> _positionPopup() async {
    try {
      final display = await windowManager.getPrimaryDisplay();
      // visibleFrame accounts for taskbar (Windows) / menu bar + dock (macOS).
      final frame = display.visibleFrame;
      const margin = 8.0;

      final double x;
      final double y;

      if (Platform.isMacOS) {
        // Top-right corner, just below the menu bar.
        x = frame.left + frame.width - _popupSize.width - margin;
        y = frame.top + margin;
      } else {
        // Bottom-right corner, just above the taskbar.
        x = frame.left + frame.width - _popupSize.width - margin;
        y = frame.top + frame.height - _popupSize.height - margin;
      }

      await windowManager.setPosition(Offset(x, y));
    } catch (e) {
      // Fallback: center if display info unavailable.
      await windowManager.center();
    }
  }

  /// macOS: show/hide the Dock icon depending on mode.
  void _setDockHidden(bool hidden) {
    _channel.invokeMethod('setActivationPolicy', hidden).catchError((_) {});
  }
}

extension _ContextExt on BuildContext {
  T? let<T>(T? Function(BuildContext) fn) => fn(this);
}
