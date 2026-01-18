import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/home_title.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.settings)),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            children: [
              _SectionHeader(l10n.languageDisplay),
              _AppLocaleSetting(
                value: settings.appLocale,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAppLocale(value);
                },
              ),
              _ThemeSetting(
                value: settings.themeMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                },
              ),
              const Divider(),
              _SectionHeader(l10n.dataUpdates),
              _SwitchSetting(
                title: l10n.autoCheckUpdates,
                subtitle: l10n.autoCheckUpdatesDesc,
                value: settings.autoCheckUpdates,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAutoCheckUpdates(value);
                },
              ),
              _TileSetting(
                title: l10n.checkUpdatesNow,
                subtitle: l10n.checkUpdatesNowDesc,
                onTap: () {
                  _checkForUpdates(context, l10n);
                },
              ),
              _TileSetting(
                title: l10n.clearCache,
                subtitle: l10n.clearCacheDesc,
                onTap: () {
                  _clearCache(context, l10n);
                },
              ),
              const Divider(),
              _SectionHeader(l10n.notifications),
              _SwitchSetting(
                title: l10n.stickyDateNotification,
                subtitle: l10n.stickyDateNotificationDesc,
                value: settings.stickyDateNotification,
                onChanged: (value) async {
                  await ref.read(settingsProvider.notifier).setStickyDateNotification(value);
                  if (value) {
                    await NotificationService.requestPermissions();
                    await NotificationService.showStickyDateNotification();
                  } else {
                    await NotificationService.cancelStickyDateNotification();
                  }
                },
              ),
              _SwitchSetting(
                title: l10n.ipoAlerts,
                subtitle: l10n.ipoAlertsDesc,
                value: settings.ipoNotifications,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setIpoNotifications(value);
                },
              ),
              const Divider(),
              _SectionHeader(l10n.about),
              _TileSetting(
                title: l10n.about,
                subtitle: l10n.appVersion,
                onTap: () {
                  _showAboutDialog(context, l10n);
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
      ),
    );
  }

  void _checkForUpdates(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.checkingUpdates)),
    );
  }

  void _clearCache(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cacheCleared)),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: l10n.appName,
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

class _AppLocaleSetting extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _AppLocaleSetting({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(l10n.language),
      subtitle: Text(_getDisplayLanguage(value)),
      leading: const Icon(Icons.language),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, l10n),
    );
  }

  String _getDisplayLanguage(String value) {
    switch (value) {
      case 'en':
        return 'English';
      case 'ne':
        return 'नेपाली (Nepali)';
      case 'new':
        return 'नेपाल भाषा (Newari)';
      default:
        return 'नेपाली (Nepali)';
    }
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final locale in AppLocale.values)
              _LanguageOption(
                title: locale.displayName,
                subtitle: locale.nativeName,
                isSelected: value == locale.code,
                onTap: () {
                  onChanged(locale.code);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.language,
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
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(l10n.theme),
      subtitle: Text(_getDisplayTheme(value, l10n)),
      leading: Icon(_getThemeIcon(value)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, l10n),
    );
  }

  String _getDisplayTheme(String value, AppLocalizations l10n) {
    switch (value) {
      case 'light':
        return l10n.themeLight;
      case 'dark':
        return l10n.themeDark;
      default:
        return l10n.themeSystem;
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

  void _showThemeDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: l10n.themeSystem,
              subtitle: l10n.themeSystemDesc,
              icon: Icons.brightness_auto,
              isSelected: value == 'system',
              onTap: () {
                onChanged('system');
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              title: l10n.themeLight,
              subtitle: l10n.themeLightDesc,
              icon: Icons.light_mode,
              isSelected: value == 'light',
              onTap: () {
                onChanged('light');
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              title: l10n.themeDark,
              subtitle: l10n.themeDarkDesc,
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
