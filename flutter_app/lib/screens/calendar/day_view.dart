import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';
import '../../models/calendar_view_state.dart';
import '../../providers/calendar_view_provider.dart';
import '../../providers/google_auth_provider.dart';
import '../../services/nepali_date_service.dart';
import 'event_editor.dart';
import 'event_detail_popup.dart';

/// Hour slot height in pixels.
const _hourHeight = 60.0;

/// Time gutter width.
const _gutterWidth = 56.0;

/// Day view — single day with hourly time slots and event blocks.
class DayView extends ConsumerWidget {
  const DayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedDateNotifierProvider);
    final dateSystem = ref.watch(dateSystemNotifierProvider);
    final merger = ref.read(calendarEventMergerProvider);
    // Watch sync to get Google events
    ref.watch(googleCalendarSyncProvider);
    final events = merger.eventsForAdDate(focused);

    // Include draft event if it matches this day
    final draft = ref.watch(draftEventProvider);
    final allEvents = [...events];
    if (draft != null &&
        draft.startTime.year == focused.year &&
        draft.startTime.month == focused.month &&
        draft.startTime.day == focused.day) {
      allEvents.add(draft);
    }

    final allDayEvents = allEvents.where((e) => e.isAllDay).toList();
    final timedEvents = allEvents.where((e) => !e.isAllDay).toList();

    final now = DateTime.now();
    final isToday = focused.year == now.year &&
        focused.month == now.month &&
        focused.day == now.day;

    return Column(
      children: [
        // Day header
        _DayHeader(date: focused, dateSystem: dateSystem, isToday: isToday),
        const Divider(height: 1),
        // All-day events strip
        if (allDayEvents.isNotEmpty)
          _AllDayStrip(events: allDayEvents),
        if (allDayEvents.isNotEmpty) const Divider(height: 1),
        // Hourly timeline with event blocks
        Expanded(
          child: _HourlyTimeline(
            date: focused,
            timedEvents: timedEvents,
            isToday: isToday,
            now: now,
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final DateSystem dateSystem;
  final bool isToday;

  const _DayHeader({required this.date, required this.dateSystem, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bs = NepaliDateService.adToBs(date);

    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final weekdaysNp = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार'];
    final adWeekday = date.weekday % 7;

    String primary;
    String secondary;
    if (dateSystem == DateSystem.bs) {
      primary = '${weekdaysNp[adWeekday]}, ${NepaliDateService.formatShortNp(bs)}';
      secondary = '${weekdays[adWeekday]}, ${_formatAdShort(date)}';
    } else {
      primary = '${weekdays[adWeekday]}, ${_formatAdShort(date)}';
      secondary = '${weekdaysNp[adWeekday]}, ${NepaliDateService.formatShortNp(bs)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (isToday)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Today',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primary, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(secondary, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAdShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _AllDayStrip extends StatelessWidget {
  final List<CalendarEvent> events;
  const _AllDayStrip({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: events.map((e) {
          Color chipColor;
          if (e.isHoliday) {
            chipColor = Colors.red;
          } else if (e.auspiciousType != null) {
            chipColor = Colors.green;
          } else if (e.source == CalendarEventSource.google) {
            chipColor = e.color ?? Colors.blue;
          } else {
            chipColor = Colors.orange;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border(left: BorderSide(color: chipColor, width: 3)),
            ),
            child: Text(
              e.titleNp ?? e.title,
              style: TextStyle(fontSize: 12, color: chipColor),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HourlyTimeline extends ConsumerWidget {
  final DateTime date;
  final List<CalendarEvent> timedEvents;
  final bool isToday;
  final DateTime now;

  const _HourlyTimeline({
    required this.date,
    required this.timedEvents,
    required this.isToday,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(googleAuthProvider);
    final controller = ScrollController(
      initialScrollOffset: isToday ? (now.hour - 1).clamp(0, 23) * _hourHeight : 6 * _hourHeight,
    );

    // Layout overlapping events into columns
    final columns = _layoutEvents(timedEvents);

    return SingleChildScrollView(
      controller: controller,
      child: SizedBox(
        height: 24 * _hourHeight,
        child: Stack(
          children: [
            // Hour lines + labels + tap targets
            ...List.generate(24, (hour) {
              final hourLabel = hour == 0
                  ? '12 AM'
                  : hour < 12
                      ? '$hour AM'
                      : hour == 12
                          ? '12 PM'
                          : '${hour - 12} PM';

              return Positioned(
                top: hour * _hourHeight,
                left: 0,
                right: 0,
                height: _hourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _gutterWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          hourLabel,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: authState.isSignedIn
                            ? () => _onTimeSlotTap(context, ref, hour)
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Event blocks
            ...columns.expand((col) {
              return col.events.map((positioned) {
                final event = positioned.event;
                final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
                final endMinutes = event.endTime != null
                    ? event.endTime!.hour * 60 + event.endTime!.minute
                    : startMinutes + 60;
                final duration = (endMinutes - startMinutes).clamp(15, 24 * 60);

                final top = startMinutes * _hourHeight / 60;
                final height = duration * _hourHeight / 60;

                // Calculate horizontal position based on column
                final totalColumns = positioned.totalColumns;
                final colIndex = positioned.columnIndex;

                Color eventColor;
                if (event.source == CalendarEventSource.google) {
                  eventColor = event.color ?? Colors.blue;
                } else if (event.isHoliday) {
                  eventColor = Colors.red;
                } else {
                  eventColor = Colors.orange;
                }

                final isDraft = event.id.startsWith('draft_');

                return Positioned(
                  top: top,
                  left: _gutterWidth + (colIndex * (1.0 / totalColumns) * 100).toDouble().clamp(0, double.infinity),
                  right: 4.0 + ((totalColumns - colIndex - 1) * (1.0 / totalColumns) * 100).toDouble().clamp(0, double.infinity),
                  height: height.toDouble(),
                  child: _EventBlock(
                    event: event,
                    color: eventColor,
                    isDraft: isDraft,
                    onTap: isDraft ? null : () => EventDetailPopup.show(context, ref, event),
                  ),
                );
              });
            }),
            // Current time indicator
            if (isToday)
              Positioned(
                top: (now.hour * 60 + now.minute) * _hourHeight / 60,
                left: _gutterWidth - 4,
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(height: 2, color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// When a time slot is tapped: create a draft block, open editor, clear draft on return.
  void _onTimeSlotTap(BuildContext context, WidgetRef ref, int hour) {
    // Create draft event at this time slot
    final draftEvent = CalendarEvent(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      title: '(New event)',
      startTime: DateTime(date.year, date.month, date.day, hour),
      endTime: DateTime(date.year, date.month, date.day, (hour + 1) % 24),
      isAllDay: false,
      source: CalendarEventSource.local,
    );
    ref.read(draftEventProvider.notifier).state = draftEvent;

    // Open editor — clear draft when it closes regardless of outcome
    EventEditorDialog.show(
      context,
      initialDate: date,
      initialTime: TimeOfDay(hour: hour, minute: 0),
    ).then((_) {
      ref.read(draftEventProvider.notifier).state = null;
    });
  }

  /// Layout overlapping events into non-overlapping columns.
  List<_EventColumn> _layoutEvents(List<CalendarEvent> events) {
    if (events.isEmpty) return [];

    // Sort by start time
    final sorted = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Assign columns to avoid overlap
    final positioned = <_PositionedEvent>[];
    final groups = <List<_PositionedEvent>>[];
    List<_PositionedEvent>? currentGroup;
    int groupEnd = 0;

    for (final event in sorted) {
      final startMin = event.startTime.hour * 60 + event.startTime.minute;
      final endMin = event.endTime != null
          ? event.endTime!.hour * 60 + event.endTime!.minute
          : startMin + 60;

      if (currentGroup == null || startMin >= groupEnd) {
        // Start a new group
        if (currentGroup != null) groups.add(currentGroup);
        currentGroup = [];
        groupEnd = endMin;
      } else {
        groupEnd = endMin > groupEnd ? endMin : groupEnd;
      }

      // Find first available column in group
      int col = 0;
      for (final existing in currentGroup) {
        final existingEnd = existing.event.endTime != null
            ? existing.event.endTime!.hour * 60 + existing.event.endTime!.minute
            : existing.event.startTime.hour * 60 + existing.event.startTime.minute + 60;
        if (startMin < existingEnd && existing.columnIndex == col) {
          col++;
        }
      }

      final pe = _PositionedEvent(event: event, columnIndex: col, totalColumns: 1);
      currentGroup.add(pe);
      positioned.add(pe);
    }
    if (currentGroup != null) groups.add(currentGroup);

    // Set totalColumns for each group
    for (final group in groups) {
      final maxCol = group.map((e) => e.columnIndex).reduce((a, b) => a > b ? a : b) + 1;
      for (final pe in group) {
        pe.totalColumns = maxCol;
      }
    }

    return [_EventColumn(events: positioned)];
  }
}

class _PositionedEvent {
  final CalendarEvent event;
  final int columnIndex;
  int totalColumns;

  _PositionedEvent({
    required this.event,
    required this.columnIndex,
    required this.totalColumns,
  });
}

class _EventColumn {
  final List<_PositionedEvent> events;
  _EventColumn({required this.events});
}

/// Rendered event block on the timeline.
class _EventBlock extends StatelessWidget {
  final CalendarEvent event;
  final Color color;
  final bool isDraft;
  final VoidCallback? onTap;

  const _EventBlock({
    required this.event,
    required this.color,
    this.isDraft = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          margin: const EdgeInsets.only(right: 2, top: 1, bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDraft
                ? color.withValues(alpha: isDark ? 0.15 : 0.08)
                : isDark
                    ? color.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: isDraft
                ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
                : Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDraft
                      ? color.withValues(alpha: 0.5)
                      : isDark
                          ? Colors.white
                          : color.withValues(alpha: 0.9),
                  fontStyle: isDraft ? FontStyle.italic : null,
                ),
              ),
              if (!isDraft && (event.startTime.hour > 0 || event.startTime.minute > 0))
                Text(
                  _formatTime(event.startTime, event.endTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : color.withValues(alpha: 0.7),
                  ),
                ),
              if (!isDraft && event.location != null && event.location!.isNotEmpty)
                Text(
                  event.location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : color.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime start, DateTime? end) {
    final s = '${start.hour % 12 == 0 ? 12 : start.hour % 12}:${start.minute.toString().padLeft(2, '0')} ${start.hour < 12 ? 'AM' : 'PM'}';
    if (end == null) return s;
    final e = '${end.hour % 12 == 0 ? 12 : end.hour % 12}:${end.minute.toString().padLeft(2, '0')} ${end.hour < 12 ? 'AM' : 'PM'}';
    return '$s – $e';
  }
}
