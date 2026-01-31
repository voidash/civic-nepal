import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/home_title.dart';

/// Screen for selecting between different map views
class MapSelectorScreen extends StatelessWidget {
  const MapSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.map)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explore Nepal Section (OSM-based)
                _SectionHeader(
                  icon: Icons.explore,
                  title: l10n.exploreNepal,
                  color: Colors.teal,
                ),
                const SizedBox(height: 12),
                _MapOptionCard(
                  icon: Icons.public,
                  title: l10n.nepalMap,
                  subtitle: l10n.exploreNepalDesc,
                  color: Colors.teal,
                  onTap: () => context.push('/map/nepal'),
                ),
                const SizedBox(height: 32),

                // Election Section
                _SectionHeader(
                  icon: Icons.how_to_vote,
                  title: l10n.electionMap,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),
                _MapOptionCard(
                  icon: Icons.location_city,
                  title: l10n.districtMap,
                  subtitle: l10n.districtMapDesc,
                  color: Colors.green,
                  onTap: () => context.push('/map/districts'),
                ),
                const SizedBox(height: 12),
                _MapOptionCard(
                  icon: Icons.account_balance,
                  title: l10n.constituencyMap,
                  subtitle: l10n.constituencyMapDesc,
                  color: Colors.blue,
                  onTap: () => context.push('/map/federal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MapOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MapOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
