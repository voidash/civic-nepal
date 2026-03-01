import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';
import '../../models/calendar_view_state.dart';
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
class _WeekdayHeader extends StatelessWidget {
  static const _daysNp = ['आ', 'सो', 'मं', 'बु', 'बि', 'शु', 'श'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: Row(
        children: List.generate(7, (i) {
          final isSaturday = i == 6;
          return Expanded(
            child: Center(
              child: Text(
                _daysNp[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSaturday
                      ? Colors.red
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
    required this.onTap,
  });

  static String _toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? textColor;
    if (isHoliday || isSaturday) {
      textColor = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : null,
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
