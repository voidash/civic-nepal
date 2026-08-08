import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';
import '../../models/calendar_view_state.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/calendar_view_provider.dart';
import '../../services/nepali_date_service.dart';
import '../../services/calendar_event_merger.dart';

/// Month view — 7-column grid with event indicators.
class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedDateNotifierProvider);
    final dateSystem = ref.watch(dateSystemNotifierProvider);
    final selectedDay = ref.watch(selectedDayNotifierProvider);
    final merger = ref.read(calendarEventMergerProvider);
    // Watch the Nepali data load so the grid repaints once the JSON is parsed.
    // Without this the first frame renders an empty month and never recovers.
    ref.watch(calendarDataLoaderProvider);
    // Watch Google sync so event dots update
    ref.watch(googleCalendarSyncProvider);

    if (dateSystem == DateSystem.bs) {
      return _BsMonthGrid(
        focusedAd: focused,
        selectedDay: selectedDay,
        merger: merger,
      );
    } else {
      return _AdMonthGrid(
        focusedAd: focused,
        selectedDay: selectedDay,
        merger: merger,
      );
    }
  }
}

/// BS month grid — shows a single BS month.
class _BsMonthGrid extends ConsumerWidget {
  final DateTime focusedAd;
  final DateTime? selectedDay;
  final CalendarEventMerger merger;

