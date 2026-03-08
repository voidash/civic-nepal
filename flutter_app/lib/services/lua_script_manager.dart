import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'lua_engine_service.dart';

/// Downloads Lua scripts from URLs, caches them locally, and executes them.
///
/// Cache location: `<applicationSupportDirectory>/lua_cache/<sha256_of_url>.lua`
class LuaScriptManager {
  LuaScriptManager._();

  // ─── Fetch ───────────────────────────────────────────────────────────────

  /// Fetch the script at [url].
  ///
  /// Returns the cached version unless [forceRefresh] is true or no cache exists.
  /// Throws [LuaScriptFetchException] on HTTP failure or I/O error.
  static Future<String> fetchScript(String url, {bool forceRefresh = false}) async {
    final cacheFile = await _cacheFileFor(url);

    if (!forceRefresh && await cacheFile.exists()) {
      return cacheFile.readAsString();
    }

    late final http.Response response;
    try {
      response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw LuaScriptFetchException(url, e.toString());
    }

    if (response.statusCode != 200) {
      throw LuaScriptFetchException(
        url,
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    final script = response.body;
    try {
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsString(script);
    } on Exception catch (e) {
      // Cache write failure is non-fatal — we still have the script in memory
      // ignore: avoid_print
      print('[LuaScriptManager] Warning: cache write failed for $url — $e');
    }
    return script;
  }

  // ─── Execute helpers ──────────────────────────────────────────────────────

  /// Fetch script from [url], load it into the Lua state, then call [entryPoint].
  ///
  /// [entryPoint] defaults to `"main"`. [args] are passed to the entry function.
  /// Returns the function's return value.
  static Future<Object?> executeFromUrl(
    String url, {
    String entryPoint = 'main',
    List<Object?> args = const [],
    bool forceRefresh = false,
  }) async {
    await LuaEngineService.loadFromUrl(url, forceRefresh: forceRefresh);
    return LuaEngineService.call(entryPoint, args);
  }

  // ─── Cache management ────────────────────────────────────────────────────

  /// Delete all cached Lua scripts.
  static Future<void> clearCache() async {
    final dir = await _cacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Delete the cached script for [url], if any.
  static Future<void> evict(String url) async {
    final file = await _cacheFileFor(url);
    if (await file.exists()) await file.delete();
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  static Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/lua_cache');
  }

  static Future<File> _cacheFileFor(String url) async {
    final dir = await _cacheDir();
    final hash = sha256.convert(utf8.encode(url)).toString();
    return File('${dir.path}/$hash.lua');
  }
}
