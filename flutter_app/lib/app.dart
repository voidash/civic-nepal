import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    // Handle deep links from widgets (nepalcivic://tools/nepali-calendar)
    redirect: (context, state) {
      // Deep link: nepalcivic://tools/nepali-calendar parses as host=tools, path=/nepali-calendar
      // We need to reconstruct the full path
      final uri = state.uri;
      if (uri.scheme == 'nepalcivic' && uri.host.isNotEmpty) {
        // Reconstruct: /{host}{path}
        return '/${uri.host}${uri.path}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/constitution',
        builder: (context, state) => const ConstitutionScreen(),
      ),
      GoRoute(
        path: '/leaders',
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
        builder: (context, state) => const DistrictMapScreen(),
      ),
      GoRoute(
        path: '/government',
        builder: (context, state) => const HowNepalWorksScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/tools/citizenship-merger',
        builder: (context, state) => const CitizenshipMergerScreen(),
      ),
      GoRoute(
        path: '/tools/image-compressor',
        builder: (context, state) => const ImageCompressorScreen(),
      ),
      GoRoute(
        path: '/tools/date-converter',
        builder: (context, state) => const DateConverterScreen(),
      ),
      GoRoute(
        path: '/tools/gov-services',
        builder: (context, state) => GovServicesScreen(
          initialCategory: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(
        path: '/tools/nepali-calendar',
        builder: (context, state) => const NepaliCalendarScreen(),
      ),
      GoRoute(
        path: '/tools/forex',
        builder: (context, state) => const ForexScreen(),
      ),
      GoRoute(
        path: '/tools/bullion',
        builder: (context, state) => const BullionScreen(),
      ),
      GoRoute(
        path: '/tools/ipo',
        builder: (context, state) => const IpoSharesScreen(),
      ),
    ],
  );
}
