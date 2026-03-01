import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'screens/home/responsive_home.dart';
import 'screens/constitution/constitution_screen.dart';
import 'screens/leaders/leaders_screen.dart';
import 'screens/leaders/leader_detail_screen.dart';
import 'screens/map/map_selector_screen.dart';
import 'screens/map/geo_district_map_screen.dart';
import 'screens/map/geo_local_body_screen.dart';
import 'screens/map/geo_federal_map_screen.dart';
import 'screens/map/constituency_screen.dart';
import 'screens/map/nepal_map_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tools/photo_merger_screen.dart';
import 'screens/tools/image_compressor_screen.dart';
import 'screens/tools/pdf_compressor_screen.dart';
import 'screens/tools/unicode_converter_screen.dart';
import 'screens/tools/date_converter_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/tools/forex_screen.dart';
import 'screens/tools/bullion_screen.dart';
import 'screens/tools/ipo_shares_screen.dart';
import 'screens/tools/gov_services_screen.dart';
import 'screens/government/how_nepal_works_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/emergency/earthquakes_screen.dart';
import 'screens/emergency/contacts_screen.dart';
import 'screens/emergency/resources_screen.dart';
import 'screens/news/ronb_feed_screen.dart';
import 'widgets/desktop_nav_shell.dart';

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
      // ShellRoute wraps all main routes with persistent WebNavBar on desktop.
      // On mobile (< 600px), the shell passes through the child directly.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DesktopNavShell(child: child),
        routes: [
          // Home — responsive: desktop gets calendar-first, mobile gets card-based
          GoRoute(
            path: '/home',
            builder: (context, state) => const ResponsiveHome(),
          ),
          // Calendar, IPO, Rights
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/ipo',
            builder: (context, state) => const IpoSharesScreen(),
          ),
          GoRoute(
            path: '/rights',
            builder: (context, state) => const ConstitutionScreen(),
          ),
          // Constitution
          GoRoute(
            path: '/constitution',
            builder: (context, state) => const ConstitutionScreen(),
          ),
          GoRoute(
            path: '/constitutional-rights',
            builder: (context, state) => const ConstitutionScreen(),
          ),
          // Leaders
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
          // Maps
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapSelectorScreen(),
            routes: [
              GoRoute(
                path: 'districts',
                builder: (context, state) => const GeoDistrictMapScreen(),
                routes: [
                  GoRoute(
                    path: ':district',
                    builder: (context, state) {
                      final district = state.pathParameters['district'] ?? '';
                      return GeoLocalBodyScreen(districtName: Uri.decodeComponent(district));
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'federal',
                builder: (context, state) => const GeoFederalMapScreen(),
              ),
              GoRoute(
                path: 'nepal',
                builder: (context, state) => const NepalMapScreen(),
              ),
              GoRoute(
                path: 'constituencies/:district',
                builder: (context, state) {
                  final district = state.pathParameters['district'] ?? '';
                  return ConstituencyScreen(districtName: Uri.decodeComponent(district));
                },
              ),
            ],
          ),
          // Government
          GoRoute(
            path: '/how-nepal-works',
            builder: (context, state) => const HowNepalWorksScreen(),
          ),
          GoRoute(
            path: '/government',
            builder: (context, state) => const HowNepalWorksScreen(),
          ),
          GoRoute(
            path: '/gov',
            builder: (context, state) => const HowNepalWorksScreen(),
          ),
          // Emergency / Alerts
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const EmergencyScreen(),
            routes: [
              GoRoute(
                path: 'earthquakes',
                builder: (context, state) => const EarthquakesScreen(),
              ),
              GoRoute(
                path: 'contacts',
                builder: (context, state) => const EmergencyContactsScreen(),
              ),
              GoRoute(
                path: 'resources',
                builder: (context, state) => const EmergencyResourcesScreen(),
              ),
            ],
          ),
          // News
          GoRoute(
            path: '/news',
            builder: (context, state) => const RonbFeedScreen(),
          ),
          // Settings
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          // Tools — short paths
          GoRoute(
            path: '/photo-merger',
            builder: (context, state) => const PhotoMergerScreen(),
          ),
          GoRoute(
            path: '/photo-compress',
            builder: (context, state) => const ImageCompressorScreen(),
          ),
          GoRoute(
            path: '/pdf-compress',
            builder: (context, state) => const PdfCompressorScreen(),
          ),
          GoRoute(
            path: '/unicode',
            builder: (context, state) => const UnicodeConverterScreen(),
          ),
          GoRoute(
            path: '/date-converter',
            builder: (context, state) => const DateConverterScreen(),
          ),
          GoRoute(
            path: '/forex',
            builder: (context, state) => const ForexScreen(),
          ),
          GoRoute(
            path: '/gold-price',
            builder: (context, state) => const BullionScreen(),
          ),
          // Tools — /tools/ prefixed paths
          GoRoute(
            path: '/tools/photo-merger',
            builder: (context, state) => const PhotoMergerScreen(),
          ),
          GoRoute(
            path: '/tools/image-compressor',
            builder: (context, state) => const ImageCompressorScreen(),
          ),
          GoRoute(
            path: '/tools/pdf-compressor',
            builder: (context, state) => const PdfCompressorScreen(),
          ),
          GoRoute(
            path: '/tools/unicode-converter',
            builder: (context, state) => const UnicodeConverterScreen(),
          ),
          GoRoute(
            path: '/tools/date-converter',
            builder: (context, state) => const DateConverterScreen(),
          ),
          GoRoute(
            path: '/tools/nepali-calendar',
            builder: (context, state) => const CalendarScreen(),
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
          GoRoute(
            path: '/tools/gov-services',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return GovServicesScreen(initialCategory: category);
            },
          ),
          // Legacy redirects
          GoRoute(
            path: '/gov-services',
            redirect: (context, state) => '/government',
          ),
          GoRoute(
            path: '/how-to-get',
            redirect: (context, state) => '/government',
          ),
          GoRoute(
            path: '/nepali-calendar',
            redirect: (context, state) => '/calendar',
          ),
        ],
      ),
    ],
  );
}
