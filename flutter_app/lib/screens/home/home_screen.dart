import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../l10n/app_localizations.dart';
import '../../services/nepali_date_service.dart';
import '../../widgets/home_title.dart';
import '../tools/nepali_calendar_screen.dart';
import '../tools/ipo_shares_screen.dart';
import '../constitution/constitution_screen.dart';

part 'home_screen.g.dart';

/// Home screen with 4-tab bottom navigation: Calendar | Home | IPO | Rights
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabHistory = ref.watch(_tabHistoryProvider);
    final currentIndex = tabHistory.last;

    return HomeTabSwitcher(
      onSwitchToHome: () => ref.read(_tabHistoryProvider.notifier).goHome(),
      child: PopScope(
        // Only allow pop (exit) when tab history has only one item
        canPop: tabHistory.length <= 1,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            // Go back to previous tab
            ref.read(_tabHistoryProvider.notifier).popTab();
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: const [
              NepaliCalendarScreen(),
              _HomeTab(),
              IpoSharesScreen(),
              ConstitutionScreen(),
            ],
          ),
          bottomNavigationBar: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(_tabHistoryProvider.notifier).pushTab(index);
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
            );
          },
        ),
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appName),
            const Text(
              'नेपाल नागरिक',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: l10n.settings,
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
              _SectionHeader(title: l10n.explore, titleNp: 'अन्वेषण'),
              const SizedBox(height: 12),
              _QuickAccessGrid(l10n: l10n),
              const SizedBox(height: 24),

              // Utilities section
              _SectionHeader(title: l10n.utilities, titleNp: 'उपकरणहरू'),
              const SizedBox(height: 12),
              // First row
              Row(
                children: [
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.badge,
                      title: l10n.citizenshipMerger,
                      titleNp: 'नागरिकता मर्जर',
                      color: const Color(0xFF7B1FA2),
                      onTap: () => context.push('/tools/citizenship-merger'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.compress,
                      title: l10n.imageCompressor,
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
                      title: l10n.calendar,
                      titleNp: 'पात्रो',
                      color: const Color(0xFFC62828),
                      onTap: () => context.push('/tools/nepali-calendar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.swap_horiz,
                      title: l10n.dateConvert,
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
                      title: l10n.forex,
                      titleNp: 'विदेशी मुद्रा',
                      color: const Color(0xFF2E7D32),
                      onTap: () => context.push('/tools/forex'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UtilityGridCard(
                      icon: Icons.diamond,
                      title: l10n.goldSilver,
                      titleNp: 'सुन/चाँदी',
                      color: const Color(0xFFFFB300),
                      onTap: () => context.push('/tools/bullion'),
                    ),
                  ),
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

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Row(
      children: [
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.account_balance,
            title: l10n.govt,
            titleNp: 'सरकार',
            color: secondaryColor,
            onTap: () => context.push('/government'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.map,
            title: l10n.map,
            titleNp: 'नक्सा',
            color: const Color(0xFF2E7D32),
            onTap: () => context.push('/map'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.gavel,
            title: l10n.rights,
            titleNp: 'अधिकार',
            color: const Color(0xFF6A1B9A),
            onTap: () => context.push('/constitution'),
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
class _TabHistory extends _$TabHistory {
  @override
  List<int> build() => [1]; // Start with Home tab

  int get currentIndex => state.last;

  void pushTab(int index) {
    if (state.last != index) {
      state = [...state, index];
    }
  }

  /// Go back to previous tab. Returns true if there was a previous tab.
  bool popTab() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1);
      return true;
    }
    return false;
  }

  /// Go directly to home tab, clearing history
  void goHome() {
    state = [1];
  }
}
