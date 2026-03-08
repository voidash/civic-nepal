import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nagarik_calendar/models/lua_plugin.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

const _metaJson = {
  'id': 'civic_tip',
  'name': 'Civic Tip',
  'description': 'Daily civic tip',
  'version': '1.0.0',
  'type': 'markdown_panel',
  'entryPoint': 'get_content',
  'scriptUrl': 'https://example.com/civic_tip.lua',
  'iconUrl': 'https://example.com/icon.png',
  'author': 'voidash',
  'requiresNetwork': false,
  'intervalHours': null,
};

const _metaJsonMinimal = {
  'id': 'hello',
  'name': 'Hello',
  'description': 'Hello plugin',
  'version': '0.1.0',
  'type': 'startup',
  'entryPoint': 'main',
  'scriptUrl': 'https://example.com/hello.lua',
};

final _manifestJson = {
  'id': 'nagarik-default',
  'name': 'Default Plugins',
  'description': 'Built-in plugin set',
  'version': 1,
  'author': 'voidash',
  'plugins': [_metaJson, _metaJsonMinimal],
};

LuaPluginMeta _makeMeta({
  String id = 'test-plugin',
  LuaPluginType type = LuaPluginType.startup,
}) =>
    LuaPluginMeta(
      id: id,
      name: 'Test Plugin',
      description: 'desc',
      version: '1.0.0',
      type: type,
      entryPoint: 'main',
      scriptUrl: 'https://example.com/$id.lua',
    );

