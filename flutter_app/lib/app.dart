import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'l10n/app_localizations.dart';
import 'screens/home/home_screen.dart';
import 'screens/constitution/constitution_screen.dart';
import 'screens/leaders/leaders_screen.dart';
import 'screens/leaders/leader_detail_screen.dart';
import 'screens/map/map_selector_screen.dart';
import 'screens/map/district_map_screen.dart';
import 'screens/map/federal_map_screen.dart';
import 'screens/map/local_body_screen.dart';
import 'screens/map/constituency_screen.dart';
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
      // Home is the main entry point
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeTab(),
      ),
      // Calendar, IPO, Rights are regular pushed routes (like Government)
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NepaliCalendarScreen(),
      ),
      GoRoute(
        path: '/ipo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IpoSharesScreen(),
      ),
      GoRoute(
        path: '/rights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConstitutionScreen(),
      ),
      // Other full screen routes
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
        builder: (context, state) => const MapSelectorScreen(),
        routes: [
          // District map (local level - mayors, etc.)
          GoRoute(
            path: 'districts',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const DistrictMapScreen(),
            routes: [
              // Local bodies for a specific district
              GoRoute(
                path: ':district',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final district = state.pathParameters['district'] ?? '';
                  return LocalBodyScreen(districtName: Uri.decodeComponent(district));
                },
              ),
            ],
          ),
          // Federal constituency map
          GoRoute(
            path: 'federal',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FederalMapScreen(),
          ),
          // Legacy: Constituencies for a specific district (from old flow)
          GoRoute(
            path: 'constituencies/:district',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final district = state.pathParameters['district'] ?? '';
              return ConstituencyScreen(districtName: Uri.decodeComponent(district));
            },
          ),
        ],
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
      // Alias for deep links that might arrive without /tools/ prefix
      GoRoute(
        path: '/nepali-calendar',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/calendar',
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

