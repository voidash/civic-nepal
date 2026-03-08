import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/lua_plugin.dart';
import '../services/lua_repo_service.dart';

part 'lua_plugin_provider.g.dart';

/// A plugin entry enriched with its current install/enable status.
class PluginWithStatus {
  const PluginWithStatus({
    required this.meta,
    required this.repoId,
    required this.repoUrl,
    required this.isInstalled,
    required this.isEnabled,
  });

  final LuaPluginMeta meta;
  final String repoId;
  final String repoUrl;
  final bool isInstalled;
  final bool isEnabled;

  String get compositeId => '$repoId/${meta.id}';
}

/// List of all subscribed repo URLs persisted in SharedPreferences.
@riverpod
Future<List<String>> repoUrls(RepoUrlsRef ref) async {
  await LuaRepoService.seedDefaultReposIfNeeded();
  return LuaRepoService.getRepoUrls();
}

/// Fetched (and cached) manifest for a single repo URL.
@riverpod
Future<LuaRepoManifest> repoManifest(RepoManifestRef ref, String url) async {
  return LuaRepoService.fetchManifest(url);
}

/// All installed plugins from SharedPreferences.
@riverpod
Future<List<InstalledPlugin>> installedPlugins(InstalledPluginsRef ref) async {
  return LuaRepoService.getInstalledPlugins();
}

/// Synchronous derived list of only the enabled installed plugins.
@riverpod
List<InstalledPlugin> enabledPlugins(EnabledPluginsRef ref) {
  return ref.watch(installedPluginsProvider).when(
        data: (list) => list.where((p) => p.enabled).toList(),
        loading: () => [],
        error: (_, __) => [],
      );
}

/// All plugins across all subscribed repos, merged with install/enable status.
@riverpod
Future<List<PluginWithStatus>> allRemotePlugins(AllRemotePluginsRef ref) async {
  final urls = await ref.watch(repoUrlsProvider.future);
  final installed = await ref.watch(installedPluginsProvider.future);
  final installedIds = {for (final p in installed) p.compositeId: p};

  final results = <PluginWithStatus>[];
  for (final url in urls) {
    try {
      final manifest = await ref.watch(repoManifestProvider(url).future);
      for (final meta in manifest.plugins) {
        final compositeId = '${manifest.id}/${meta.id}';
        final installedPlugin = installedIds[compositeId];
        results.add(PluginWithStatus(
          meta: meta,
          repoId: manifest.id,
          repoUrl: url,
          isInstalled: installedPlugin != null,
          isEnabled: installedPlugin?.enabled ?? false,
        ));
      }
    } on Exception catch (e) {
      // Skip repos that fail to load — don't break the whole list
      // ignore: avoid_print
      print('[allRemotePlugins] Skipping $url: $e');
    }
  }
  return results;
}
