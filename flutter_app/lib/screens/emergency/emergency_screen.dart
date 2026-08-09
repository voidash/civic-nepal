import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/earthquake.dart';
import '../../providers/earthquake_provider.dart';
import '../../widgets/home_title.dart';

/// Alerts Hub Screen - Main entry point for alerts & disaster response
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final earthquakesAsync = ref.watch(recentEarthquakesProvider);

    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.alerts)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earthquake summary card with live data
            _EarthquakeSummaryCard(
              earthquakesAsync: earthquakesAsync,
              onTap: () => context.push('/alerts/earthquakes'),
            ),
            const SizedBox(height: 16),

            // Quick access cards row
            Row(
              children: [
                Expanded(
                  child: _AlertHubCard(
                    icon: Icons.phone,
                    title: l10n.contacts,
                    titleNp: l10n.contactsNp,
                    color: Colors.red.shade600,
                    description: l10n.emergencyContactsDesc,
                    onTap: () => context.push('/alerts/contacts'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlertHubCard(
                    icon: Icons.directions_car,
                    title: l10n.roadClosures,
                    titleNp: l10n.roadClosuresNp,
                    color: Colors.orange.shade700,
                    description: l10n.roadClosuresDesc,
                    onTap: () => _openRoadClosures(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _AlertHubCard(
                    icon: Icons.cloud,
                    title: l10n.weather,
                    titleNp: l10n.weatherNp,
                    color: Colors.blue.shade600,
                    description: l10n.weatherDesc,
                    onTap: () => _openWeather(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlertHubCard(
                    icon: Icons.link,
                    title: l10n.resourcesTab,
                    titleNp: l10n.resourcesNp,
                    color: Colors.teal.shade600,
                    description: l10n.resourcesDesc,
                    onTap: () => context.push('/alerts/resources'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Safety tips section
            Text(
              l10n.safetyTips,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _SafetyTipsCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _openRoadClosures(BuildContext context) async {
    final uri = Uri.parse('https://navigate.dor.gov.np/app/dashboard');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWeather(BuildContext context) async {
    final uri = Uri.parse('https://www.dhm.gov.np/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Earthquake summary card with live data preview
class _EarthquakeSummaryCard extends StatelessWidget {
  final AsyncValue<List<Earthquake>> earthquakesAsync;
  final VoidCallback onTap;

  const _EarthquakeSummaryCard({
    required this.earthquakesAsync,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.orange.shade600,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.ssid_chart, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.earthquakesTab,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.recentSeismicActivity,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),

            // Content
            earthquakesAsync.when(
              data: (earthquakes) {
                final significant = earthquakes
                    .where((e) => e.magnitude >= 4.0)
                    .take(3)
                    .toList();

                if (significant.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade600, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.noSignificantEarthquakes,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ...significant.map((eq) => _MiniEarthquakeRow(earthquake: eq)),
                    if (earthquakes.length > 3)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.viewAllEarthquakes(earthquakes.length),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.errorLoading)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniEarthquakeRow extends StatelessWidget {
  final Earthquake earthquake;

  const _MiniEarthquakeRow({required this.earthquake});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final magColor = _getMagnitudeColor(earthquake.magnitude);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: magColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: magColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                earthquake.magnitude.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: magColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earthquake.place,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTimeAgo(earthquake.time),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude >= 6.0) return Colors.red.shade700;
    if (magnitude >= 5.0) return Colors.orange.shade700;
    if (magnitude >= 4.0) return Colors.amber.shade700;
    return Colors.yellow.shade700;
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
}

/// Hub card for navigation to sub-screens
class _AlertHubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String titleNp;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _AlertHubCard({
    required this.icon,
    required this.title,
    required this.titleNp,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (titleNp.isNotEmpty)
                Text(
                titleNp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final tips = [
      (Icons.table_restaurant, l10n.safetyTip1),
      (Icons.door_front_door, l10n.safetyTip2),
      (Icons.electric_bolt, l10n.safetyTip3),
      (Icons.home, l10n.safetyTip4),
      (Icons.backpack, l10n.safetyTip5),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(tip.$1, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tip.$2, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
