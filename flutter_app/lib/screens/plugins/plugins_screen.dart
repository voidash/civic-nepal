import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/lua_plugin.dart';
import '../../providers/lua_plugin_provider.dart';
import '../../services/lua_repo_service.dart';

class PluginsScreen extends ConsumerStatefulWidget {
  const PluginsScreen({super.key});

  @override
  ConsumerState<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends ConsumerState<PluginsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugins'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Installed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BrowseTab(),
          _InstalledTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddRepoDialog(context),
              tooltip: 'Add repository',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showAddRepoDialog(BuildContext context) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Plugin Repository'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Repository URL',
            hintText: 'https://yourname.github.io/nagarik-plugins',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    // Do NOT dispose the controller here — the dialog exit animation may
    // still be rendering the TextField. Let the GC collect it.

    if (url == null || url.isEmpty) return;
    try {
      await LuaRepoService.addRepo(url);
      ref.invalidate(repoUrlsProvider);
      ref.invalidate(allRemotePluginsProvider);
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add repo: $e')),
        );
      }
    }
  }
}

// ── Browse tab ────────────────────────────────────────────────────────────────

class _BrowseTab extends ConsumerWidget {
  const _BrowseTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlsAsync = ref.watch(repoUrlsProvider);

    return urlsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString(), onRetry: () => ref.invalidate(repoUrlsProvider)),
      data: (urls) {
        if (urls.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.extension_off_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No repositories yet'),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a plugin repository URL',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: urls.length,
          itemBuilder: (context, i) => _RepoSection(repoUrl: urls[i]),
        );
      },
    );
  }
}

class _RepoSection extends ConsumerStatefulWidget {
  const _RepoSection({required this.repoUrl});
  final String repoUrl;

  @override
  ConsumerState<_RepoSection> createState() => _RepoSectionState();
}

class _RepoSectionState extends ConsumerState<_RepoSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final manifestAsync = ref.watch(repoManifestProvider(widget.repoUrl));
    final allAsync = ref.watch(allRemotePluginsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          manifestAsync.when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(strokeWidth: 2),
              title: Text('Loading…'),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text(widget.repoUrl, style: const TextStyle(fontSize: 13)),
              subtitle: Text(e.toString()),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeRepo(context),
              ),
            ),
            data: (manifest) => ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(manifest.name),
              subtitle: Text('${manifest.plugins.length} plugin(s)  •  ${manifest.author}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove repository',
                    onPressed: () => _removeRepo(context),
                  ),
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            allAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
              data: (plugins) {
                final repoPlugins =
                    plugins.where((p) => p.repoUrl == widget.repoUrl).toList();
                return Column(
                  children: repoPlugins
                      .map((p) => _PluginBrowseCard(plugin: p))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _removeRepo(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Repository'),
        content: Text(
          'Remove "${widget.repoUrl}"? All installed plugins from this repo will be uninstalled.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true) return;
    await LuaRepoService.removeRepo(widget.repoUrl);
    ref.invalidate(repoUrlsProvider);
    ref.invalidate(allRemotePluginsProvider);
    ref.invalidate(installedPluginsProvider);
  }
}

class _PluginBrowseCard extends ConsumerWidget {
  const _PluginBrowseCard({required this.plugin});
  final PluginWithStatus plugin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: plugin.meta.iconUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(plugin.meta.iconUrl!))
          : const CircleAvatar(child: Icon(Icons.extension)),
      title: Text(plugin.meta.name),
      subtitle: Text(plugin.meta.description, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypeChip(type: plugin.meta.type),
          const SizedBox(width: 8),
          plugin.isInstalled
              ? const Icon(Icons.check_circle, color: Colors.green)
              : TextButton(
                  onPressed: () => _install(context, ref),
                  child: const Text('Install'),
                ),
        ],
      ),
      onTap: () => context.push('/plugins/${Uri.encodeComponent(plugin.compositeId)}'),
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    try {
      await LuaRepoService.installPlugin(plugin.repoUrl, plugin.meta);
      ref.invalidate(installedPluginsProvider);
      ref.invalidate(allRemotePluginsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plugin.meta.name} installed')),
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
}

// ── Installed tab ─────────────────────────────────────────────────────────────

class _InstalledTab extends ConsumerWidget {
  const _InstalledTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedAsync = ref.watch(installedPluginsProvider);

    return installedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(installedPluginsProvider),
      ),
      data: (plugins) {
        if (plugins.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.extension_off_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No plugins installed'),
                SizedBox(height: 8),
                Text(
                  'Browse repos and install plugins',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: plugins.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => _InstalledPluginTile(plugin: plugins[i]),
        );
      },
    );
  }
}

class _InstalledPluginTile extends ConsumerWidget {
  const _InstalledPluginTile({required this.plugin});
  final InstalledPlugin plugin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: plugin.meta.iconUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(plugin.meta.iconUrl!))
          : const CircleAvatar(child: Icon(Icons.extension)),
      title: Text(plugin.meta.name),
      subtitle: Text(
        '${plugin.meta.type.displayName}  •  v${plugin.meta.version}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: plugin.enabled,
            onChanged: (value) async {
              await LuaRepoService.setPluginEnabled(plugin.compositeId, value);
              ref.invalidate(installedPluginsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Uninstall',
            onPressed: () => _uninstall(context, ref),
          ),
        ],
      ),
      onTap: () => context.push('/plugins/${Uri.encodeComponent(plugin.compositeId)}'),
    );
  }

  Future<void> _uninstall(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uninstall Plugin'),
        content: Text('Uninstall "${plugin.meta.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uninstall')),
        ],
      ),
    );
    if (confirm != true) return;
    await LuaRepoService.uninstallPlugin(plugin.compositeId);
    ref.invalidate(installedPluginsProvider);
    ref.invalidate(allRemotePluginsProvider);
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final LuaPluginType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      LuaPluginType.startup => Colors.orange,
      LuaPluginType.calendarInject => Colors.blue,
      LuaPluginType.markdownPanel => Colors.purple,
      LuaPluginType.newScreen => Colors.teal,
      LuaPluginType.background => Colors.grey,
    };
    return Chip(
      label: Text(type.displayName, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
