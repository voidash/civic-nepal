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
  // Enable URL updates for push/pop operations on web
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final path = state.uri.path;
      final uri = state.uri;
      // Handle deep links from widgets
      if (uri.scheme == 'nepalcivic' && uri.host.isNotEmpty) {
        return '/${uri.host}${uri.path}';
      }
      // Redirect root to /home
      if (path == '/' || path.isEmpty) {
        return '/home';
      }
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
        path: '/constitutional-rights',
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
            parentNavigatorKey: _rootNavigatorKey,
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
        path: '/how-nepal-works',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HowNepalWorksScreen(),
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
        path: '/photo-merger',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CitizenshipMergerScreen(),
      ),
      GoRoute(
        path: '/tools/citizenship-merger',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CitizenshipMergerScreen(),
      ),
      GoRoute(
        path: '/photo-compress',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ImageCompressorScreen(),
      ),
      GoRoute(
        path: '/tools/image-compressor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ImageCompressorScreen(),
      ),
      GoRoute(
        path: '/date-converter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DateConverterScreen(),
      ),
      GoRoute(
        path: '/tools/date-converter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DateConverterScreen(),
      ),
      GoRoute(
        path: '/gov',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HowNepalWorksScreen(),
      ),
      // Legacy routes redirect to unified government screen
      GoRoute(
        path: '/gov-services',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/government',
      ),
      GoRoute(
        path: '/how-to-get',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/government',
      ),
      GoRoute(
        path: '/tools/nepali-calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NepaliCalendarScreen(),
      ),
      GoRoute(
        path: '/forex',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForexScreen(),
      ),
      GoRoute(
        path: '/tools/forex',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForexScreen(),
      ),
      GoRoute(
        path: '/gold-price',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BullionScreen(),
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
class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({
    required this.currentPath,
    required this.child,
    super.key,
  });

  final String currentPath;
  final Widget child;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  int _getSelectedIndex() {
    if (widget.currentPath.startsWith('/calendar')) return 0;
    if (widget.currentPath.startsWith('/home')) return 1;
    if (widget.currentPath.startsWith('/ipo')) return 2;
    if (widget.currentPath.startsWith('/rights')) return 3;
    return 1; // default to home
  }

  bool get _isHome => widget.currentPath.startsWith('/home');

  Future<bool> _onWillPop() async {
    if (!_isHome) {
      context.go('/home');
      return false; // Don't pop, we navigated instead
    }
    return true; // Allow pop (exit app)
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = _getSelectedIndex();

    return PopScope(
      canPop: _isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isHome) {
          // Use post-frame callback to avoid issues with navigation during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/home');
            }
          });
        }
      },
      child: Scaffold(
        body: widget.child,
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
      ),
    );
  }
}
