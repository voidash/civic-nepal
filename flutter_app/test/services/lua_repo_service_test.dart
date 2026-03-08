import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nagarik_calendar/models/lua_plugin.dart';
import 'package:nagarik_calendar/services/lua_repo_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test doubles
// ─────────────────────────────────────────────────────────────────────────────

/// Routes getApplicationSupportDirectory() to a temp directory per test.
class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this._dir);

  final String _dir;

  @override
  Future<String?> getApplicationSupportPath() async => _dir;

  // All other methods unsupported — tests only call getApplicationSupportDirectory
  @override
  Future<String?> getTemporaryPath() async => _dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir;

  @override
  Future<String?> getDownloadsPath() async => _dir;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => null;

  @override
  Future<String?> getLibraryPath() async => _dir;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _repoUrl = 'https://example.com/my-repo';

final _validManifest = {
  'id': 'my-repo',
  'name': 'My Repo',
  'description': 'test repo',
  'version': 1,
  'author': 'tester',
  'plugins': [
    {
      'id': 'startup_plugin',
      'name': 'Startup Plugin',
      'description': 'runs at startup',
      'version': '1.0.0',
      'type': 'startup',
      'entryPoint': 'main',
      'scriptUrl': 'https://example.com/startup.lua',
    },
    {
      'id': 'bg_plugin',
      'name': 'Background Plugin',
      'description': 'runs in background',
      'version': '1.0.0',
      'type': 'background',
      'entryPoint': 'main',
      'scriptUrl': 'https://example.com/bg.lua',
      'intervalHours': 6,
    },
    {
      'id': 'calendar_plugin',
      'name': 'Calendar Plugin',
      'description': 'injects events',
      'version': '1.0.0',
      'type': 'calendar_inject',
      'entryPoint': 'get_events',
      'scriptUrl': 'https://example.com/calendar.lua',
    },
  ],
};

LuaPluginMeta _startupMeta() => LuaPluginMeta(
      id: 'startup_plugin',
      name: 'Startup Plugin',
      description: 'runs at startup',
      version: '1.0.0',
      type: LuaPluginType.startup,
      entryPoint: 'main',
      scriptUrl: 'https://example.com/startup.lua',
    );

LuaPluginMeta _bgMeta() => LuaPluginMeta(
      id: 'bg_plugin',
      name: 'Background Plugin',
      description: 'runs in background',
      version: '1.0.0',
      type: LuaPluginType.background,
      entryPoint: 'main',
      scriptUrl: 'https://example.com/bg.lua',
      intervalHours: 6,
    );

MockClient _manifestClient({int status = 200}) => MockClient((request) async {
      if (request.url.toString().endsWith('index.json') && status == 200) {
        return http.Response(jsonEncode(_validManifest), 200);
      }
      return http.Response('Not Found', status);
    });

/// Seeds SharedPreferences with a pre-built installed plugins list.
Future<void> _seedInstalled(List<InstalledPlugin> plugins) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'lua_installed_plugins',
    jsonEncode(plugins.map((p) => p.toJson()).toList()),
  );
}

