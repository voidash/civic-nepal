import 'package:flutter/services.dart';
import 'package:lua_engine/lua_engine.dart';

import 'lua_script_manager.dart';

export 'package:lua_engine/lua_engine.dart' show LuaException;

/// App-level wrapper around [LuaEngine] that converts [PlatformException] into
/// typed [LuaException] and provides convenience helpers.
class LuaEngineService {
  const LuaEngineService._();

  /// Execute [script] and return the last value as a Dart object.
  ///
  /// Throws [LuaException] if the script raises an error.
  static Future<Object?> execute(String script) async {
    try {
      return await LuaEngine.execute(script);
    } on PlatformException catch (e) {
      throw _toDomainException(e);
    }
  }

  /// Load [script] into the persistent Lua state (defines globals/functions).
  ///
  /// Throws [LuaException] on error.
  static Future<void> loadFromString(String script) async {
    try {
      await LuaEngine.load(script);
    } on PlatformException catch (e) {
      throw _toDomainException(e);
    }
  }

  /// Fetch a Lua script from [url] (with file-based caching) and load it.
  ///
  /// Throws [LuaScriptFetchException] if the URL cannot be fetched.
  /// Throws [LuaException] if the script raises an error.
  static Future<void> loadFromUrl(String url, {bool forceRefresh = false}) async {
    final script = await LuaScriptManager.fetchScript(url, forceRefresh: forceRefresh);
    await loadFromString(script);
  }

  /// Execute a script fetched from [url] and return the result.
  static Future<Object?> executeFromUrl(String url, {bool forceRefresh = false}) async {
    final script = await LuaScriptManager.fetchScript(url, forceRefresh: forceRefresh);
    return execute(script);
  }

  /// Call a named Lua global function with [args].
  ///
  /// Throws [LuaException] if the function does not exist or raises an error.
  static Future<Object?> call(String fn, [List<Object?> args = const []]) async {
    try {
      return await LuaEngine.call(fn, args);
    } on PlatformException catch (e) {
      throw _toDomainException(e);
    }
  }

  /// Destroy the current Lua state and create a fresh one.
  static Future<void> reset() async {
    try {
      await LuaEngine.reset();
    } on PlatformException catch (e) {
      throw _toDomainException(e);
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  static Exception _toDomainException(PlatformException e) {
    if (e.code == 'LUA_ERROR') {
      return LuaException(
        e.message ?? 'Unknown Lua error',
        luaTraceback: e.details?.toString(),
      );
    }
    return LuaException('Native error [${e.code}]: ${e.message ?? ''}');
  }
}

/// Thrown when a remote Lua script cannot be fetched.
class LuaScriptFetchException implements Exception {
  final String url;
  final String reason;

  const LuaScriptFetchException(this.url, this.reason);

  @override
  String toString() => 'LuaScriptFetchException: Failed to fetch $url — $reason';
}