  const _BsMonthGrid({
    required this.focusedAd,
    required this.selectedDay,
    required this.merger,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bs = NepaliDateService.adToBs(focusedAd);
    final daysInMonth = NepaliDateService.getDaysInMonth(bs.year, bs.month);
    final firstDayBs = NepaliDateService.fromBsDate(bs.year, bs.month, 1);
    final firstWeekday = firstDayBs.weekday; // 1=Sun in nepali_utils
    final startOffset = firstWeekday - 1;

    final today = NepaliDateService.today();
    final dayInfoMap = merger.nepaliDayInfoForMonth(bs.year, bs.month);
    final auspicious = merger.auspiciousDataForMonth(bs.year, bs.month);

    final rows = ((startOffset + daysInMonth) / 7).ceil();
    final theme = Theme.of(context);
    final isNepaliUi = AppLocalizations.of(context).isNepali;

    return Column(
      children: [
        _WeekdayHeader(),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: List.generate(rows, (rowIndex) {
                  return Expanded(
                    child: Row(
                      children: List.generate(7, (colIndex) {
                        final index = rowIndex * 7 + colIndex;
                        final dayNum = index - startOffset + 1;

                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }

                        final bsDate = NepaliDateService.fromBsDate(bs.year, bs.month, dayNum);
                        final adDate = NepaliDateService.bsToAd(bsDate);
                        final isToday = today.year == bs.year &&
                            today.month == bs.month &&
                            today.day == dayNum;
                        final isSaturday = colIndex == 6;
                        final isSelected = selectedDay != null &&
                            selectedDay!.year == adDate.year &&
                            selectedDay!.month == adDate.month &&
                            selectedDay!.day == adDate.day;

                        final dayInfo = dayInfoMap[dayNum];
                        final isHoliday = dayInfo?.isHoliday ?? false;
                        final hasEvents = dayInfo != null && dayInfo.events.isNotEmpty;
                        final isAuspicious = auspicious?.hasAuspiciousDay(dayNum) ?? false;
                        final allEvents = merger.eventsForAdDate(adDate);
                        final hasGoogleEvents = allEvents.any((e) => e.source == CalendarEventSource.google);

                        // Prefer the Nepali name when the UI is in Nepali.
                        final names = isNepaliUi
                            ? (dayInfo?.eventsNp.isNotEmpty ?? false
                                ? dayInfo!.eventsNp
                                : dayInfo?.events ?? const [])
                            : (dayInfo?.events ?? const []);
                        final eventText = names.isNotEmpty ? names.first : null;

                        return Expanded(
                          child: _DayCell(
                            dayNum: dayNum,
                            adDay: adDate.day,
                            isToday: isToday,
                            isSaturday: isSaturday,
                            isSelected: isSelected,
                            isHoliday: isHoliday,
                            hasEvents: hasEvents,
                            isAuspicious: isAuspicious,
                            hasGoogleEvents: hasGoogleEvents,
                            showSecondaryDate: true,
                            eventText: eventText,
                            onTap: () {
                              ref.read(selectedDayNotifierProvider.notifier).select(adDate);
                            },
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// AD month grid — shows a single Gregorian month.
class _AdMonthGrid extends ConsumerWidget {
  final DateTime focusedAd;
  final DateTime? selectedDay;
  final CalendarEventMerger merger;

  const _AdMonthGrid({
    required this.focusedAd,
    required this.selectedDay,
    required this.merger,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = focusedAd.year;
    final month = focusedAd.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayWeekday = DateTime(year, month, 1).weekday % 7; // 0=Sun
    final startOffset = firstDayWeekday;

    final now = DateTime.now();
    final rows = ((startOffset + daysInMonth) / 7).ceil();
    final theme = Theme.of(context);
    final isNepaliUi = AppLocalizations.of(context).isNepali;

    // Get events for this AD month
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month, daysInMonth);
    final events = merger.eventsForAdRange(start, end);
    final eventsByDay = <int, List<CalendarEvent>>{};
    for (final e in events) {
      final day = e.startTime.day;
      eventsByDay.putIfAbsent(day, () => []).add(e);
    }

    return Column(
      children: [
        _WeekdayHeader(),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: List.generate(rows, (rowIndex) {
                  return Expanded(
                    child: Row(
                      children: List.generate(7, (colIndex) {
                        final index = rowIndex * 7 + colIndex;
                        final dayNum = index - startOffset + 1;

                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }

                        final adDate = DateTime(year, month, dayNum);
                        final bsDate = NepaliDateService.adToBs(adDate);
                        final isToday = now.year == year &&
                            now.month == month &&
                            now.day == dayNum;
                        final isSaturday = colIndex == 6;
                        final isSelected = selectedDay != null &&
                            selectedDay!.year == year &&
                            selectedDay!.month == month &&
                            selectedDay!.day == dayNum;

                        final dayEvents = eventsByDay[dayNum] ?? [];
                        final isHoliday = dayEvents.any((e) => e.isHoliday);
                        final hasEvents = dayEvents.isNotEmpty;
                        final isAuspicious = dayEvents.any((e) => e.auspiciousType != null);
                        final hasGoogleEvents = dayEvents.any((e) => e.source == CalendarEventSource.google);

                        final first = dayEvents.isNotEmpty ? dayEvents.first : null;
                        final eventText = first == null
                            ? null
                            : (isNepaliUi ? (first.titleNp ?? first.title) : first.title);

                        return Expanded(
                          child: _DayCell(
                            dayNum: dayNum,
                            adDay: bsDate.day, // Show BS day as secondary
                            isToday: isToday,
                            isSaturday: isSaturday,
                            isSelected: isSelected,
                            isHoliday: isHoliday,
                            hasEvents: hasEvents,
                            isAuspicious: isAuspicious,
                            hasGoogleEvents: hasGoogleEvents,
                            showSecondaryDate: true,
                            secondaryIsNepali: true,
                            eventText: eventText,
                            onTap: () {
                              ref.read(selectedDayNotifierProvider.notifier).select(adDate);
                            },
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Weekday header row (Sun–Sat).
///
/// Uses full day names — the single-syllable forms ("बि", "श") were ambiguous
/// between बिहीबार/बुधबार and शनिबार/शुक्रबार.
class _WeekdayHeader extends StatelessWidget {
  static const _daysNp = ['आइत', 'सोम', 'मंगल', 'बुध', 'बिही', 'शुक्र', 'शनि'];
  static const _daysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 38,
      child: Row(
        children: List.generate(7, (i) {
          final isSaturday = i == 6;
          final color =
              isSaturday ? Colors.red : theme.colorScheme.onSurfaceVariant;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _daysNp[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  _daysEn[i],
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Individual day cell.
class _DayCell extends StatelessWidget {
  final int dayNum;
  final int adDay;
  final bool isToday;
  final bool isSaturday;
  final bool isSelected;
  final bool isHoliday;
  final bool hasEvents;
  final bool isAuspicious;
  final bool hasGoogleEvents;
  final bool showSecondaryDate;
  final bool secondaryIsNepali;

  /// Festival/holiday name shown inside the cell, when there is room.
  final String? eventText;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayNum,
    required this.adDay,
    required this.isToday,
    required this.isSaturday,
    required this.isSelected,
    required this.isHoliday,
    required this.hasEvents,
    required this.isAuspicious,
    this.hasGoogleEvents = false,
    required this.showSecondaryDate,
    this.secondaryIsNepali = false,
    this.eventText,
    required this.onTap,
  });

  static String _toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? textColor;
    if (isHoliday || isSaturday) {
      textColor = Colors.red[isDark ? 300 : 700];
    }

    // Tint non-working days so holidays read at a glance, matching the
    // home-screen calendar.
    Color? background;
    if (isSelected) {
      background = theme.colorScheme.primaryContainer;
    } else if (isHoliday) {
      background = Colors.red.withValues(alpha: isDark ? 0.10 : 0.06);
    } else if (isSaturday) {
      background = Colors.red.withValues(alpha: isDark ? 0.05 : 0.03);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            // Day number (top-left)
            Positioned(
              top: 4,
              left: 6,
              child: isToday
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          secondaryIsNepali
                              ? dayNum.toString()
                              : _toNepaliNumeral(dayNum),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      secondaryIsNepali
                          ? dayNum.toString()
                          : _toNepaliNumeral(dayNum),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
            ),
            // Secondary date (top-right)
            if (showSecondaryDate)
              Positioned(
                top: 4,
                right: 4,
                child: Text(
                  secondaryIsNepali
                      ? _toNepaliNumeral(adDay)
                      : adDay.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            // Festival / holiday name
            if (eventText != null && eventText!.isNotEmpty)
              Positioned(
                // Clears the 24px "today" circle that sits at top: 4.
                top: 30,
                left: 4,
                right: 4,
                bottom: 12,
                child: Text(
                  eventText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    color: isHoliday
                        ? Colors.red[isDark ? 300 : 600]
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            // Event/auspicious indicators (bottom)
            Positioned(
              bottom: 3,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasEvents && !isHoliday)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isHoliday)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isAuspicious)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasGoogleEvents)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
