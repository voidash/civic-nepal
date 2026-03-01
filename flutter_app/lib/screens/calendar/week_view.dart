import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';
import '../../models/calendar_view_state.dart';
import '../../providers/calendar_view_provider.dart';
import '../../providers/google_auth_provider.dart';
import '../../services/nepali_date_service.dart';
import 'event_editor.dart';
import 'event_detail_popup.dart';

const _hourHeight = 60.0;
const _gutterWidth = 48.0;

/// Week view — 7 day columns with hourly time axis and event blocks.
class WeekView extends ConsumerWidget {
  const WeekView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedDateNotifierProvider);
    final dateSystem = ref.watch(dateSystemNotifierProvider);
    final merger = ref.read(calendarEventMergerProvider);
    ref.watch(googleCalendarSyncProvider);

    final weekday = focused.weekday % 7;
    final weekStart = focused.subtract(Duration(days: weekday));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final events = merger.eventsForAdRange(weekStart, weekEnd);

    // Include draft event if it falls in this week
    final draft = ref.watch(draftEventProvider);
    final allEvents = [...events];
    if (draft != null) {
      final draftOffset = draft.startTime.difference(
        DateTime(weekStart.year, weekStart.month, weekStart.day),
      ).inDays;
      if (draftOffset >= 0 && draftOffset < 7) {
        allEvents.add(draft);
      }
    }

    final now = DateTime.now();

    return Column(
      children: [
        _WeekDayHeaders(weekStart: weekStart, dateSystem: dateSystem, now: now),
        const Divider(height: 1),
        _AllDayRow(weekStart: weekStart, events: allEvents),
        const Divider(height: 1),
        Expanded(
          child: _WeekHourlyGrid(weekStart: weekStart, events: allEvents, now: now),
        ),
      ],
    );
  }
}

class _WeekDayHeaders extends StatelessWidget {
  final DateTime weekStart;
  final DateSystem dateSystem;
  final DateTime now;

  const _WeekDayHeaders({required this.weekStart, required this.dateSystem, required this.now});

  static const _daysShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _daysNpShort = ['आ', 'सो', 'मं', 'बु', 'बि', 'शु', 'श'];

