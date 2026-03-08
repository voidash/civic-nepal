import 'package:flutter/services.dart';

/// Embedded Lua 5.4 scripting engine.
///
/// Maintains a persistent Lua state across calls.
/// All methods execute on a dedicated background thread (no UI blocking).
///
/// Channel: com.nagarikpatro/lua
/// Methods:
///   execute(script: String) -> Object?   — execute script, return last value
///   load(script: String)    -> void      — execute script, accumulate globals
///   call(function: String, args: List)   -> Object?  — call named global function
///   reset()                 -> void      — destroy + recreate state
class LuaEngine {
  static const MethodChannel _channel = MethodChannel('com.nagarikpatro/lua');

  /// Execute [script] and return the last expression value.
  ///
  /// The script runs in the current Lua state. Any globals defined survive
  /// to future calls. Throws [LuaException] on script error.
  static Future<Object?> execute(String script) =>
      _channel.invokeMethod<Object>('execute', {'script': script});

  /// Load [script] into the Lua state without returning a value.
  ///
  /// Use this to define functions/globals that subsequent [call] invocations
  /// can use. Throws [LuaException] on compilation or runtime error.
  static Future<void> load(String script) async =>
      _channel.invokeMethod<void>('load', {'script': script});

  /// Call a named global Lua function with [args].
  ///
  /// [fn] must be a callable global defined by a prior [load] or [execute].
  /// [args] may contain null, bool, int, double, String, List, Map values.
  /// Returns the function's return value (nil → null).
  static Future<Object?> call(String fn, [List<Object?> args = const []]) =>
      _channel.invokeMethod<Object>('call', {'function': fn, 'args': args});

  /// Destroy the current Lua state and create a fresh one.
  ///
  /// All globals and loaded modules are cleared.
  static Future<void> reset() async => _channel.invokeMethod<void>('reset');
}

/// Thrown when a Lua script raises an error.
class LuaException implements Exception {
  final String message;
  final String? luaTraceback;

  const LuaException(this.message, {this.luaTraceback});

  @override
  String toString() => luaTraceback != null
      ? 'LuaException: $message\n$luaTraceback'
      : 'LuaException: $message';
}