InstalledPlugin _makeInstalled({
  String id = 'test-plugin',
  String repoId = 'my-repo',
  LuaPluginType type = LuaPluginType.startup,
  bool enabled = true,
}) =>
    InstalledPlugin(
      meta: _makeMeta(id: id, type: type),
      repoId: repoId,
      repoUrl: 'https://example.com/repo',
      enabled: enabled,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── LuaPluginType ──────────────────────────────────────────────────────────

  group('LuaPluginType.fromString', () {
    test('parses every known type', () {
      expect(LuaPluginType.fromString('startup'), LuaPluginType.startup);
      expect(LuaPluginType.fromString('calendar_inject'), LuaPluginType.calendarInject);
      expect(LuaPluginType.fromString('markdown_panel'), LuaPluginType.markdownPanel);
      expect(LuaPluginType.fromString('new_screen'), LuaPluginType.newScreen);
      expect(LuaPluginType.fromString('background'), LuaPluginType.background);
    });

    test('throws ArgumentError on unknown string', () {
      expect(
        () => LuaPluginType.fromString('does_not_exist'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('LuaPluginType.toJsonString', () {
    test('roundtrips every type through fromString', () {
      for (final type in LuaPluginType.values) {
        expect(LuaPluginType.fromString(type.toJsonString()), type);
      }
    });

    test('produces snake_case strings', () {
      expect(LuaPluginType.calendarInject.toJsonString(), 'calendar_inject');
      expect(LuaPluginType.markdownPanel.toJsonString(), 'markdown_panel');
      expect(LuaPluginType.newScreen.toJsonString(), 'new_screen');
    });
  });

  group('LuaPluginType.displayName', () {
    test('returns non-empty string for every type', () {
      for (final type in LuaPluginType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('specific display names', () {
      expect(LuaPluginType.startup.displayName, 'Startup');
      expect(LuaPluginType.calendarInject.displayName, 'Calendar');
      expect(LuaPluginType.markdownPanel.displayName, 'Markdown Panel');
      expect(LuaPluginType.newScreen.displayName, 'New Screen');
      expect(LuaPluginType.background.displayName, 'Background');
    });
  });

  // ── LuaPluginMeta ──────────────────────────────────────────────────────────

  group('LuaPluginMeta', () {
    test('fromJson parses all fields', () {
      final meta = LuaPluginMeta.fromJson(_metaJson);

      expect(meta.id, 'civic_tip');
      expect(meta.name, 'Civic Tip');
      expect(meta.description, 'Daily civic tip');
      expect(meta.version, '1.0.0');
      expect(meta.type, LuaPluginType.markdownPanel);
      expect(meta.entryPoint, 'get_content');
      expect(meta.scriptUrl, 'https://example.com/civic_tip.lua');
      expect(meta.iconUrl, 'https://example.com/icon.png');
      expect(meta.author, 'voidash');
      expect(meta.requiresNetwork, isFalse);
      expect(meta.intervalHours, isNull);
    });

    test('fromJson handles absent optional fields', () {
      final meta = LuaPluginMeta.fromJson(_metaJsonMinimal);

      expect(meta.id, 'hello');
      expect(meta.iconUrl, isNull);
      expect(meta.author, isNull);
      expect(meta.requiresNetwork, isFalse); // default
      expect(meta.intervalHours, isNull);
    });

    test('toJson / fromJson roundtrip preserves all fields', () {
      final original = LuaPluginMeta.fromJson(_metaJson);
      final encoded = original.toJson();
      final decoded = LuaPluginMeta.fromJson(encoded);

      expect(decoded, equals(original));
    });

    test('toJson encodes type as snake_case string', () {
      final meta = LuaPluginMeta.fromJson(_metaJson);
      final json = meta.toJson();
      expect(json['type'], 'markdown_panel');
    });

    test('fromJson parses calendar_inject type', () {
      final json = {
        ..._metaJsonMinimal,
        'type': 'calendar_inject',
        'entryPoint': 'get_events',
      };
      final meta = LuaPluginMeta.fromJson(json);
      expect(meta.type, LuaPluginType.calendarInject);
    });

    test('fromJson parses background type with intervalHours', () {
      final json = {
        ..._metaJsonMinimal,
        'type': 'background',
        'intervalHours': 6,
        'requiresNetwork': true,
      };
      final meta = LuaPluginMeta.fromJson(json);
      expect(meta.type, LuaPluginType.background);
      expect(meta.intervalHours, 6);
      expect(meta.requiresNetwork, isTrue);
    });
  });

  // ── LuaRepoManifest ────────────────────────────────────────────────────────

  group('LuaRepoManifest', () {
    test('fromJson parses manifest with plugins list', () {
      final manifest = LuaRepoManifest.fromJson(_manifestJson);

      expect(manifest.id, 'nagarik-default');
      expect(manifest.name, 'Default Plugins');
      expect(manifest.description, 'Built-in plugin set');
      expect(manifest.version, 1);
      expect(manifest.author, 'voidash');
      expect(manifest.plugins, hasLength(2));
    });

    test('plugins are correctly typed', () {
      final manifest = LuaRepoManifest.fromJson(_manifestJson);
      expect(manifest.plugins[0].type, LuaPluginType.markdownPanel);
      expect(manifest.plugins[1].type, LuaPluginType.startup);
    });

    test('toJson / fromJson roundtrip', () {
      final original = LuaRepoManifest.fromJson(_manifestJson);
      final decoded = LuaRepoManifest.fromJson(original.toJson());
      expect(decoded, equals(original));
    });

    test('fromJson tolerates empty plugins array', () {
      final json = {
        ..._manifestJson,
        'plugins': <Map<String, dynamic>>[],
      };
      final manifest = LuaRepoManifest.fromJson(json);
      expect(manifest.plugins, isEmpty);
    });

    test('survives JSON string encode + decode', () {
      final original = LuaRepoManifest.fromJson(_manifestJson);
      final jsonString = jsonEncode(original.toJson());
      final decoded = LuaRepoManifest.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
      expect(decoded, equals(original));
    });
  });

  // ── InstalledPlugin ────────────────────────────────────────────────────────

  group('InstalledPlugin', () {
    test('compositeId is repoId/meta.id', () {
      final plugin = _makeInstalled(id: 'civic_tip', repoId: 'nagarik-default');
      expect(plugin.compositeId, 'nagarik-default/civic_tip');
    });

    test('enabled defaults to true', () {
      final plugin = InstalledPlugin(
        meta: _makeMeta(),
        repoId: 'r',
        repoUrl: 'https://example.com',
      );
      expect(plugin.enabled, isTrue);
    });

    test('copyWith changes only the specified field', () {
      final plugin = _makeInstalled(enabled: true);
      final disabled = plugin.copyWith(enabled: false);

      expect(disabled.enabled, isFalse);
      expect(disabled.meta, plugin.meta);
      expect(disabled.repoId, plugin.repoId);
      expect(disabled.repoUrl, plugin.repoUrl);
    });

    test('toJson / fromJson roundtrip', () {
      final original = _makeInstalled(id: 'hello', repoId: 'my-repo');
      final decoded = InstalledPlugin.fromJson(original.toJson());
      expect(decoded, equals(original));
    });

    test('toJson / fromJson roundtrip with lastRun set', () {
      final now = DateTime.utc(2025, 3, 5, 10, 30);
      final plugin = _makeInstalled().copyWith(lastRun: now);
      final decoded = InstalledPlugin.fromJson(plugin.toJson());
      expect(decoded.lastRun, isNotNull);
      expect(decoded.lastRun!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('disabled plugin preserves compositeId through roundtrip', () {
      final plugin = _makeInstalled(id: 'foo', repoId: 'bar', enabled: false);
      final decoded = InstalledPlugin.fromJson(plugin.toJson());
      expect(decoded.compositeId, 'bar/foo');
      expect(decoded.enabled, isFalse);
    });
  });

}
