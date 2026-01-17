import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for fetching JSON data with remote update capability.
///
/// Strategy:
/// 1. On first load, use bundled assets
/// 2. Check for updates in background
/// 3. Cache remote data locally
/// 4. On subsequent loads, use cached data if newer than bundled
class RemoteDataService {
  // TODO: Update this to your actual GitHub repo
  static const String _remoteBaseUrl =
      'https://raw.githubusercontent.com/user/nepal-civic/main/flutter_app/assets/data';

  static const String _versionFile = 'data_version.json';
  static const String _cachePrefix = 'cached_data_';
  static const String _versionPrefix = 'data_version_';

  /// Files that can be fetched remotely
  static const List<String> remoteFiles = [
    'ministers.json',
    'nepali_calendar_events.json',
    'nepali_calendar_auspicious.json',
    'leaders.json',
    'gov_services.json',
  ];

  /// Load JSON data with remote update support
  ///
  /// Returns cached/remote data if available and newer, otherwise bundled asset.
  static Future<Map<String, dynamic>> loadJson(String filename) async {
    // First, load bundled asset (always available)
    final bundled = await _loadBundledAsset(filename);

    // Check if this file supports remote updates
    if (!remoteFiles.contains(filename)) {
      return bundled;
    }

    // Try to get cached version
    final cached = await _getCachedData(filename);
    if (cached != null) {
      // Use cached if it exists (it was fetched from remote previously)
      return cached;
    }

    // Return bundled, and trigger background update
    _checkForUpdatesInBackground(filename);
    return bundled;
  }

  /// Load bundled asset
  static Future<Map<String, dynamic>> _loadBundledAsset(String filename) async {
    final jsonString = await rootBundle.loadString('assets/data/$filename');
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Get cached data if available
  static Future<Map<String, dynamic>?> _getCachedData(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_cachePrefix$filename');
      if (cachedJson != null) {
        return json.decode(cachedJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached data for $filename: $e');
    }
    return null;
  }

  /// Cache data locally
  static Future<void> _cacheData(
      String filename, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$filename', json.encode(data));
    } catch (e) {
      debugPrint('Error caching data for $filename: $e');
    }
  }

  /// Check for updates in background (fire and forget)
  static void _checkForUpdatesInBackground(String filename) {
    // Don't block, just start the check
    _fetchRemoteIfNewer(filename).catchError((e) {
      debugPrint('Background update check failed for $filename: $e');
    });
  }

  /// Fetch remote data if it's newer than what we have
  static Future<void> _fetchRemoteIfNewer(String filename) async {
    try {
      // Fetch remote version info
      final remoteVersion = await _fetchRemoteVersion();
      if (remoteVersion == null) return;

      // Get local version
      final localVersion = await _getLocalVersion(filename);

      // Compare versions
      final remoteFileVersion =
          remoteVersion['files']?[filename]?['version'] as int? ?? 0;
      if (remoteFileVersion > localVersion) {
        // Fetch and cache the new data
        final remoteData = await _fetchRemoteFile(filename);
        if (remoteData != null) {
          await _cacheData(filename, remoteData);
          await _saveLocalVersion(filename, remoteFileVersion);
          debugPrint('Updated $filename to version $remoteFileVersion');
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  /// Fetch remote version file
  static Future<Map<String, dynamic>?> _fetchRemoteVersion() async {
    try {
      final response = await http
          .get(Uri.parse('$_remoteBaseUrl/$_versionFile'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching remote version: $e');
    }
    return null;
  }

  /// Fetch a specific file from remote
  static Future<Map<String, dynamic>?> _fetchRemoteFile(String filename) async {
    try {
      final response = await http
          .get(Uri.parse('$_remoteBaseUrl/$filename'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching remote file $filename: $e');
    }
    return null;
  }

  /// Get locally stored version number for a file
  static Future<int> _getLocalVersion(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_versionPrefix$filename') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Save version number locally
  static Future<void> _saveLocalVersion(String filename, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_versionPrefix$filename', version);
    } catch (e) {
      debugPrint('Error saving version for $filename: $e');
    }
  }

  /// Force refresh all remote files (call from settings or pull-to-refresh)
  static Future<void> forceRefreshAll() async {
    for (final filename in remoteFiles) {
      try {
        final remoteData = await _fetchRemoteFile(filename);
        if (remoteData != null) {
          await _cacheData(filename, remoteData);
          debugPrint('Force refreshed $filename');
        }
      } catch (e) {
        debugPrint('Error refreshing $filename: $e');
      }
    }
  }

  /// Clear all cached data (for debugging/reset)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final filename in remoteFiles) {
      await prefs.remove('$_cachePrefix$filename');
      await prefs.remove('$_versionPrefix$filename');
    }
    debugPrint('Cleared all cached data');
  }
}
