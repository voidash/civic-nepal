import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pinnable_item.dart';
import '../../providers/settings_provider.dart';
import '../../services/nepali_date_service.dart';
import '../../widgets/custom_bottom_nav.dart';

/// Home tab content with feature cards and utilities
/// Used within the StatefulShellRoute bottom navigation
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  late NepaliDateTime _todayBs;
  late DateTime _todayAd;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _updateDate();
    _scheduleMidnightUpdate();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _updateDate() {
    setState(() {
      _todayAd = DateTime.now();
      _todayBs = NepaliDateService.today();
    });
  }

  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);

    _midnightTimer = Timer(duration, () {
      _updateDate();
      _scheduleMidnightUpdate();
    });
  }

  Future<void> _togglePin(String route) async {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.mediumImpact();
    final nowPinned = await ref.read(settingsProvider.notifier).togglePin(route);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowPinned ? l10n.pinnedToast : l10n.unpinnedToast),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateTo(String route) {
    // Record visit for recent tracking
    ref.read(settingsProvider.notifier).recordVisit(route);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: l10n.settings,
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1), // Home
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) => _buildBody(context, l10n, settings),
          loading: () => _buildBody(context, l10n, null),
          error: (_, __) => _buildBody(context, l10n, null),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, SettingsData? settings) {
    final pinnedRoutes = settings?.pinnedRoutes ?? [];
    final recentRoutes = settings?.recentRoutes ?? [];

    // Filter recent to exclude pinned items
    final filteredRecent = recentRoutes
        .where((route) => !pinnedRoutes.contains(route))
        .toList()
        .reversed // Most recent first
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's date widget
          _TodayDateWidget(
            todayBs: _todayBs,
            todayAd: _todayAd,
            onTap: () => _navigateTo('/calendar'),
          ),
          const SizedBox(height: 20),

          // Pinned section (only if there are pinned items)
          if (pinnedRoutes.isNotEmpty) ...[
            _SectionHeader(title: l10n.pinned, titleNp: l10n.pinnedNp),
            const SizedBox(height: 12),
            _PinnedGrid(
              routes: pinnedRoutes,
              onTap: _navigateTo,
              onLongPress: _togglePin,
              isPinned: (route) => pinnedRoutes.contains(route),
            ),
            const SizedBox(height: 24),
          ],

          // Recent section (only if there are recent items not already pinned)
          if (filteredRecent.isNotEmpty) ...[
            _SectionHeader(title: l10n.recent, titleNp: l10n.recentNp),
            const SizedBox(height: 12),
            _PinnedGrid(
              routes: filteredRecent,
              onTap: _navigateTo,
              onLongPress: _togglePin,
              isPinned: (route) => pinnedRoutes.contains(route),
            ),
            const SizedBox(height: 24),
          ],

          // Quick access grid
          _SectionHeader(title: l10n.explore, titleNp: l10n.exploreNp),
          const SizedBox(height: 12),
          _QuickAccessGrid(
            l10n: l10n,
            onTap: _navigateTo,
            onLongPress: _togglePin,
            isPinned: (route) => pinnedRoutes.contains(route),
          ),
          const SizedBox(height: 24),

          // Utilities section
          _SectionHeader(title: l10n.utilities, titleNp: l10n.utilitiesNp),
          const SizedBox(height: 12),
          _UtilitiesGrid(
            l10n: l10n,
            onTap: _navigateTo,
            onLongPress: _togglePin,
            isPinned: (route) => pinnedRoutes.contains(route),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TodayDateWidget extends StatelessWidget {
  const _TodayDateWidget({
    required this.todayBs,
    required this.todayAd,
    required this.onTap,
  });

  final NepaliDateTime todayBs;
  final DateTime todayAd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayNameNp = NepaliDateService.getWeekdayNp(todayBs);
    final dayNameEn = NepaliDateService.getWeekdayEn(todayBs);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Date number
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    todayBs.day.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Date details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NepaliDateService.formatNp(todayBs),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NepaliDateService.formatEn(todayBs),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dayNameNp ($dayNameEn)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Calendar indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).viewCalendar,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.titleNp,
  });

  final String title;
  final String titleNp;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          titleNp,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Grid for pinned/recent items (dynamic based on routes)
class _PinnedGrid extends StatelessWidget {
  const _PinnedGrid({
    required this.routes,
    required this.onTap,
    required this.onLongPress,
    required this.isPinned,
  });

  final List<String> routes;
  final void Function(String route) onTap;
  final void Function(String route) onLongPress;
  final bool Function(String route) isPinned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = PinnableItems.byRoutes(routes);