  static String _toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: _gutterWidth),
          ...List.generate(7, (i) {
            final date = weekStart.add(Duration(days: i));
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
            final isSaturday = i == 6;

            String dayLabel;
            String dateLabel;
            if (dateSystem == DateSystem.bs) {
              final bs = NepaliDateService.adToBs(date);
              dayLabel = _daysNpShort[i];
              dateLabel = _toNepaliNumeral(bs.day);
            } else {
              dayLabel = _daysShort[i];
              dateLabel = date.day.toString();
            }

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayLabel, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isSaturday ? Colors.red : theme.colorScheme.onSurfaceVariant,
                  )),
                  const SizedBox(height: 2),
                  isToday
                      ? Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          child: Center(child: Text(dateLabel, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary,
                          ))),
                        )
                      : Text(dateLabel, style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: isSaturday ? Colors.red : null,
                        )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AllDayRow extends StatelessWidget {
  final DateTime weekStart;
  final List<CalendarEvent> events;

  const _AllDayRow({required this.weekStart, required this.events});

  @override
  Widget build(BuildContext context) {
    final allDay = events.where((e) => e.isAllDay).toList();
    if (allDay.isEmpty) return const SizedBox.shrink();

    final byDay = <int, List<CalendarEvent>>{};
    for (final e in allDay) {
      final dayOffset = e.startTime.difference(DateTime(weekStart.year, weekStart.month, weekStart.day)).inDays;
      if (dayOffset >= 0 && dayOffset < 7) {
        byDay.putIfAbsent(dayOffset, () => []).add(e);
      }
    }
    if (byDay.isEmpty) return const SizedBox.shrink();

    final maxEvents = byDay.values.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    final rowHeight = (maxEvents.clamp(1, 3) * 20.0) + 8;

    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _gutterWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, top: 4),
              child: Text('all-day', textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ),
          ...List.generate(7, (i) {
            final dayEvents = byDay[i] ?? [];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: dayEvents.take(3).map((e) {
                    final color = e.isHoliday ? Colors.red
                        : e.auspiciousType != null ? Colors.green
                        : e.source == CalendarEventSource.google ? (e.color ?? Colors.blue)
                        : Colors.orange;
                    return Container(
                      height: 16, margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(e.titleNp ?? e.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: color)),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeekHourlyGrid extends ConsumerWidget {
  final DateTime weekStart;
  final List<CalendarEvent> events;
  final DateTime now;

  const _WeekHourlyGrid({required this.weekStart, required this.events, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(googleAuthProvider);
    final isThisWeek = now.difference(weekStart).inDays >= 0 && now.difference(weekStart).inDays < 7;

    final controller = ScrollController(
      initialScrollOffset: isThisWeek ? (now.hour - 1).clamp(0, 23) * _hourHeight : 6 * _hourHeight,
    );

    // Group timed events by day
    final timedByDay = <int, List<CalendarEvent>>{};
    for (final e in events.where((e) => !e.isAllDay)) {
      final dayOffset = e.startTime.difference(DateTime(weekStart.year, weekStart.month, weekStart.day)).inDays;
      if (dayOffset >= 0 && dayOffset < 7) {
        timedByDay.putIfAbsent(dayOffset, () => []).add(e);
      }
    }

    return SingleChildScrollView(
      controller: controller,
      child: SizedBox(
        height: 24 * _hourHeight,
        child: Row(
          children: [
            // Time labels
            SizedBox(
              width: _gutterWidth,
              child: Stack(
                children: List.generate(24, (hour) {
                  final hourLabel = hour == 0 ? '12 AM'
                      : hour < 12 ? '$hour AM'
                      : hour == 12 ? '12 PM'
                      : '${hour - 12} PM';
                  return Positioned(
                    top: hour * _hourHeight,
                    left: 0, right: 4,
                    child: Text(hourLabel, textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                  );
                }),
              ),
            ),
            // 7 day columns
            ...List.generate(7, (dayIndex) {
              final dayDate = weekStart.add(Duration(days: dayIndex));
              final dayEvents = timedByDay[dayIndex] ?? [];

              return Expanded(
                child: _DayColumn(
                  date: dayDate,
                  events: dayEvents,
                  now: now,
                  isToday: isThisWeek && dayDate.day == now.day && dayDate.month == now.month,
                  showBorder: dayIndex > 0,
                  authSignedIn: authState.isSignedIn,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// A single day column in the week grid.
class _DayColumn extends ConsumerWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final DateTime now;
  final bool isToday;
  final bool showBorder;
  final bool authSignedIn;

  const _DayColumn({
    required this.date,
    required this.events,
    required this.now,
    required this.isToday,
    required this.showBorder,
    required this.authSignedIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Layout events into columns
    final positioned = _layoutEvents(events);

    return Stack(
      children: [
        // Hour lines + tap targets
        ...List.generate(24, (hour) {
          return Positioned(
            top: hour * _hourHeight,
            left: 0, right: 0,
            height: _hourHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: authSignedIn
                  ? () => _onTimeSlotTap(context, ref, hour)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    left: showBorder ? BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)) : BorderSide.none,
                  ),
                ),
              ),
            ),
          );
        }),
        // Event blocks
        ...positioned.map((pe) {
          final event = pe.event;
          final startMin = event.startTime.hour * 60 + event.startTime.minute;
          final endMin = event.endTime != null
              ? event.endTime!.hour * 60 + event.endTime!.minute
              : startMin + 60;
          final duration = (endMin - startMin).clamp(15, 24 * 60);

          final top = startMin * _hourHeight / 60;
          final height = duration * _hourHeight / 60;

          Color eventColor;
          if (event.source == CalendarEventSource.google) {
            eventColor = event.color ?? Colors.blue;
          } else if (event.isHoliday) {
            eventColor = Colors.red;
          } else {
            eventColor = Colors.orange;
          }

          final isDraft = event.id.startsWith('draft_');
          final colFraction = 1.0 / pe.totalColumns;

          return Positioned(
            top: top,
            height: height.toDouble(),
            left: pe.columnIndex * colFraction * 100,
            right: (1.0 - (pe.columnIndex + 1) * colFraction) * 100,
            child: FractionallySizedBox(
              widthFactor: colFraction,
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: isDraft ? null : () => EventDetailPopup.show(context, ref, event),
                child: MouseRegion(
                  cursor: isDraft ? SystemMouseCursors.basic : SystemMouseCursors.click,
                  child: Container(
                    margin: const EdgeInsets.only(right: 1, top: 1, bottom: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDraft
                          ? eventColor.withValues(alpha: isDark ? 0.15 : 0.08)
                          : isDark
                              ? eventColor.withValues(alpha: 0.3)
                              : eventColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: isDraft
                          ? Border.all(color: eventColor.withValues(alpha: 0.5), width: 1)
                          : Border(left: BorderSide(color: eventColor, width: 2)),
                    ),
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDraft
                            ? eventColor.withValues(alpha: 0.5)
                            : isDark ? Colors.white : eventColor,
                        fontStyle: isDraft ? FontStyle.italic : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        // Current time line
        if (isToday)
          Positioned(
            top: (now.hour * 60 + now.minute) * _hourHeight / 60,
            left: 0, right: 0,
            child: Container(height: 2, color: Colors.red),
          ),
      ],
    );
  }

  void _onTimeSlotTap(BuildContext context, WidgetRef ref, int hour) {
    // Create draft event
    final draftEvent = CalendarEvent(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      title: '(New event)',
      startTime: DateTime(date.year, date.month, date.day, hour),
      endTime: DateTime(date.year, date.month, date.day, (hour + 1) % 24),
      isAllDay: false,
      source: CalendarEventSource.local,
    );
    ref.read(draftEventProvider.notifier).state = draftEvent;

    EventEditorDialog.show(
      context,
      initialDate: date,
      initialTime: TimeOfDay(hour: hour, minute: 0),
    ).then((_) {
      ref.read(draftEventProvider.notifier).state = null;
    });
  }

  List<_PositionedEvent> _layoutEvents(List<CalendarEvent> events) {
    if (events.isEmpty) return [];

    final sorted = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final groups = <List<_PositionedEvent>>[];
    List<_PositionedEvent>? currentGroup;
    int groupEnd = 0;

    for (final event in sorted) {
      final startMin = event.startTime.hour * 60 + event.startTime.minute;
      final endMin = event.endTime != null
          ? event.endTime!.hour * 60 + event.endTime!.minute
          : startMin + 60;

      if (currentGroup == null || startMin >= groupEnd) {
        if (currentGroup != null) groups.add(currentGroup);
        currentGroup = [];
        groupEnd = endMin;
      } else {
        if (endMin > groupEnd) groupEnd = endMin;
      }

      int col = 0;
      for (final existing in currentGroup) {
        final existingEnd = existing.event.endTime != null
            ? existing.event.endTime!.hour * 60 + existing.event.endTime!.minute
            : existing.event.startTime.hour * 60 + existing.event.startTime.minute + 60;
        if (startMin < existingEnd && existing.columnIndex == col) col++;
      }

      currentGroup.add(_PositionedEvent(event: event, columnIndex: col, totalColumns: 1));
    }
    if (currentGroup != null) groups.add(currentGroup);

    final result = <_PositionedEvent>[];
    for (final group in groups) {
      final maxCol = group.map((e) => e.columnIndex).reduce((a, b) => a > b ? a : b) + 1;
      for (final pe in group) {
        pe.totalColumns = maxCol;
        result.add(pe);
      }
    }
    return result;
  }
}

class _PositionedEvent {
  final CalendarEvent event;
  final int columnIndex;
  int totalColumns;
  _PositionedEvent({required this.event, required this.columnIndex, required this.totalColumns});
}
