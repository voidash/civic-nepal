import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// A screen/feature that can be pinned to the home screen
class PinnableItem {
  final String route;
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations l10n) getTitle;
  final String Function(AppLocalizations l10n) getTitleNp;

  const PinnableItem({
    required this.route,
    required this.icon,
    required this.color,
    required this.getTitle,
    required this.getTitleNp,
  });
}

/// Registry of all pinnable items in the app
class PinnableItems {
  PinnableItems._();

  static final List<PinnableItem> all = [
    // Explore section items
    PinnableItem(
      route: '/how-nepal-works',
      icon: Icons.account_balance,
      color: const Color(0xFF5C6BC0),
      getTitle: (l10n) => l10n.govt,
      getTitleNp: (l10n) => l10n.govtNp,
    ),
    PinnableItem(
      route: '/map',
      icon: Icons.map,
      color: const Color(0xFF2E7D32),
      getTitle: (l10n) => l10n.map,
      getTitleNp: (l10n) => l10n.mapNp,
    ),
    PinnableItem(
      route: '/constitutional-rights',
      icon: Icons.gavel,
      color: const Color(0xFF6A1B9A),
      getTitle: (l10n) => l10n.rights,
      getTitleNp: (l10n) => l10n.rightsNp,
    ),
    PinnableItem(
      route: '/alerts',
      icon: Icons.notifications_active,
      color: const Color(0xFFD32F2F),
      getTitle: (l10n) => l10n.alerts,
      getTitleNp: (l10n) => l10n.alertsNp,
    ),
    // Utility items
    PinnableItem(
      route: '/photo-merger',
      icon: Icons.photo_library,
      color: const Color(0xFF7B1FA2),
      getTitle: (l10n) => l10n.photoMerger,
      getTitleNp: (l10n) => l10n.photoMergerNp,
    ),
    PinnableItem(
      route: '/photo-compress',
      icon: Icons.compress,
      color: const Color(0xFF1976D2),
      getTitle: (l10n) => l10n.imageCompressor,
      getTitleNp: (l10n) => l10n.imageCompressorNp,
    ),
    PinnableItem(
      route: '/calendar',
      icon: Icons.calendar_month,
      color: const Color(0xFF1976D2),
      getTitle: (l10n) => l10n.calendar,
      getTitleNp: (l10n) => l10n.calendarNp,
    ),
    PinnableItem(
      route: '/date-converter',
      icon: Icons.swap_horiz,
      color: const Color(0xFFE65100),
      getTitle: (l10n) => l10n.dateConvert,
      getTitleNp: (l10n) => l10n.dateConvertNp,
    ),
    PinnableItem(
      route: '/forex',
      icon: Icons.currency_exchange,
      color: const Color(0xFF2E7D32),
      getTitle: (l10n) => l10n.forex,
      getTitleNp: (l10n) => l10n.forexNp,
    ),
    PinnableItem(
      route: '/gold-price',
      icon: Icons.diamond,
      color: const Color(0xFFFFB300),
      getTitle: (l10n) => l10n.goldSilver,
      getTitleNp: (l10n) => l10n.goldSilverNp,
    ),
    PinnableItem(
      route: '/pdf-compress',
      icon: Icons.picture_as_pdf,
      color: const Color(0xFFD32F2F),
      getTitle: (l10n) => l10n.pdfCompressorShort,
      getTitleNp: (l10n) => l10n.pdfCompressorNp,
    ),
    PinnableItem(
      route: '/unicode',
      icon: Icons.translate,
      color: const Color(0xFF00796B),
      getTitle: (l10n) => l10n.unicodeShort,
      getTitleNp: (l10n) => l10n.unicodeNp,
    ),
    PinnableItem(
      route: '/leaders',
      icon: Icons.people,
      color: const Color(0xFF455A64),
      getTitle: (l10n) => l10n.leaders,
      getTitleNp: (l10n) => l10n.leadersNp,
    ),
    PinnableItem(
      route: '/news',
      icon: Icons.newspaper,
      color: const Color(0xFF1877F2),
      getTitle: (_) => 'RONB Feed',
      getTitleNp: (_) => 'समाचार',
    ),
    PinnableItem(
      route: '/ipo',
      icon: Icons.trending_up,
      color: const Color(0xFF00897B),
      getTitle: (l10n) => l10n.ipoShares,
      getTitleNp: (l10n) => l10n.ipoSharesNp,
    ),
  ];

  /// Get a pinnable item by route
  static PinnableItem? byRoute(String route) {
    try {
      return all.firstWhere((item) => item.route == route);
    } catch (_) {
      return null;
    }
  }

  /// Get multiple pinnable items by routes, preserving order
  static List<PinnableItem> byRoutes(List<String> routes) {
    return routes
        .map((route) => byRoute(route))
        .where((item) => item != null)
        .cast<PinnableItem>()
        .toList();
  }

  /// Routes that should be tracked for recent visits
  static final Set<String> trackableRoutes = all.map((e) => e.route).toSet();

  /// Check if a route should be tracked
  static bool isTrackable(String route) => trackableRoutes.contains(route);
}
