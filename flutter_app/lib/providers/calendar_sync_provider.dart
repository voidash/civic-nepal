import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/calendar_event.dart';
import '../services/google_calendar_service.dart';
import '../services/nepali_date_service.dart';
import 'calendar_view_provider.dart';
import 'google_auth_provider.dart';

part 'calendar_sync_provider.g.dart';

/// Provides merged events (Nepali + Google) for the currently focused month.
@riverpod
Future<List<CalendarEvent>> mergedMonthEvents(Ref ref) async {
  // Watch auth state — re-fetch when sign-in changes
  final auth = ref.watch(googleAuthProvider);
  final focused = ref.watch(focusedDateNotifierProvider);
  final merger = ref.read(calendarEventMergerProvider);

  // Ensure Nepali data is loaded
  await merger.loadNepaliData();

  final bs = NepaliDateService.adToBs(focused);
  final nepaliEvents = merger.eventsForBsMonth(bs.year, bs.month);

  if (!auth.isSignedIn) {
    return nepaliEvents;
  }

  // Fetch Google events for the visible range
  try {
    final daysInMonth = NepaliDateService.getDaysInMonth(bs.year, bs.month);
    final firstDay = NepaliDateService.bsToAd(NepaliDateService.fromBsDate(bs.year, bs.month, 1));
    final lastDay = NepaliDateService.bsToAd(NepaliDateService.fromBsDate(bs.year, bs.month, daysInMonth));

    // Pad ±7 days for week view transitions
    final start = firstDay.subtract(const Duration(days: 7));
    final end = lastDay.add(const Duration(days: 7));

    final googleEvents = await GoogleCalendarService.instance.fetchEvents(
      start: start,
      end: end,
    );

    // Merge and sort
    final all = [...nepaliEvents, ...googleEvents];
    all.sort((a, b) => a.startTime.compareTo(b.startTime));
    return all;
  } catch (e) {
    // If Google fetch fails, still return Nepali events
    return nepaliEvents;
  }
}

/// Provides events for a specific AD date (merged).
@riverpod
Future<List<CalendarEvent>> eventsForDate(Ref ref, DateTime date) async {
  final auth = ref.watch(googleAuthProvider);
  final merger = ref.read(calendarEventMergerProvider);
  await merger.loadNepaliData();

  final nepaliEvents = merger.eventsForAdDate(date);

  if (!auth.isSignedIn) return nepaliEvents;

  // Use cached Google events
  final googleEvents = GoogleCalendarService.instance.cachedEventsForDate(date);
  final all = [...nepaliEvents, ...googleEvents];
  all.sort((a, b) => a.startTime.compareTo(b.startTime));
  return all;
}
