import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lua_plugin.dart';
import 'lua_engine_service.dart';
import 'lua_script_manager.dart';

/// The Lua snippet loaded once into the VM that provides per-plugin sandboxing.
///
/// Uses Lua 5.4's 4-arg [load()] to give each plugin its own environment table.
const _pluginManagerScript = r"""
_plugins = {}

function load_plugin(id, source)
  local env = setmetatable({}, {__index = _G})
  local chunk, err = load(source, "@" .. id, "t", env)
  if not chunk then error(err) end
  chunk()
  _plugins[id] = env
end

function call_plugin(id, fname, ...)
  local env = assert(_plugins[id], "plugin not loaded: " .. id)
  local f = assert(env[fname], "function not found: " .. fname)
  return f(...)
end
""";

const _prefKeyRepoUrls = 'lua_repo_urls';
const _prefKeyInstalledPlugins = 'lua_installed_plugins';
const _prefKeyDefaultRepoSeeded = 'lua_default_repo_seeded';

/// The built-in plugin repository shipped with the app.
///
/// Served via GitHub Pages (custom domain) from the civic-nepal repo.
const kDefaultRepoUrl = 'https://nagarikpatro.xyz/lua_plugins';

/// Manages plugin repositories and installed plugins lifecycle.
class LuaRepoService {
  LuaRepoService._();

  // ─── Repository URL management ───────────────────────────────────────────

