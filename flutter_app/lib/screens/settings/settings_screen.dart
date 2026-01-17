import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            children: [
              const _SectionHeader('Language & Display'),
              _LanguageSetting(
                value: settings.languagePreference,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setLanguagePreference(value);
                },
              ),
              _ThemeSetting(
                value: settings.themeMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                },
              ),
              const Divider(),
              const _SectionHeader('Data & Updates'),
              _SwitchSetting(
                title: 'Auto-check for updates',
                subtitle: 'Check for new data on app launch',
                value: settings.autoCheckUpdates,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAutoCheckUpdates(value);
                },
              ),
              _TileSetting(
                title: 'Check for updates now',
                subtitle: 'Download latest leader data',
                onTap: () {
                  _checkForUpdates(context);
                },
              ),
              _TileSetting(
                title: 'Clear cache',
                subtitle: 'Free up storage space',
                onTap: () {
                  _clearCache(context);
                },
              ),
              const Divider(),
              const _SectionHeader('About'),
              _TileSetting(
                title: 'About',
                subtitle: 'Nepal Civic App v1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for updates...')),
    );
  }

  void _clearCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Nepal Civic',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Nepal Civic Project',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _LanguageSetting extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _LanguageSetting({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Language'),
      subtitle: Text(_getDisplayLanguage(value)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Show language selection dialog
      },
    );
  }

  String _getDisplayLanguage(String value) {
    switch (value) {
      case 'both':
        return 'Both Languages';
      case 'nepali':
        return 'नेपाली (Nepali)';
      case 'english':
        return 'English';
      default:
        return 'Both Languages';
    }
  }
}

class _ViewModeSetting extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _ViewModeSetting({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Default View Mode'),
      subtitle: Text(value == 'paragraph' ? 'Paragraph' : 'Sentence'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Show view mode selection dialog
      },
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchSetting({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _TileSetting extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _TileSetting({
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ThemeSetting extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _ThemeSetting({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Theme'),
      subtitle: Text(_getDisplayTheme(value)),
      leading: Icon(_getThemeIcon(value)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context),
    );
  }

  String _getDisplayTheme(String value) {
    switch (value) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  IconData _getThemeIcon(String value) {
    switch (value) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: 'System',
              subtitle: 'Follow device settings',
              icon: Icons.brightness_auto,
              isSelected: value == 'system',
              onTap: () {
                onChanged('system');
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              title: 'Light',
              subtitle: 'Always light theme',
              icon: Icons.light_mode,
              isSelected: value == 'light',
              onTap: () {
                onChanged('light');
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              title: 'Dark',
              subtitle: 'Always dark theme',
              icon: Icons.dark_mode,
              isSelected: value == 'dark',
              onTap: () {
                onChanged('dark');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : null,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
