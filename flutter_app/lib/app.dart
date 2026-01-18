import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'l10n/app_localizations.dart';
import 'screens/home/home_screen.dart';
import 'screens/constitution/constitution_screen.dart';
import 'screens/leaders/leaders_screen.dart';
import 'screens/leaders/leader_detail_screen.dart';
import 'screens/map/district_map_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tools/citizenship_merger_screen.dart';
import 'screens/tools/image_compressor_screen.dart';
import 'screens/tools/date_converter_screen.dart';
import 'screens/tools/gov_services_screen.dart';
import 'screens/tools/nepali_calendar_screen.dart';
import 'screens/tools/forex_screen.dart';
import 'screens/tools/bullion_screen.dart';
import 'screens/tools/ipo_shares_screen.dart';
import 'screens/government/how_nepal_works_screen.dart';

part 'app.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.uri.path;
      debugPrint('GoRouter redirect called with path: $path');

      final uri = state.uri;
      // Handle deep links from widgets
      if (uri.scheme == 'nepalcivic' && uri.host.isNotEmpty) {
        return '/${uri.host}${uri.path}';
      }
      // Redirect root to /home
      if (path == '/' || path.isEmpty) {
        debugPrint('Redirecting to /home');
        return '/home';
      }
      debugPrint('No redirect needed for: $path');
      return null;
    },
    routes: [
      // Shell route for bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeTab(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NepaliCalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/ipo',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: IpoSharesScreen(),
            ),
          ),
          GoRoute(
            path: '/rights',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConstitutionScreen(),
            ),
          ),
        ],
      ),
      // Routes outside of bottom nav (full screen)
      GoRoute(
        path: '/constitution',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConstitutionScreen(),
      ),
      GoRoute(
        path: '/leaders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LeadersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final leaderId = state.pathParameters['id'] ?? '';
              return LeaderDetailScreen(leaderId: leaderId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/map',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DistrictMapScreen(),
      ),
      GoRoute(
        path: '/government',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HowNepalWorksScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/tools/citizenship-merger',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CitizenshipMergerScreen(),
      ),
      GoRoute(
        path: '/tools/image-compressor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ImageCompressorScreen(),
      ),
      GoRoute(
        path: '/tools/date-converter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DateConverterScreen(),
      ),
      GoRoute(
        path: '/tools/gov-services',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GovServicesScreen(
          initialCategory: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(
        path: '/tools/nepali-calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NepaliCalendarScreen(),
      ),
      GoRoute(
        path: '/tools/forex',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForexScreen(),
      ),
      GoRoute(
        path: '/tools/bullion',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BullionScreen(),
      ),
      GoRoute(
        path: '/tools/ipo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IpoSharesScreen(),
      ),
    ],
  );
}

/// Scaffold with bottom navigation bar
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.currentPath,
    required this.child,
    super.key,
  });

  final String currentPath;
  final Widget child;

  int _getSelectedIndex() {
    if (currentPath.startsWith('/calendar')) return 0;
    if (currentPath.startsWith('/home')) return 1;
    if (currentPath.startsWith('/ipo')) return 2;
    if (currentPath.startsWith('/rights')) return 3;
    return 1; // default to home
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = _getSelectedIndex();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final paths = ['/calendar', '/home', '/ipo', '/rights'];
          context.go(paths[index]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_outlined),
            selectedIcon: const Icon(Icons.show_chart),
            label: l10n.navIpo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.gavel_outlined),
            selectedIcon: const Icon(Icons.gavel),
            label: l10n.navRights,
          ),
        ],
      ),
    );
  }
}
