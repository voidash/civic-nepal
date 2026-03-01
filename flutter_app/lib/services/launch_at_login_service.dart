import 'package:flutter/services.dart';

/// Manages "Launch at Login" on macOS via SMAppService.
class LaunchAtLoginService {
  static const _channel = MethodChannel('com.nagarikpatro/launch_at_login');

  static Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> setEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>('setEnabled', {'enabled': enabled});
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
