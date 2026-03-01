import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_view_state.dart';
import '../../providers/calendar_view_provider.dart';
import '../../services/nepali_date_service.dart';
import '../../services/calendar_event_merger.dart';

/// Year view — 4×3 grid of mini-month calendars.
class YearView extends ConsumerWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedDateNotifierProvider);
    final dateSystem = ref.watch(dateSystemNotifierProvider);
    final merger = ref.read(calendarEventMergerProvider);

    if (dateSystem == DateSystem.bs) {
      final bs = NepaliDateService.adToBs(focused);
      return _BsYearGrid(bsYear: bs.year, merger: merger, ref: ref);
    } else {
      return _AdYearGrid(adYear: focused.year, merger: merger, ref: ref);
    }
  }
}

class _BsYearGrid extends StatelessWidget {
  final int bsYear;
  final CalendarEventMerger merger;
  final WidgetRef ref;

  const _BsYearGrid({required this.bsYear, required this.merger, required this.ref});

  @override
  Widget build(BuildContext context) {
    final today = NepaliDateService.today();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          return _MiniMonth(
            title: NepaliDateService.getMonthNameNp(month),
            daysInMonth: NepaliDateService.getDaysInMonth(bsYear, month),
            firstWeekdayOffset: NepaliDateService.fromBsDate(bsYear, month, 1).weekday - 1,
            todayDay: (today.year == bsYear && today.month == month) ? today.day : null,
            merger: merger,
            bsYear: bsYear,
            bsMonth: month,
            onTap: () {
              // Navigate to this month in month view
              final bsDate = NepaliDateService.fromBsDate(bsYear, month, 1);
              final adDate = NepaliDateService.bsToAd(bsDate);
              ref.read(focusedDateNotifierProvider.notifier).setDate(adDate);
              ref.read(calendarViewModeNotifierProvider.notifier).setMode(CalendarViewMode.month);
            },
          );
        },
      ),
    );
  }
}

class _AdYearGrid extends StatelessWidget {
  final int adYear;
  final CalendarEventMerger merger;
  final WidgetRef ref;

  const _AdYearGrid({required this.adYear, required this.merger, required this.ref});

  static const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final daysInMonth = DateUtils.getDaysInMonth(adYear, month);
          final firstWeekday = DateTime(adYear, month, 1).weekday % 7; // 0=Sun

          return _MiniMonth(
            title: _monthNames[index],
            daysInMonth: daysInMonth,
            firstWeekdayOffset: firstWeekday,
            todayDay: (now.year == adYear && now.month == month) ? now.day : null,
            merger: merger,
            bsYear: null,
            bsMonth: null,
            onTap: () {
              ref.read(focusedDateNotifierProvider.notifier).setDate(DateTime(adYear, month, 1));
              ref.read(calendarViewModeNotifierProvider.notifier).setMode(CalendarViewMode.month);
            },
          );
        },
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final String title;
  final int daysInMonth;
  final int firstWeekdayOffset;
  final int? todayDay;
  final CalendarEventMerger merger;
  final int? bsYear;
  final int? bsMonth;
  final VoidCallback onTap;

  const _MiniMonth({
    required this.title,
    required this.daysInMonth,
    required this.firstWeekdayOffset,
    required this.todayDay,
    required this.merger,
    required this.bsYear,
    required this.bsMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = ((firstWeekdayOffset + daysInMonth) / 7).ceil();

    // Get event info for highlighting
    Map<int, bool>? holidayDays;
    Map<int, bool>? eventDays;
    if (bsYear != null && bsMonth != null) {
      final dayInfo = merger.nepaliDayInfoForMonth(bsYear!, bsMonth!);
      holidayDays = {};
      eventDays = {};
      for (final entry in dayInfo.entries) {
        if (entry.value.isHoliday) holidayDays[entry.key] = true;
        if (entry.value.events.isNotEmpty) eventDays[entry.key] = true;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month title
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            // Mini grid
            Expanded(
              child: Column(
                children: List.generate(rows, (rowIndex) {
                  return Expanded(
                    child: Row(
                      children: List.generate(7, (colIndex) {
                        final index = rowIndex * 7 + colIndex;
                        final dayNum = index - firstWeekdayOffset + 1;

                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const Expanded(child: SizedBox());
                        }

                        final isToday = dayNum == todayDay;
                        final isSaturday = colIndex == 6;
                        final isHoliday = holidayDays?[dayNum] ?? false;
                        final hasEvent = eventDays?[dayNum] ?? false;

                        return Expanded(
                          child: Center(
                            child: isToday
                                ? Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        dayNum.toString(),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    dayNum.toString(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: (isHoliday || isSaturday)
                                          ? Colors.red
                                          : hasEvent
                                              ? Colors.orange
                                              : theme.colorScheme.onSurface,
                                      fontWeight: hasEvent ? FontWeight.w600 : null,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
