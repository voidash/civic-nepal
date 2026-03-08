import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lua_plugin.dart';
import '../../providers/lua_plugin_provider.dart';
import '../../services/lua_repo_service.dart';

class PluginDetailScreen extends ConsumerWidget {
  const PluginDetailScreen({super.key, required this.compositeId});

  final String compositeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedAsync = ref.watch(installedPluginsProvider);
    final allAsync = ref.watch(allRemotePluginsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plugin Details')),
      body: installedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (installed) {
          final installedPlugin =
              installed.where((p) => p.compositeId == compositeId).firstOrNull;

          if (installedPlugin != null) {
            return _PluginDetailView(
              meta: installedPlugin.meta,
              repoUrl: installedPlugin.repoUrl,
              isInstalled: true,
              isEnabled: installedPlugin.enabled,
              lastRun: installedPlugin.lastRun,
              compositeId: compositeId,
            );
          }

          // Not installed — look it up in remote listings
          return allAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allPlugins) {
              final remote = allPlugins
                  .where((p) => p.compositeId == compositeId)
                  .firstOrNull;
              if (remote == null) {
                return const Center(child: Text('Plugin not found'));
              }
              return _PluginDetailView(
                meta: remote.meta,
                repoUrl: remote.repoUrl,
                isInstalled: false,
                isEnabled: false,
                lastRun: null,
                compositeId: compositeId,
              );
            },
          );
        },
      ),
    );
  }
}

class _PluginDetailView extends ConsumerWidget {
  const _PluginDetailView({
    required this.meta,
    required this.repoUrl,
    required this.isInstalled,
    required this.isEnabled,
    required this.lastRun,
    required this.compositeId,
  });

  final LuaPluginMeta meta;
  final String repoUrl;
  final bool isInstalled;
  final bool isEnabled;
  final DateTime? lastRun;
  final String compositeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = switch (meta.type) {
      LuaPluginType.startup => Colors.orange,
      LuaPluginType.calendarInject => Colors.blue,
      LuaPluginType.markdownPanel => Colors.purple,
      LuaPluginType.newScreen => Colors.teal,
      LuaPluginType.background => Colors.grey,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              meta.iconUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(meta.iconUrl!, width: 64, height: 64),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.extension, size: 36, color: typeColor),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      meta.author ?? 'Unknown author',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        meta.type.displayName,
                        style: TextStyle(fontSize: 12, color: typeColor),
                      ),
                      backgroundColor: typeColor.withValues(alpha: 0.1),
                      side: BorderSide(color: typeColor.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Meta info
          _InfoRow(label: 'Version', value: meta.version),
          _InfoRow(label: 'Entry point', value: meta.entryPoint),
          if (meta.intervalHours != null)
            _InfoRow(label: 'Interval', value: '${meta.intervalHours}h'),
          _InfoRow(label: 'Requires network', value: meta.requiresNetwork ? 'Yes' : 'No'),
          if (lastRun != null)
            _InfoRow(label: 'Last run', value: lastRun!.toLocal().toString()),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Description
          Text(meta.description, style: Theme.of(context).textTheme.bodyLarge),

          const SizedBox(height: 24),

          // Actions
          if (isInstalled) ...[
            Row(
              children: [
                const Text('Enabled'),
                const SizedBox(width: 12),
                Switch(
                  value: isEnabled,
                  onChanged: (value) async {
                    await LuaRepoService.setPluginEnabled(compositeId, value);
                    ref.invalidate(installedPluginsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () => _runNow(context, ref),
                  child: const Text('Run now'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _uninstall(context, ref),
                  child: const Text('Uninstall'),
                ),
              ],
            ),
          ] else
            FilledButton(
              onPressed: () => _install(context, ref),
              child: const Text('Install'),
            ),
        ],
      ),
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    try {
      await LuaRepoService.installPlugin(repoUrl, meta);
      ref.invalidate(installedPluginsProvider);
      ref.invalidate(allRemotePluginsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${meta.name} installed')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Install failed: $e')),
        );
      }
    }
  }

  Future<void> _uninstall(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uninstall Plugin'),
        content: Text('Uninstall "${meta.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uninstall')),
        ],
      ),
    );
    if (confirm != true) return;
    await LuaRepoService.uninstallPlugin(compositeId);
    ref.invalidate(installedPluginsProvider);
    ref.invalidate(allRemotePluginsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _runNow(BuildContext context, WidgetRef ref) async {
    try {
      final result = await LuaRepoService.callPlugin(
        compositeId,
        meta.entryPoint,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Result: ${result ?? 'nil'}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