    // Build rows of 2 items each
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final row = Row(
        children: [
          Expanded(
            child: _PinnableCard(
              item: items[i],
              l10n: l10n,
              onTap: () => onTap(items[i].route),
              onLongPress: () => onLongPress(items[i].route),
              isPinned: isPinned(items[i].route),
            ),
          ),
          const SizedBox(width: 12),
          if (i + 1 < items.length)
            Expanded(
              child: _PinnableCard(
                item: items[i + 1],
                l10n: l10n,
                onTap: () => onTap(items[i + 1].route),
                onLongPress: () => onLongPress(items[i + 1].route),
                isPinned: isPinned(items[i + 1].route),
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      );
      rows.add(row);
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }
}

/// Card for a pinnable item (used in Pinned/Recent sections)
class _PinnableCard extends StatelessWidget {
  const _PinnableCard({
    required this.item,
    required this.l10n,
    required this.onTap,
    required this.onLongPress,
    required this.isPinned,
  });

  final PinnableItem item;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: item.color.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  Icon(item.icon, size: 28, color: item.color),
                  const SizedBox(height: 8),
                  Text(
                    item.getTitle(l10n),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    item.getTitleNp(l10n),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isPinned)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: item.color.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({
    required this.l10n,
    required this.onTap,
    required this.onLongPress,
    required this.isPinned,
  });

  final AppLocalizations l10n;
  final void Function(String route) onTap;
  final void Function(String route) onLongPress;
  final bool Function(String route) isPinned;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.account_balance,
                title: l10n.govt,
                titleNp: l10n.govtNp,
                color: secondaryColor,
                route: '/how-nepal-works',
                onTap: () => onTap('/how-nepal-works'),
                onLongPress: () => onLongPress('/how-nepal-works'),
                isPinned: isPinned('/how-nepal-works'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.map,
                title: l10n.map,
                titleNp: l10n.mapNp,
                color: const Color(0xFF2E7D32),
                route: '/map',
                onTap: () => onTap('/map'),
                onLongPress: () => onLongPress('/map'),
                isPinned: isPinned('/map'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.gavel,
                title: l10n.rights,
                titleNp: l10n.rightsNp,
                color: const Color(0xFF6A1B9A),
                route: '/constitutional-rights',
                onTap: () => onTap('/constitutional-rights'),
                onLongPress: () => onLongPress('/constitutional-rights'),
                isPinned: isPinned('/constitutional-rights'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.extension,
                title: 'Plugins',
                titleNp: 'प्लगइन',
                color: const Color(0xFF7B1FA2),
                route: '/plugins',
                onTap: () => onTap('/plugins'),
                onLongPress: () => onLongPress('/plugins'),
                isPinned: isPinned('/plugins'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String titleNp;
  final Color color;
  final String route;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isPinned;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.titleNp,
    required this.color,
    required this.route,
    required this.onTap,
    required this.onLongPress,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    titleNp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isPinned)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UtilitiesGrid extends StatelessWidget {
  const _UtilitiesGrid({
    required this.l10n,
    required this.onTap,
    required this.onLongPress,
    required this.isPinned,
  });

  final AppLocalizations l10n;
  final void Function(String route) onTap;
  final void Function(String route) onLongPress;
  final bool Function(String route) isPinned;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.photo_library,
                title: l10n.photoMerger,
                titleNp: l10n.photoMergerNp,
                color: const Color(0xFF7B1FA2),
                route: '/photo-merger',
                onTap: () => onTap('/photo-merger'),
                onLongPress: () => onLongPress('/photo-merger'),
                isPinned: isPinned('/photo-merger'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.compress,
                title: l10n.imageCompressor,
                titleNp: l10n.imageCompressorNp,
                color: const Color(0xFF1976D2),
                route: '/photo-compress',
                onTap: () => onTap('/photo-compress'),
                onLongPress: () => onLongPress('/photo-compress'),
                isPinned: isPinned('/photo-compress'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row
        Row(
          children: [
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.calendar_month,
                title: l10n.calendar,
                titleNp: l10n.calendarNp,
                color: const Color(0xFF1976D2),
                route: '/calendar',
                onTap: () => onTap('/calendar'),
                onLongPress: () => onLongPress('/calendar'),
                isPinned: isPinned('/calendar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.swap_horiz,
                title: l10n.dateConvert,
                titleNp: l10n.dateConvertNp,
                color: const Color(0xFFE65100),
                route: '/date-converter',
                onTap: () => onTap('/date-converter'),
                onLongPress: () => onLongPress('/date-converter'),
                isPinned: isPinned('/date-converter'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third row - Forex and Gold
        Row(
          children: [
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.currency_exchange,
                title: l10n.forex,
                titleNp: l10n.forexNp,
                color: const Color(0xFF2E7D32),
                route: '/forex',
                onTap: () => onTap('/forex'),
                onLongPress: () => onLongPress('/forex'),
                isPinned: isPinned('/forex'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.diamond,
                title: l10n.goldSilver,
                titleNp: l10n.goldSilverNp,
                color: const Color(0xFFFFB300),
                route: '/gold-price',
                onTap: () => onTap('/gold-price'),
                onLongPress: () => onLongPress('/gold-price'),
                isPinned: isPinned('/gold-price'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Fourth row - PDF Compressor and Unicode Converter
        Row(
          children: [
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.picture_as_pdf,
                title: l10n.pdfCompressorShort,
                titleNp: l10n.pdfCompressorNp,
                color: const Color(0xFFD32F2F),
                route: '/pdf-compress',
                onTap: () => onTap('/pdf-compress'),
                onLongPress: () => onLongPress('/pdf-compress'),
                isPinned: isPinned('/pdf-compress'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UtilityGridCard(
                icon: Icons.translate,
                title: l10n.unicodeShort,
                titleNp: l10n.unicodeNp,
                color: const Color(0xFF00796B),
                route: '/unicode',
                onTap: () => onTap('/unicode'),
                onLongPress: () => onLongPress('/unicode'),
                isPinned: isPinned('/unicode'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UtilityGridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String titleNp;
  final Color color;
  final String route;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isPinned;

  const _UtilityGridCard({
    required this.icon,
    required this.title,
    required this.titleNp,
    required this.color,
    required this.route,
    required this.onTap,
    required this.onLongPress,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  Icon(icon, size: 28, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    titleNp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isPinned)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
