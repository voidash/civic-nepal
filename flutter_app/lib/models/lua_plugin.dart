import 'package:freezed_annotation/freezed_annotation.dart';

part 'lua_plugin.freezed.dart';
part 'lua_plugin.g.dart';

class LuaPluginTypeConverter implements JsonConverter<LuaPluginType, String> {
  const LuaPluginTypeConverter();

  @override
  LuaPluginType fromJson(String json) => LuaPluginType.fromString(json);

  @override
  String toJson(LuaPluginType type) => type.toJsonString();
}

enum LuaPluginType {
  startup,
  calendarInject,
  markdownPanel,
  newScreen,
  background;

  static LuaPluginType fromString(String s) {
    return switch (s) {
      'startup' => LuaPluginType.startup,
      'calendar_inject' => LuaPluginType.calendarInject,
      'markdown_panel' => LuaPluginType.markdownPanel,
      'new_screen' => LuaPluginType.newScreen,
      'background' => LuaPluginType.background,
      _ => throw ArgumentError('Unknown LuaPluginType: $s'),
    };
  }

  String toJsonString() {
    return switch (this) {
      LuaPluginType.startup => 'startup',
      LuaPluginType.calendarInject => 'calendar_inject',
      LuaPluginType.markdownPanel => 'markdown_panel',
      LuaPluginType.newScreen => 'new_screen',
      LuaPluginType.background => 'background',
    };
  }

  String get displayName {
    return switch (this) {
      LuaPluginType.startup => 'Startup',
      LuaPluginType.calendarInject => 'Calendar',
      LuaPluginType.markdownPanel => 'Markdown Panel',
      LuaPluginType.newScreen => 'New Screen',
      LuaPluginType.background => 'Background',
    };
  }
}

@freezed
class LuaPluginMeta with _$LuaPluginMeta {
  const factory LuaPluginMeta({
    required String id,
    required String name,
    required String description,
    required String version,
    @LuaPluginTypeConverter() required LuaPluginType type,
    required String entryPoint,
    required String scriptUrl,
    String? iconUrl,
    String? author,
    @Default(false) bool requiresNetwork,
    @Default(false) bool autoInstall,
    int? intervalHours,
  }) = _LuaPluginMeta;

  factory LuaPluginMeta.fromJson(Map<String, dynamic> json) =>
      _$LuaPluginMetaFromJson(json);
}

@freezed
class LuaRepoManifest with _$LuaRepoManifest {
  const factory LuaRepoManifest({
    required String id,
    required String name,
    required String description,
    required int version,
    required String author,
    required List<LuaPluginMeta> plugins,
  }) = _LuaRepoManifest;

  factory LuaRepoManifest.fromJson(Map<String, dynamic> json) =>
      _$LuaRepoManifestFromJson(json);
}

@freezed
class InstalledPlugin with _$InstalledPlugin {
  const InstalledPlugin._();

  const factory InstalledPlugin({
    required LuaPluginMeta meta,
    required String repoId,
    required String repoUrl,
    @Default(true) bool enabled,
    DateTime? lastRun,
  }) = _InstalledPlugin;

  factory InstalledPlugin.fromJson(Map<String, dynamic> json) =>
      _$InstalledPluginFromJson(json);

  String get compositeId => '$repoId/${meta.id}';
}