/// Tracks calls to the com.nagarikpatro/lua method channel.
List<MethodCall> _setupLuaChannelMock() {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.nagarikpatro/lua'),
    (call) async {
      calls.add(call);
      return null; // All Lua calls succeed and return null
    },
  );
  return calls;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    // Fresh SharedPreferences for every test
    SharedPreferences.setMockInitialValues({});

    // Route path_provider to a temp directory
    tempDir = Directory.systemTemp.createTempSync('lua_repo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── URL normalisation ──────────────────────────────────────────────────────

  group('normaliseRepoUrl', () {
    test('strips trailing slash', () {
      expect(
        LuaRepoService.normaliseRepoUrl('https://example.com/repo/'),
        'https://example.com/repo',
      );
    });

    test('trims whitespace', () {
      expect(
        LuaRepoService.normaliseRepoUrl('  https://example.com/repo  '),
        'https://example.com/repo',
      );
    });

    test('leaves URL without trailing slash unchanged', () {
      const url = 'https://example.com/repo';
      expect(LuaRepoService.normaliseRepoUrl(url), url);
    });
  });

  group('manifestUrlFor', () {
    test('appends /index.json to bare repo URL', () {
      expect(
        LuaRepoService.manifestUrlFor('https://example.com/repo'),
        'https://example.com/repo/index.json',
      );
    });

    test('does not double-append if URL already ends in .json', () {
      const url = 'https://example.com/my-index.json';
      expect(LuaRepoService.manifestUrlFor(url), url);
    });

    test('strips trailing slash before appending /index.json', () {
      expect(
        LuaRepoService.manifestUrlFor('https://example.com/repo/'),
        'https://example.com/repo/index.json',
      );
    });
  });

  // ── Repo URL persistence ───────────────────────────────────────────────────

  group('addRepo / getRepoUrls', () {
    test('initially empty', () async {
      expect(await LuaRepoService.getRepoUrls(), isEmpty);
    });

    test('addRepo stores normalised URL', () async {
      await LuaRepoService.addRepo('$_repoUrl/');
      final urls = await LuaRepoService.getRepoUrls();
      expect(urls, [_repoUrl]); // trailing slash stripped
    });

    test('addRepo deduplicates same URL', () async {
      await LuaRepoService.addRepo(_repoUrl);
      await LuaRepoService.addRepo(_repoUrl);
      expect(await LuaRepoService.getRepoUrls(), hasLength(1));
    });

    test('addRepo deduplicates URL with trailing slash', () async {
      await LuaRepoService.addRepo(_repoUrl);
      await LuaRepoService.addRepo('$_repoUrl/');
      expect(await LuaRepoService.getRepoUrls(), hasLength(1));
    });

    test('addRepo appends multiple distinct URLs', () async {
      await LuaRepoService.addRepo(_repoUrl);
      await LuaRepoService.addRepo('https://other.example.com/repo');
      expect(await LuaRepoService.getRepoUrls(), hasLength(2));
    });
  });

  group('removeRepo', () {
    test('removes the URL', () async {
      await LuaRepoService.addRepo(_repoUrl);
      await LuaRepoService.removeRepo(_repoUrl);
      expect(await LuaRepoService.getRepoUrls(), isEmpty);
    });

    test('removing non-existent URL is a no-op', () async {
      await LuaRepoService.addRepo(_repoUrl);
      await LuaRepoService.removeRepo('https://does-not-exist.example.com');
      expect(await LuaRepoService.getRepoUrls(), hasLength(1));
    });

    test('cascades removal to installed plugins from that repo', () async {
      // Seed an installed plugin belonging to _repoUrl
      await _seedInstalled([
        InstalledPlugin(
          meta: _startupMeta(),
          repoId: 'my-repo',
          repoUrl: _repoUrl,
        ),
        InstalledPlugin(
          meta: _bgMeta(),
          repoId: 'other-repo',
          repoUrl: 'https://other.example.com/repo',
        ),
      ]);

      await LuaRepoService.addRepo(_repoUrl);
      await LuaRepoService.removeRepo(_repoUrl);

      final installed = await LuaRepoService.getInstalledPlugins();
      expect(installed, hasLength(1));
      expect(installed.first.repoUrl, 'https://other.example.com/repo');
    });
  });

  // ── fetchManifest ──────────────────────────────────────────────────────────

  group('fetchManifest', () {
    test('parses manifest from HTTP 200 response', () async {
      final manifest = await LuaRepoService.fetchManifest(
        _repoUrl,
        httpClient: _manifestClient(),
      );

      expect(manifest.id, 'my-repo');
      expect(manifest.name, 'My Repo');
      expect(manifest.plugins, hasLength(3));
    });

    test('throws LuaRepoFetchException on non-200 status', () async {
      await expectLater(
        LuaRepoService.fetchManifest(
          _repoUrl,
          httpClient: _manifestClient(status: 404),
        ),
        throwsA(isA<LuaRepoFetchException>()),
      );
    });

    test('caches result on disk after first fetch', () async {
      await LuaRepoService.fetchManifest(
        _repoUrl,
        httpClient: _manifestClient(),
      );

      // Second fetch with a client that always 404s — must read from cache
      final cached = await LuaRepoService.fetchManifest(
        _repoUrl,
        httpClient: _manifestClient(status: 404),
      );
      expect(cached.id, 'my-repo');
    });

    test('forceRefresh bypasses cache and hits network', () async {
      // Populate cache
      await LuaRepoService.fetchManifest(
        _repoUrl,
        httpClient: _manifestClient(),
      );

      // forceRefresh with a 500 client should throw, not return cached
      await expectLater(
        LuaRepoService.fetchManifest(
          _repoUrl,
          forceRefresh: true,
          httpClient: _manifestClient(status: 500),
        ),
        throwsA(isA<LuaRepoFetchException>()),
      );
    });

    test('accepts trailing slash on repo URL', () async {
      // Should normalise URL and still request index.json
      final manifest = await LuaRepoService.fetchManifest(
        '$_repoUrl/',
        httpClient: _manifestClient(),
      );
      expect(manifest.id, 'my-repo');
    });
  });

  // ── Plugin install / uninstall / enable ────────────────────────────────────

  group('getInstalledPlugins', () {
    test('returns empty list initially', () async {
      expect(await LuaRepoService.getInstalledPlugins(), isEmpty);
    });
  });

  group('installPlugin', () {
    test('creates an enabled InstalledPlugin', () async {
      await LuaRepoService.installPlugin(
        _repoUrl,
        _startupMeta(),
        httpClient: _manifestClient(),
      );

      final installed = await LuaRepoService.getInstalledPlugins();
      expect(installed, hasLength(1));
      expect(installed.first.meta.id, 'startup_plugin');
      expect(installed.first.repoId, 'my-repo');
      expect(installed.first.repoUrl, _repoUrl);
      expect(installed.first.enabled, isTrue);
    });

    test('compositeId is correct', () async {
      await LuaRepoService.installPlugin(
        _repoUrl,
        _startupMeta(),
        httpClient: _manifestClient(),
      );
      final plugin = (await LuaRepoService.getInstalledPlugins()).first;
      expect(plugin.compositeId, 'my-repo/startup_plugin');
    });

    test('reinstalling same plugin is idempotent (replaces, no duplicates)', () async {
      await LuaRepoService.installPlugin(
        _repoUrl,
        _startupMeta(),
        httpClient: _manifestClient(),
      );
      await LuaRepoService.installPlugin(
        _repoUrl,
        _startupMeta(),
        httpClient: _manifestClient(),
      );
      expect(await LuaRepoService.getInstalledPlugins(), hasLength(1));
    });

    test('can install multiple different plugins', () async {
      await LuaRepoService.installPlugin(
        _repoUrl,
        _startupMeta(),
        httpClient: _manifestClient(),
      );
      await LuaRepoService.installPlugin(
        _repoUrl,
        _bgMeta(),
        httpClient: _manifestClient(),
      );
      expect(await LuaRepoService.getInstalledPlugins(), hasLength(2));
    });
  });

  group('uninstallPlugin', () {
    test('removes the plugin from the list', () async {
      await _seedInstalled([
        InstalledPlugin(meta: _startupMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
        InstalledPlugin(meta: _bgMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
      ]);

      await LuaRepoService.uninstallPlugin('my-repo/startup_plugin');

      final installed = await LuaRepoService.getInstalledPlugins();
      expect(installed, hasLength(1));
      expect(installed.first.meta.id, 'bg_plugin');
    });

    test('uninstalling non-existent compositeId is a no-op', () async {
      await _seedInstalled([
        InstalledPlugin(meta: _startupMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
      ]);

      await LuaRepoService.uninstallPlugin('my-repo/does-not-exist');
      expect(await LuaRepoService.getInstalledPlugins(), hasLength(1));
    });
  });

  group('setPluginEnabled', () {
    test('disables a plugin', () async {
      await _seedInstalled([
        InstalledPlugin(meta: _startupMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
      ]);

      await LuaRepoService.setPluginEnabled('my-repo/startup_plugin', false);

      final installed = await LuaRepoService.getInstalledPlugins();
      expect(installed.first.enabled, isFalse);
    });

    test('re-enables a previously disabled plugin', () async {
      await _seedInstalled([
        InstalledPlugin(
          meta: _startupMeta(),
          repoId: 'my-repo',
          repoUrl: _repoUrl,
          enabled: false,
        ),
      ]);

      await LuaRepoService.setPluginEnabled('my-repo/startup_plugin', true);

      final installed = await LuaRepoService.getInstalledPlugins();
      expect(installed.first.enabled, isTrue);
    });

    test('does not affect other plugins', () async {
      await _seedInstalled([
        InstalledPlugin(meta: _startupMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
        InstalledPlugin(meta: _bgMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
      ]);

      await LuaRepoService.setPluginEnabled('my-repo/startup_plugin', false);

      final installed = await LuaRepoService.getInstalledPlugins();
      final bg = installed.firstWhere((p) => p.meta.id == 'bg_plugin');
      expect(bg.enabled, isTrue);
    });
  });

  // ── Plugin execution ───────────────────────────────────────────────────────

  group('runStartupPlugins', () {
    test('only calls entry point of startup-type plugins', () async {
      final calls = _setupLuaChannelMock();

      await _seedInstalled([
        InstalledPlugin(meta: _startupMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
        InstalledPlugin(meta: _bgMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
      ]);

      await LuaRepoService.runStartupPlugins();

      // Should call call_plugin once for startup_plugin, never for bg_plugin
      final callPluginCalls = calls
          .where((c) => c.method == 'call')
          .map((c) => (c.arguments as Map)['args'] as List)
          .where((args) => args.isNotEmpty && args[0] == 'my-repo/startup_plugin')
          .toList();

      expect(callPluginCalls, hasLength(1));

      final bgCalls = calls
          .where((c) => c.method == 'call')
          .map((c) => (c.arguments as Map)['args'] as List)
          .where((args) => args.isNotEmpty && args[0] == 'my-repo/bg_plugin')
          .toList();
      expect(bgCalls, isEmpty);
    });

    test('skips disabled startup plugins', () async {
      final calls = _setupLuaChannelMock();

      await _seedInstalled([
        InstalledPlugin(
          meta: _startupMeta(),
          repoId: 'my-repo',
          repoUrl: _repoUrl,
          enabled: false,
        ),
      ]);

      await LuaRepoService.runStartupPlugins();

      final callPluginCalls =
          calls.where((c) => c.method == 'call').toList();
      expect(callPluginCalls, isEmpty);
    });

    test('marks lastRun after successful execution', () async {
      _setupLuaChannelMock();

      await _seedInstalled([
        InstalledPlugin(meta: _startupMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
      ]);

      final before = DateTime.now();
      await LuaRepoService.runStartupPlugins();
      final after = DateTime.now();

      final installed = await LuaRepoService.getInstalledPlugins();
      final lastRun = installed.first.lastRun;
      expect(lastRun, isNotNull);
      expect(
        lastRun!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(lastRun.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('runs fine with no installed plugins', () async {
      _setupLuaChannelMock();
      // Should not throw
      await expectLater(LuaRepoService.runStartupPlugins(), completes);
    });
  });

  group('runBackgroundPlugins', () {
    test('only calls background-type plugins', () async {
      final calls = _setupLuaChannelMock();

      await _seedInstalled([
        InstalledPlugin(meta: _startupMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
        InstalledPlugin(meta: _bgMeta(), repoId: 'my-repo', repoUrl: _repoUrl),
      ]);

      await LuaRepoService.runBackgroundPlugins();

      final bgCalls = calls
          .where((c) => c.method == 'call')
          .map((c) => (c.arguments as Map)['args'] as List)
          .where((args) => args.isNotEmpty && args[0] == 'my-repo/bg_plugin')
          .toList();
      expect(bgCalls, hasLength(1));

      final startupCalls = calls
          .where((c) => c.method == 'call')
          .map((c) => (c.arguments as Map)['args'] as List)
          .where((args) => args.isNotEmpty && args[0] == 'my-repo/startup_plugin')
          .toList();
      expect(startupCalls, isEmpty);
    });

    test('skips disabled background plugins', () async {
      final calls = _setupLuaChannelMock();

      await _seedInstalled([
        InstalledPlugin(
          meta: _bgMeta(),
          repoId: 'my-repo',
          repoUrl: _repoUrl,
          enabled: false,
        ),
      ]);

      await LuaRepoService.runBackgroundPlugins();
      expect(calls.where((c) => c.method == 'call'), isEmpty);
    });
  });

  // ── initializePlugins ──────────────────────────────────────────────────────

  group('initializePlugins', () {
    test('loads plugin manager script into Lua VM', () async {
      final calls = _setupLuaChannelMock();

      await LuaRepoService.initializePlugins();

      final loadCalls = calls.where((c) => c.method == 'load').toList();
      expect(loadCalls, isNotEmpty);

      // Manager script defines load_plugin and call_plugin
      final script = (loadCalls.first.arguments as Map)['script'] as String;
      expect(script, contains('load_plugin'));
      expect(script, contains('call_plugin'));
    });

    test('does not throw when no plugins are installed', () async {
      _setupLuaChannelMock();
      await expectLater(LuaRepoService.initializePlugins(), completes);
    });

    test('seeds default repo on first run', () async {
      _setupLuaChannelMock();

      await LuaRepoService.initializePlugins();

      final urls = await LuaRepoService.getRepoUrls();
      expect(urls, contains(kDefaultRepoUrl));
    });

    test('does not double-add default repo on second call', () async {
      _setupLuaChannelMock();

      await LuaRepoService.initializePlugins();
      await LuaRepoService.initializePlugins();

      final urls = await LuaRepoService.getRepoUrls();
      final defaultCount = urls.where((u) => u == kDefaultRepoUrl).length;
      expect(defaultCount, 1);
    });
  });

  // ── LuaRepoFetchException ──────────────────────────────────────────────────

  group('LuaRepoFetchException', () {
    test('toString includes url and reason', () {
      const ex = LuaRepoFetchException('https://example.com', 'HTTP 404');
      expect(ex.toString(), contains('https://example.com'));
      expect(ex.toString(), contains('HTTP 404'));
    });
  });

  // ── seedDefaultReposIfNeeded ───────────────────────────────────────────────

  group('seedDefaultReposIfNeeded', () {
    test('adds kDefaultRepoUrl when no repos exist', () async {
      await LuaRepoService.seedDefaultReposIfNeeded();
      expect(await LuaRepoService.getRepoUrls(), contains(kDefaultRepoUrl));
    });

    test('is idempotent — second call does not add duplicate', () async {
      await LuaRepoService.seedDefaultReposIfNeeded();
      await LuaRepoService.seedDefaultReposIfNeeded();
      final urls = await LuaRepoService.getRepoUrls();
      expect(urls.where((u) => u == kDefaultRepoUrl).length, 1);
    });
  });
}
