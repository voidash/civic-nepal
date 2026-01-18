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

// Keys for shell branches to maintain state
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorCalendarKey = GlobalKey<NavigatorState>(debugLabel: 'calendar');
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorIpoKey = GlobalKey<NavigatorState>(debugLabel: 'ipo');
final _shellNavigatorRightsKey = GlobalKey<NavigatorState>(debugLabel: 'rights');

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // Handle deep links from widgets (nepalcivic://tools/nepali-calendar)
    redirect: (context, state) {
      // Deep link: nepalcivic://tools/nepali-calendar parses as host=tools, path=/nepali-calendar
      // We need to reconstruct the full path
      final uri = state.uri;
      if (uri.scheme == 'nepalcivic' && uri.host.isNotEmpty) {
        // Reconstruct: /{host}{path}
        return '/${uri.host}${uri.path}';
      }
      // Redirect root to /home
      if (state.uri.path == '/' || state.uri.path.isEmpty) {
        return '/home';
      }
      return null;
    },
    routes: [
      // Bottom navigation shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Calendar tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCalendarKey,
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const NepaliCalendarScreen(),
              ),
            ],
          ),
          // Home tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeTab(),
              ),
            ],
          ),
          // IPO tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorIpoKey,
            routes: [
              GoRoute(
                path: '/ipo',
                builder: (context, state) => const IpoSharesScreen(),
              ),
            ],
          ),
          // Rights/Constitution tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorRightsKey,
            routes: [
              GoRoute(
                path: '/rights',
                builder: (context, state) => const ConstitutionScreen(),
              ),
            ],
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

/// Scaffold with bottom navigation bar for shell routes
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
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
