import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/nepali_date_service.dart';
import '../constitution/constitution_screen.dart';
import '../government/how_nepal_works_screen.dart';
import '../map/district_map_screen.dart' show DistrictMapScreen, selectedDistrictProvider;
import '../../providers/constitution_provider.dart' show selectedArticleProvider;

part 'home_screen.g.dart';

/// Home screen with 4-tab bottom navigation: Home | Rights | Government | Map
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_currentTabProvider);
    // Watch map's selected district to handle back gesture correctly
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    // Watch constitution's selected article for Rights tab
    final selectedArticle = ref.watch(selectedArticleProvider);
    // Check if on map tab with panel open
    final mapPanelOpen = currentIndex == 3 && selectedDistrict != null;
    // Check if on Rights tab with article selected (not on Know Your Rights)
    final articleSelected = currentIndex == 1 && selectedArticle != null;

    return PopScope(
      // Only allow pop (exit) when on Home tab
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (articleSelected) {
            // Return to Know Your Rights page
            ref.read(selectedArticleProvider.notifier).clear();
          } else if (mapPanelOpen) {
            // Close map panel first
            ref.read(selectedDistrictProvider.notifier).clear();
          } else if (currentIndex != 0) {
            // Go back to Home tab instead of exiting
            ref.read(_currentTabProvider.notifier).setIndex(0);
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: const [
            _HomeTab(),
            ConstitutionTab(),
            HowNepalWorksScreen(),
            MapTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(_currentTabProvider.notifier).setIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.gavel_outlined),
              selectedIcon: Icon(Icons.gavel),
              label: 'Rights',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance),
              label: 'Govt',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map',
            ),
          ],
        ),
      ),
    );
  }
}

/// Home tab content with feature cards and utilities
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nepal Civic'),
            Text(
              'नेपाल नागरिक',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's date widget
              _TodayDateWidget(
                todayBs: _todayBs,
                todayAd: _todayAd,
                onTap: () => context.push('/tools/nepali-calendar'),
              ),
              const SizedBox(height: 20),

              // Quick access grid
              const _SectionHeader(title: 'Explore', titleNp: 'अन्वेषण'),
              const SizedBox(height: 12),
              const _QuickAccessGrid(),
              const SizedBox(height: 24),

              // Utilities section
              const _SectionHeader(title: 'Utilities', titleNp: 'उपकरणहरू'),
              const SizedBox(height: 12),
              // First row
              Row(
                children: [
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.badge,
                      title: 'Citizenship Merger',
                      titleNp: 'नागरिकता मर्जर',
                      color: const Color(0xFF7B1FA2),
                      onTap: () => context.push('/tools/citizenship-merger'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.compress,
                      title: 'Image < 300KB',
                      titleNp: 'फोटो कम्प्रेस',
                      color: const Color(0xFF1976D2),
                      onTap: () => context.push('/tools/image-compressor'),
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
                      title: 'Calendar',
                      titleNp: 'पात्रो',
                      color: const Color(0xFFC62828),
                      onTap: () => context.push('/tools/nepali-calendar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.swap_horiz,
                      title: 'Date Convert',
                      titleNp: 'मिति परिवर्तक',
                      color: const Color(0xFFE65100),
                      onTap: () => context.push('/tools/date-converter'),
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
                      title: 'Forex',
                      titleNp: 'विदेशी मुद्रा',
                      color: const Color(0xFF2E7D32),
                      onTap: () => context.push('/tools/forex'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.diamond,
                      title: 'Gold/Silver',
                      titleNp: 'सुन/चाँदी',
                      color: const Color(0xFFFFB300),
                      onTap: () => context.push('/tools/bullion'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fourth row - Gov Services
              Row(
                children: [
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.account_balance,
                      title: 'Gov Services',
                      titleNp: 'सरकारी सेवा',
                      color: const Color(0xFF00695C),
                      onTap: () => context.push('/tools/gov-services'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()), // Empty slot
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
              // Arrow
              Icon(
                Icons.swap_horiz,
                color: Colors.white.withValues(alpha: 0.7),
                size: 28,
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
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

class _QuickAccessGrid extends ConsumerWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Row(
      children: [
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.gavel,
            title: 'Rights',
            titleNp: 'संविधान',
            color: primaryColor,
            onTap: () => ref.read(_currentTabProvider.notifier).setIndex(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.account_balance,
            title: 'Govt',
            titleNp: 'सरकार',
            color: secondaryColor,
            onTap: () => ref.read(_currentTabProvider.notifier).setIndex(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.map,
            title: 'Map',
            titleNp: 'नक्सा',
            color: const Color(0xFF2E7D32), // Green for geography
            onTap: () => ref.read(_currentTabProvider.notifier).setIndex(3),
          ),
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
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.titleNp,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UtilityGridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String titleNp;
  final Color color;
  final VoidCallback onTap;

  const _UtilityGridCard({
    required this.icon,
    required this.title,
    required this.titleNp,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@riverpod
class _CurrentTab extends _$CurrentTab {
  @override
  int build() => 0; // Start with Home tab

  void setIndex(int index) {
    state = index;
  }
}

// Tab widgets
class ConstitutionTab extends StatelessWidget {
  const ConstitutionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConstitutionScreen();
  }
}

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DistrictMapScreen();
  }
}
