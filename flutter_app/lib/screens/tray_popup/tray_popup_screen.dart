import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_view_provider.dart';
import '../../services/calendar_event_merger.dart';
import '../../services/nepali_date_service.dart';
import '../../services/popup_controller.dart';

class TrayPopupScreen extends ConsumerWidget {
  const TrayPopupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure data + Google sync are loaded.
    ref.watch(calendarDataLoaderProvider);
    ref.watch(googleCalendarSyncProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final today = NepaliDateService.today();
    final todayAd = NepaliDateService.bsToAd(today);
    final weekdayNp = NepaliDateService.getWeekdayNp(today);
    final monthNp = NepaliDateService.getMonthNameNp(today.month);
    final monthEn = NepaliDateService.getMonthNameEn(today.month);

    final adFormatted =
        '${_adMonthName(todayAd.month)} ${todayAd.day}, ${todayAd.year}';

    final upcomingEvents = _upcomingGoogleEvents(ref);

    return Material(
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            weekdayNp: weekdayNp,
            dayNp: today.day.toString(),
            monthNp: monthNp,
            yearNp: today.year.toString(),
            monthEn: monthEn,
            adFormatted: adFormatted,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          if (upcomingEvents.isNotEmpty) ...[
            _SectionLabel('Upcoming'),
            ...upcomingEvents.map((e) => _EventRow(event: e)),
          ] else
            _EmptyEventsRow(),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _OpenAppButton(),
        ],
      ),
    );
  }

  List<CalendarEvent> _upcomingGoogleEvents(WidgetRef ref) {
    final merger = ref.read(calendarEventMergerProvider);
    final now = DateTime.now();
    final end = now.add(const Duration(hours: 24));
    return merger
        .eventsForAdRange(now, end)
        .where((e) => e.source == CalendarEventSource.google)
        .take(5)
        .toList();
  }

  static const _adMonthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _adMonthName(int month) =>
      month >= 1 && month <= 12 ? _adMonthNames[month] : '?';
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String weekdayNp;
  final String dayNp;
  final String monthNp;
  final String yearNp;
  final String monthEn;
  final String adFormatted;

  const _Header({
    required this.weekdayNp,
    required this.dayNp,
    required this.monthNp,
    required this.yearNp,
    required this.monthEn,
    required this.adFormatted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekdayNp,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Devanagari',
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayNp $monthNp $yearNp',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Devanagari',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  adFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  monthEn,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => PopupController.instance.hidePopup(),
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final CalendarEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = event.color ?? colorScheme.primary;
    final timeLabel = event.isAllDay
        ? 'All day'
        : _formatTime(event.startTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: eventColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    // Convert to Nepal time (UTC+5:45).
    final nepalOffset = const Duration(hours: 5, minutes: 45);
    final nepalTime = dt.toUtc().add(nepalOffset);
    final hour = nepalTime.hour;
    final minute = nepalTime.minute;
    final amPm = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $amPm';
  }
}

class _EmptyEventsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Text(
        'No upcoming events',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _OpenAppButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: FilledButton.tonal(
        onPressed: () => PopupController.instance.expandToFullApp(),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(36),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Open Nagarik Patro', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}