  static Future<List<String>> getRepoUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKeyRepoUrls);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<String>();
  }

  static Future<void> addRepo(String url) async {
    final urls = await getRepoUrls();
    final normalised = _normaliseRepoUrl(url);
    if (urls.contains(normalised)) return;
    urls.add(normalised);
    await _saveRepoUrls(urls);
  }

  static Future<void> removeRepo(String url) async {
    final normalised = _normaliseRepoUrl(url);
    final urls = await getRepoUrls();
    urls.remove(normalised);
    await _saveRepoUrls(urls);

    // Uninstall all plugins from this repo
    final installed = await getInstalledPlugins();
    final remaining = installed.where((p) => p.repoUrl != normalised).toList();
    await _saveInstalledPlugins(remaining);

    // Evict their script caches
    for (final plugin in installed) {
      if (plugin.repoUrl == normalised) {
        await LuaScriptManager.evict(plugin.meta.scriptUrl);
      }
    }
  }

  // ─── Manifest fetch ───────────────────────────────────────────────────────

  /// Fetches and deserializes the [index.json] manifest for [repoUrl].
  ///
  /// Caches in `applicationSupportDirectory/lua_repos/<hash>.json`.
  /// Pass [forceRefresh] to bypass the cache.
  /// Pass [httpClient] to inject a custom HTTP client (useful in tests).
  static Future<LuaRepoManifest> fetchManifest(
    String repoUrl, {
    bool forceRefresh = false,
    http.Client? httpClient,
  }) async {
    final manifestUrl = _manifestUrlFor(repoUrl);

    // File-based caching is only available on non-web platforms.
    if (!kIsWeb) {
      final cacheFile = await _manifestCacheFileFor(repoUrl);
      if (!forceRefresh && await cacheFile.exists()) {
        final raw = await cacheFile.readAsString();
        return LuaRepoManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    }

    final client = httpClient ?? http.Client();
    final bool clientIsOwned = httpClient == null;
    late final http.Response response;
    try {
      response = await client
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw LuaRepoFetchException(manifestUrl, e.toString());
    } finally {
      if (clientIsOwned) client.close();
    }

    if (response.statusCode != 200) {
      throw LuaRepoFetchException(
        manifestUrl,
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final manifest = LuaRepoManifest.fromJson(json);

    // Write cache (non-fatal failure, non-web only)
    if (!kIsWeb) {
      try {
        final cacheFile = await _manifestCacheFileFor(repoUrl);
        await cacheFile.parent.create(recursive: true);
        await cacheFile.writeAsString(response.body);
      } on Exception catch (e) {
        // ignore: avoid_print
        print('[LuaRepoService] Cache write failed for $manifestUrl - $e');
      }
    }

    return manifest;
  }

  // ─── Install / uninstall ──────────────────────────────────────────────────

  static Future<void> installPlugin(
    String repoUrl,
    LuaPluginMeta meta, {
    http.Client? httpClient,
  }) async {
    final normalised = _normaliseRepoUrl(repoUrl);
    final manifest = await fetchManifest(normalised, httpClient: httpClient);
    final plugin = InstalledPlugin(
      meta: meta,
      repoId: manifest.id,
      repoUrl: normalised,
    );
    final installed = await getInstalledPlugins();
    // Deduplicate by compositeId
    final updated = [
      ...installed.where((p) => p.compositeId != plugin.compositeId),
      plugin,
    ];
    await _saveInstalledPlugins(updated);
  }

  static Future<void> uninstallPlugin(String compositeId) async {
    final installed = await getInstalledPlugins();
    final plugin = installed.where((p) => p.compositeId == compositeId).firstOrNull;
    if (plugin != null) {
      await LuaScriptManager.evict(plugin.meta.scriptUrl);
    }
    final updated = installed.where((p) => p.compositeId != compositeId).toList();
    await _saveInstalledPlugins(updated);
  }

  static Future<void> setPluginEnabled(String compositeId, bool enabled) async {
    final installed = await getInstalledPlugins();
    final updated = installed
        .map((p) => p.compositeId == compositeId ? p.copyWith(enabled: enabled) : p)
        .toList();
    await _saveInstalledPlugins(updated);
  }

  static Future<List<InstalledPlugin>> getInstalledPlugins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKeyInstalledPlugins);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => InstalledPlugin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Plugin execution ─────────────────────────────────────────────────────

  /// Add [kDefaultRepoUrl] on first ever launch and auto-install any plugins
  /// that have `autoInstall: true` in the manifest. Idempotent thereafter.
  static Future<void> seedDefaultReposIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKeyDefaultRepoSeeded) ?? false) return;
    await addRepo(kDefaultRepoUrl);

    // Auto-install plugins flagged with autoInstall: true
    try {
      final manifest = await fetchManifest(kDefaultRepoUrl);
      for (final plugin in manifest.plugins.where((p) => p.autoInstall)) {
        await installPlugin(kDefaultRepoUrl, plugin);
      }
    } on Exception catch (e) {
      // Non-fatal — the repo is added, plugins can be installed manually later.
      // ignore: avoid_print
      print('[LuaRepoService] Auto-install from default repo failed: $e');
    }

    await prefs.setBool(_prefKeyDefaultRepoSeeded, true);
  }

  /// Load the plugin manager script + all enabled installed plugins into the VM.
  ///
  /// Errors are logged and not rethrown (fire-and-forget safe).
  static Future<void> initializePlugins() async {
    await seedDefaultReposIfNeeded();

    try {
      await LuaEngineService.loadFromString(_pluginManagerScript);
    } on Exception catch (e) {
      // ignore: avoid_print
      print('[LuaRepoService] Failed to load plugin manager script: $e');
      return;
    }

    final installed = await getInstalledPlugins();
    for (final plugin in installed.where((p) => p.enabled)) {
      try {
        final script = await LuaScriptManager.fetchScript(plugin.meta.scriptUrl);
        await LuaEngineService.call('load_plugin', [plugin.compositeId, script]);
      } on Exception catch (e) {
        // ignore: avoid_print
        print('[LuaRepoService] Failed to load plugin ${plugin.compositeId}: $e');
      }
    }
  }

  /// Call a named function in a loaded plugin and return the result.
  static Future<Object?> callPlugin(
    String compositeId,
    String fn, [
    List<Object?> args = const [],
  ]) async {
    return LuaEngineService.call('call_plugin', [compositeId, fn, ...args]);
  }

  /// Call the entry point of every enabled `startup` plugin.
  static Future<void> runStartupPlugins() async {
    final installed = await getInstalledPlugins();
    for (final plugin in installed.where(
      (p) => p.enabled && p.meta.type == LuaPluginType.startup,
    )) {
      try {
        await callPlugin(plugin.compositeId, plugin.meta.entryPoint);
        await _markLastRun(plugin.compositeId);
      } on Exception catch (e) {
        // ignore: avoid_print
        print('[LuaRepoService] startup plugin ${plugin.compositeId} failed: $e');
      }
    }
  }

  /// Call the entry point of every enabled `background` plugin.
  static Future<void> runBackgroundPlugins() async {
    final installed = await getInstalledPlugins();
    for (final plugin in installed.where(
      (p) => p.enabled && p.meta.type == LuaPluginType.background,
    )) {
      try {
        await callPlugin(plugin.compositeId, plugin.meta.entryPoint);
        await _markLastRun(plugin.compositeId);
      } on Exception catch (e) {
        // ignore: avoid_print
        print('[LuaRepoService] background plugin ${plugin.compositeId} failed: $e');
      }
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Visible for testing.
  static String normaliseRepoUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  /// Visible for testing.
  static String manifestUrlFor(String repoUrl) {
    final normalised = normaliseRepoUrl(repoUrl);
    if (normalised.endsWith('.json')) return normalised;
    return '$normalised/index.json';
  }

  static String _normaliseRepoUrl(String url) => normaliseRepoUrl(url);
  static String _manifestUrlFor(String repoUrl) => manifestUrlFor(repoUrl);

  static Future<Directory> _repoCacheDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/lua_repos');
  }

  static Future<File> _manifestCacheFileFor(String repoUrl) async {
    final dir = await _repoCacheDir();
    final hash = sha256.convert(utf8.encode(repoUrl)).toString();
    return File('${dir.path}/$hash.json');
  }

  static Future<void> _saveRepoUrls(List<String> urls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyRepoUrls, jsonEncode(urls));
  }

  static Future<void> _saveInstalledPlugins(List<InstalledPlugin> plugins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyInstalledPlugins,
      jsonEncode(plugins.map((p) => p.toJson()).toList()),
    );
  }

  static Future<void> _markLastRun(String compositeId) async {
    final installed = await getInstalledPlugins();
    final updated = installed.map((p) {
      if (p.compositeId == compositeId) {
        return p.copyWith(lastRun: DateTime.now());
      }
      return p;
    }).toList();
    await _saveInstalledPlugins(updated);
  }
}

/// Thrown when a repo manifest cannot be fetched.
class LuaRepoFetchException implements Exception {
  final String url;
  final String reason;

  const LuaRepoFetchException(this.url, this.reason);

  @override
  String toString() => 'LuaRepoFetchException: Failed to fetch $url — $reason';
}
