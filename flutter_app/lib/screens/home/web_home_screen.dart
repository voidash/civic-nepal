import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../services/data_service.dart';
import '../../services/nepali_date_service.dart';
import '../tools/nepali_calendar_screen.dart';

/// Primary brand color - blue
const _brandColor = Color(0xFF1976D2);
const _todayHighlight = Color(0xFF1565C0);

/// Web-specific home screen with calendar-first layout
/// Inspired by nepalipatro.com.np design
class WebHomeScreen extends ConsumerStatefulWidget {
  const WebHomeScreen({super.key});

  @override
  ConsumerState<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends ConsumerState<WebHomeScreen> {
  late int _currentYear;
  late int _currentMonth;
  late NepaliDateTime _today;
  int? _selectedDay;

  Map<String, dynamic>? _eventsData;
  Map<String, dynamic>? _auspiciousData;
  bool _isLoading = true;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _today = NepaliDateService.today();
    _currentYear = _today.year;
    _currentMonth = _today.month;
    _loadData();
    _scheduleMidnightUpdate();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);

    _midnightTimer = Timer(duration, () {
      setState(() {
        _today = NepaliDateService.today();
      });
      _scheduleMidnightUpdate();
    });
  }

  Future<void> _loadData() async {
    try {
      final events = await DataService.loadCalendarEvents();
      final auspicious = await DataService.loadAuspiciousDays();
      if (mounted) {
        setState(() {
          _eventsData = events;
          _auspiciousData = auspicious;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMonthKey(int year, int month) => '$year-${month.toString().padLeft(2, '0')}';

  Map<int, CalendarDayInfo> _getEventsForMonth() {
    if (_eventsData == null) return {};
    final key = _getMonthKey(_currentYear, _currentMonth);
    final monthData = _eventsData![key] as Map<String, dynamic>?;
    if (monthData == null) return {};

    final days = monthData['days'] as List<dynamic>?;
    if (days == null) return {};

    final result = <int, CalendarDayInfo>{};
    for (final dayJson in days) {
      final info = CalendarDayInfo.fromJson(dayJson as Map<String, dynamic>);
      result[info.day] = info;
    }
    return result;
  }

  AuspiciousDaysInfo? _getAuspiciousForMonth() {
    if (_auspiciousData == null) return null;
    final key = _getMonthKey(_currentYear, _currentMonth);
    final monthData = _auspiciousData![key] as Map<String, dynamic>?;
    if (monthData == null) return null;
    return AuspiciousDaysInfo.fromJson(monthData);
  }

  void _previousMonth() {
    setState(() {
      _selectedDay = null;
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDay = null;
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _today = NepaliDateService.today();
      _currentYear = _today.year;
      _currentMonth = _today.month;
      _selectedDay = null;
    });
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDay = _selectedDay == day ? null : day;
    });
  }

  void _navigateTo(String route) {
    ref.read(settingsProvider.notifier).recordVisit(route);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, l10n),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final daysInMonth = NepaliDateService.getDaysInMonth(_currentYear, _currentMonth);
    final firstDayOfMonth = NepaliDateService.fromBsDate(_currentYear, _currentMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final eventsForMonth = _getEventsForMonth();
    final auspiciousForMonth = _getAuspiciousForMonth();
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth >= 900;

    return Column(
      children: [
        // App download banner (web only — doesn't make sense in desktop app)
        if (kIsWeb) _buildAppBanner(context),

        // Main content
        Expanded(
          child: showSidebar
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Sidebar - Today's date + Upcoming events
              SizedBox(
                width: 240,
                child: _buildLeftSidebar(l10n, eventsForMonth, auspiciousForMonth),
              ),

              // Main Calendar Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: _buildCalendarSection(
                    l10n,
                    daysInMonth,
                    firstWeekday,
                    eventsForMonth,
                    auspiciousForMonth,
                  ),
                ),
              ),

              // Right Sidebar - Utilities
              SizedBox(
                width: 200,
                child: _buildRightSidebar(l10n),
              ),
            ],
          )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Compact today widget for narrow screens
                      _buildCompactTodayWidget(l10n),
                      _buildCalendarSection(
                        l10n,
                        daysInMonth,
                        firstWeekday,
                        eventsForMonth,
                        auspiciousForMonth,
                        isNarrow: true,
                      ),
                      _buildMonthEventsSection(l10n, eventsForMonth, auspiciousForMonth),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAppBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _brandColor.withValues(alpha: 0.95),
            _todayHighlight.withValues(alpha: 0.95),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.phone_android,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Get the app for home screen widgets, daily notifications & offline access',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Open Play Store link
              _launchPlayStore();
            },
            icon: const Icon(Icons.shop, size: 16),
            label: const Text('Play Store'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPlayStore() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=xyz.nagarikpatro.app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCalendarSection(
    AppLocalizations l10n,
    int daysInMonth,
    int firstWeekday,
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth, {
    bool isNarrow = false,
  }) {
    return Column(
      mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _buildMonthHeader(l10n),
        const Divider(height: 1),
        _buildLegend(l10n),
        const Divider(height: 1),
        _buildWeekdayHeaders(),
        const Divider(height: 1),
        if (isNarrow)
          _buildCalendarGridCompact(
            daysInMonth,
            firstWeekday,
            eventsForMonth,
            auspiciousForMonth,
            l10n,
          )
        else
          Expanded(
            child: _buildCalendarGrid(
              daysInMonth,
              firstWeekday,
              eventsForMonth,
              auspiciousForMonth,
              l10n,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactTodayWidget(AppLocalizations l10n) {
    final adDate = NepaliDateService.bsToAd(_today);
    final dayNameNp = NepaliDateService.getWeekdayNp(_today);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_brandColor, _todayHighlight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _toNepaliNumeral(_today.day),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayNameNp, ${NepaliDateService.formatNp(_today)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${adDate.day} ${_getEnglishMonthName(adDate.month)} ${adDate.year}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(
    AppLocalizations l10n,
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth,
  ) {
    final adDate = NepaliDateService.bsToAd(_today);
    final dayNameNp = NepaliDateService.getWeekdayNp(_today);
    final dayNameEn = NepaliDateService.getWeekdayEn(_today);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Date Box - Blue theme
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_brandColor, _todayHighlight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _toNepaliNumeral(_today.day),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayNameNp,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NepaliDateService.formatNp(_today),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${adDate.day} ${_getEnglishMonthName(adDate.month)} ${adDate.year} ($dayNameEn)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming Events Section
            Text(
              '${l10n.monthEvents} - ${NepaliMonth.namesNp[_currentMonth - 1]}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildUpcomingEvents(l10n, eventsForMonth, auspiciousForMonth),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebar(AppLocalizations l10n) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.utilities,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            _buildUtilityItem(
              icon: Icons.currency_exchange,
              label: l10n.forex,
              sublabel: l10n.forexNp,
              color: const Color(0xFF2E7D32),
              route: '/forex',
            ),
            _buildUtilityItem(
              icon: Icons.diamond,
              label: l10n.goldSilver,
              sublabel: l10n.goldSilverNp,
              color: const Color(0xFFFFB300),
              route: '/gold-price',
            ),
            _buildUtilityItem(
              icon: Icons.trending_up,
              label: l10n.ipoShares,
              sublabel: 'IPO शेयर',
              color: const Color(0xFFD32F2F),
              route: '/ipo',
            ),
            const Divider(height: 20),
            _buildUtilityItem(
              icon: Icons.swap_horiz,
              label: l10n.dateConvert,
              sublabel: l10n.dateConvertNp,
              color: const Color(0xFFE65100),
              route: '/date-converter',
            ),
            _buildUtilityItem(
              icon: Icons.translate,
              label: l10n.unicodeConverter,
              sublabel: 'युनिकोड',
              color: const Color(0xFF5E35B1),
              route: '/unicode',
            ),
            const Divider(height: 20),
            _buildUtilityItem(
              icon: Icons.photo_library,
              label: l10n.photoMerger,
              sublabel: 'फोटो मर्जर',
              color: const Color(0xFF00897B),
              route: '/photo-merger',
            ),
            _buildUtilityItem(
              icon: Icons.compress,
              label: l10n.imageCompressor,
              sublabel: 'इमेज कम्प्रेस',
              color: const Color(0xFF1976D2),
              route: '/photo-compress',
            ),
            _buildUtilityItem(
              icon: Icons.picture_as_pdf,
              label: l10n.pdfCompressor,
              sublabel: 'PDF कम्प्रेस',
              color: const Color(0xFFC62828),
              route: '/pdf-compress',
            ),
            const Divider(height: 20),
            _buildUtilityItem(
              icon: Icons.notifications_active,
              label: l10n.alerts,
              sublabel: l10n.alertsNp,
              color: Colors.red.shade700,
              route: '/alerts',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityItem({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _navigateTo(route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(
    AppLocalizations l10n,
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth,
  ) {
    final allItems = <({int day, String text, bool isHoliday, bool isAuspicious})>[];

    eventsForMonth.forEach((day, info) {
      final localizedEvents = info.getLocalizedEvents(l10n.isNepali);
      for (final event in localizedEvents) {
        allItems.add((day: day, text: event, isHoliday: info.isHoliday, isAuspicious: false));
      }
    });

    if (auspiciousForMonth != null) {
      final daysInMonth = NepaliDateService.getDaysInMonth(_currentYear, _currentMonth);
      for (int day = 1; day <= daysInMonth; day++) {
        final types = auspiciousForMonth.getAuspiciousTypes(day, l10n);
        for (final type in types) {
          allItems.add((day: day, text: type, isHoliday: false, isAuspicious: true));
        }
      }
    }

    allItems.sort((a, b) => a.day.compareTo(b.day));

    if (allItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            l10n.noEvents,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: allItems.take(10).map((item) {
        return InkWell(
          onTap: () => _selectDay(item.day),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.isHoliday
                        ? Colors.red.withValues(alpha: 0.1)
                        : item.isAuspicious
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      _toNepaliNumeral(item.day),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: item.isHoliday
                            ? Colors.red
                            : item.isAuspicious
                                ? Colors.green
                                : Colors.orange[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: item.isHoliday ? Colors.red : null,
                      fontWeight: item.isHoliday ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthEventsSection(
    AppLocalizations l10n,
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth,
  ) {
    final allItems = <({int day, String text, bool isHoliday, bool isAuspicious})>[];

    eventsForMonth.forEach((day, info) {
      final localizedEvents = info.getLocalizedEvents(l10n.isNepali);
      for (final event in localizedEvents) {
        allItems.add((day: day, text: event, isHoliday: info.isHoliday, isAuspicious: false));
      }
    });

    if (auspiciousForMonth != null) {
      final daysInMonth = NepaliDateService.getDaysInMonth(_currentYear, _currentMonth);
      for (int day = 1; day <= daysInMonth; day++) {
        final types = auspiciousForMonth.getAuspiciousTypes(day, l10n);
        for (final type in types) {
          allItems.add((day: day, text: type, isHoliday: false, isAuspicious: true));
        }
      }
    }

    allItems.sort((a, b) => a.day.compareTo(b.day));

    if (allItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${NepaliMonth.namesNp[_currentMonth - 1]} - ${l10n.monthEvents}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...allItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: item.isHoliday
                            ? Colors.red.withValues(alpha: 0.1)
                            : item.isAuspicious
                                ? Colors.green.withValues(alpha: 0.1)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          item.day.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: item.isHoliday
                                ? Colors.red
                                : item.isAuspicious
                                    ? Colors.green
                                    : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: item.isHoliday ? Colors.red : null,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(AppLocalizations l10n) {
    final monthNameNp = NepaliMonth.namesNp[_currentMonth - 1];
    final monthNameEn = NepaliMonth.names[_currentMonth - 1];
    final englishMonthRange = _getEnglishMonthRange();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: l10n.previousMonth,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$monthNameNp $_currentYear',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '$monthNameEn ($englishMonthRange)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today, size: 16),
            label: Text(l10n.today),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: l10n.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.red, l10n.holiday),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.orange, l10n.event),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.green, l10n.auspicious),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdaysNp = ['आइत', 'सोम', 'मंगल', 'बुध', 'बिही', 'शुक्र', 'शनि'];
    const weekdaysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          final isSaturday = index == 6;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekdaysNp[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSaturday ? Colors.red : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  weekdaysEn[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: isSaturday
                        ? Colors.red[300]
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarGridCompact(
    int daysInMonth,
    int firstWeekday,
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth,
    AppLocalizations l10n,
  ) {
    final startOffset = firstWeekday - 1;
    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        const cellHeight = 56.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (rowIndex) {
            return Row(
              children: List.generate(7, (colIndex) {
                final index = rowIndex * 7 + colIndex;
                final dayNumber = index - startOffset + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return SizedBox(
                    width: cellWidth,
                    height: cellHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                }

                final isToday = _currentYear == _today.year &&
                    _currentMonth == _today.month &&
                    dayNumber == _today.day;
                final isSaturday = colIndex == 6;
                final isSelected = _selectedDay == dayNumber;

                final bsDate = NepaliDateService.fromBsDate(_currentYear, _currentMonth, dayNumber);
                final adDate = NepaliDateService.bsToAd(bsDate);

                final dayInfo = eventsForMonth[dayNumber];
                final localizedEvents = dayInfo?.getLocalizedEvents(l10n.isNepali) ?? [];
                final hasEvents = localizedEvents.isNotEmpty;
                final isHoliday = dayInfo?.isHoliday ?? false;
                final isAuspicious = auspiciousForMonth?.hasAuspiciousDay(dayNumber) ?? false;

                return SizedBox(
                  width: cellWidth,
                  height: cellHeight,
                  child: _buildDayCellCompact(
                    dayNumber,
                    adDate.day,
                    isToday,
                    isSaturday,
                    isSelected,
                    hasEvents,
                    isHoliday,
                    isAuspicious,
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }

  Widget _buildDayCellCompact(
    int bsDay,
    int adDay,
    bool isToday,
    bool isSaturday,
    bool isSelected,
    bool hasEvents,
    bool isHoliday,
    bool isAuspicious,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color bsDayColor;
    Color adDayColor;

    if (isToday) {
      bgColor = _brandColor;
      bsDayColor = Colors.white;
      adDayColor = Colors.white.withValues(alpha: 0.7);
    } else if (isSelected) {
      bgColor = Theme.of(context).colorScheme.primaryContainer;
      bsDayColor = Theme.of(context).colorScheme.onPrimaryContainer;
      adDayColor = Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.6);
    } else if (isSaturday || isHoliday) {
      bgColor = isDark ? Colors.red.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.03);
      bsDayColor = Colors.red[isDark ? 300 : 700]!;
      adDayColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    } else {
      bgColor = Colors.transparent;
      bsDayColor = Theme.of(context).colorScheme.onSurface;
      adDayColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: () => _selectDay(bsDay),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isToday
                ? _brandColor
                : isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isToday ? 2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _toNepaliNumeral(bsDay),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: bsDayColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adDay.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: adDayColor,
                  ),
                ),
                if (hasEvents || isAuspicious) ...[
                  const SizedBox(width: 4),
                  if (isHoliday)
                    _buildEventDot(isToday ? Colors.white : Colors.red)
                  else if (hasEvents)
                    _buildEventDot(isToday ? Colors.white : Colors.orange),
                  if (isAuspicious) ...[
                    const SizedBox(width: 2),
                    _buildEventDot(isToday ? Colors.white : Colors.green),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(
    int daysInMonth,
    int firstWeekday,
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth,
    AppLocalizations l10n,
  ) {
    final startOffset = firstWeekday - 1;
    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final cellHeight = (constraints.maxHeight / rows).clamp(60.0, 100.0);

        return SingleChildScrollView(
          child: Column(
            children: List.generate(rows, (rowIndex) {
              return Row(
                children: List.generate(7, (colIndex) {
                  final index = rowIndex * 7 + colIndex;
                  final dayNumber = index - startOffset + 1;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return SizedBox(
                      width: cellWidth,
                      height: cellHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                    );
                  }

                  final isToday = _currentYear == _today.year &&
                      _currentMonth == _today.month &&
                      dayNumber == _today.day;
                  final isSaturday = colIndex == 6;
                  final isSelected = _selectedDay == dayNumber;

                  final bsDate = NepaliDateService.fromBsDate(_currentYear, _currentMonth, dayNumber);
                  final adDate = NepaliDateService.bsToAd(bsDate);

                  final dayInfo = eventsForMonth[dayNumber];
                  final localizedEvents = dayInfo?.getLocalizedEvents(l10n.isNepali) ?? [];
                  final hasEvents = localizedEvents.isNotEmpty;
                  final isHoliday = dayInfo?.isHoliday ?? false;
                  final isAuspicious = auspiciousForMonth?.hasAuspiciousDay(dayNumber) ?? false;

                  String? eventText;
                  if (localizedEvents.isNotEmpty) {
                    eventText = localizedEvents.first;
                  }

                  return SizedBox(
                    width: cellWidth,
                    height: cellHeight,
                    child: _buildDayCell(
                      dayNumber,
                      adDate.day,
                      isToday,
                      isSaturday,
                      isSelected,
                      hasEvents,
                      isHoliday,
                      isAuspicious,
                      eventText: eventText,
                    ),
                  );
                }),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildDayCell(
    int bsDay,
    int adDay,
    bool isToday,
    bool isSaturday,
    bool isSelected,
    bool hasEvents,
    bool isHoliday,
    bool isAuspicious, {
    String? eventText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color bsDayColor;
    Color adDayColor;
    Color eventTextColor;

    if (isToday) {
      bgColor = _brandColor;
      bsDayColor = Colors.white;
      adDayColor = Colors.white.withValues(alpha: 0.7);
      eventTextColor = Colors.white.withValues(alpha: 0.9);
    } else if (isSelected) {
      bgColor = Theme.of(context).colorScheme.primaryContainer;
      bsDayColor = Theme.of(context).colorScheme.onPrimaryContainer;
      adDayColor = Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.6);
      eventTextColor = Theme.of(context).colorScheme.onPrimaryContainer;
    } else if (isSaturday) {
      bgColor = isDark ? Colors.red.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.03);
      bsDayColor = Colors.red[isDark ? 300 : 700]!;
      adDayColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
      eventTextColor = Colors.red[isDark ? 300 : 600]!;
    } else {
      bgColor = Colors.transparent;
      bsDayColor = Theme.of(context).colorScheme.onSurface;
      adDayColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
      eventTextColor = isHoliday ? Colors.red[isDark ? 300 : 600]! : Colors.grey[600]!;
    }

    if (isHoliday && !isToday && !isSelected) {
      bsDayColor = Colors.red[isDark ? 300 : 700]!;
      eventTextColor = Colors.red[isDark ? 300 : 600]!;
    }

    return GestureDetector(
      onTap: () => _selectDay(bsDay),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isToday
                ? _brandColor
                : isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Event text at top - with overflow protection
              if (eventText != null && eventText.isNotEmpty)
                Flexible(
                  flex: 0,
                  child: Text(
                    eventText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: eventTextColor,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const Spacer(),

              // Nepali numeral in center
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _toNepaliNumeral(bsDay),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: bsDayColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Bottom row: indicators and AD date
              Row(
                children: [
                  if (hasEvents || isAuspicious)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isHoliday)
                          _buildEventDot(isToday ? Colors.white : Colors.red)
                        else if (hasEvents)
                          _buildEventDot(isToday ? Colors.white : Colors.orange),
                        if (isAuspicious) ...[
                          if (hasEvents) const SizedBox(width: 2),
                          _buildEventDot(isToday ? Colors.white : Colors.green),
                        ],
                      ],
                    ),
                  const Spacer(),
                  Text(
                    adDay.toString(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: adDayColor,
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

  Widget _buildEventDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildQuickAccessCards(AppLocalizations l10n) {
    final cards = [
      _QuickCard(
        icon: Icons.map,
        title: l10n.map,
        titleNp: l10n.mapNp,
        color: const Color(0xFF2E7D32),
        route: '/map',
      ),
      _QuickCard(
        icon: Icons.gavel,
        title: l10n.constitution,
        titleNp: l10n.rightsNp,
        color: const Color(0xFF6A1B9A),
        route: '/constitutional-rights',
      ),
      _QuickCard(
        icon: Icons.people,
        title: l10n.leaders,
        titleNp: l10n.leadersNp,
        color: const Color(0xFF0277BD),
        route: '/leaders',
      ),
      _QuickCard(
        icon: Icons.currency_exchange,
        title: l10n.forex,
        titleNp: l10n.forexNp,
        color: const Color(0xFF2E7D32),
        route: '/forex',
      ),
      _QuickCard(
        icon: Icons.diamond,
        title: l10n.goldSilver,
        titleNp: l10n.goldSilverNp,
        color: const Color(0xFFFFB300),
        route: '/gold-price',
      ),
      const _QuickCard(
        icon: Icons.trending_up,
        title: 'IPO',
        titleNp: 'IPO शेयर',
        color: Color(0xFFD32F2F),
        route: '/ipo',
      ),
      _QuickCard(
        icon: Icons.swap_horiz,
        title: l10n.dateConvert,
        titleNp: l10n.dateConvertNp,
        color: const Color(0xFFE65100),
        route: '/date-converter',
      ),
      _QuickCard(
        icon: Icons.notifications_active,
        title: l10n.alerts,
        titleNp: l10n.alertsNp,
        color: Colors.red.shade700,
        route: '/alerts',
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: cards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => _navigateTo(card.route),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(card.icon, size: 18, color: card.color),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          card.titleNp,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
  }

  String _getEnglishMonthRange() {
    final daysInMonth = NepaliDateService.getDaysInMonth(_currentYear, _currentMonth);
    final firstDayBs = NepaliDateService.fromBsDate(_currentYear, _currentMonth, 1);
    final lastDayBs = NepaliDateService.fromBsDate(_currentYear, _currentMonth, daysInMonth);

    final firstDayAd = NepaliDateService.bsToAd(firstDayBs);
    final lastDayAd = NepaliDateService.bsToAd(lastDayBs);

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final startMonth = months[firstDayAd.month - 1];
    final endMonth = months[lastDayAd.month - 1];

    if (firstDayAd.month == lastDayAd.month && firstDayAd.year == lastDayAd.year) {
      return '$startMonth ${firstDayAd.year}';
    } else if (firstDayAd.year == lastDayAd.year) {
      return '$startMonth - $endMonth ${firstDayAd.year}';
    } else {
      return '$startMonth ${firstDayAd.year} - $endMonth ${lastDayAd.year}';
    }
  }

  String _getEnglishMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}

class _QuickCard {
  final IconData icon;
  final String title;
  final String titleNp;
  final Color color;
  final String route;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.titleNp,
    required this.color,
    required this.route,
  });
}
