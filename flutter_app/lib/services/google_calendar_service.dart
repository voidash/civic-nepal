import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../models/calendar_event.dart';
import 'google_auth_service.dart';

/// Fetches, caches, and syncs Google Calendar events.
class GoogleCalendarService {
  static final GoogleCalendarService instance = GoogleCalendarService._();
  GoogleCalendarService._();

  /// Cached calendar list (id → name + color).
  final Map<String, CalendarMeta> _calendars = {};

  /// Cached events indexed by date string (YYYY-MM-DD).
  final Map<String, List<CalendarEvent>> _eventsByDate = {};

  /// Whether initial sync has been done.
  bool _hasSynced = false;
  bool get hasSynced => _hasSynced;

  /// Get list of user's calendars.
  Map<String, CalendarMeta> get calendars => Map.unmodifiable(_calendars);

  /// Fetch the user's calendar list from Google.
  Future<void> fetchCalendarList() async {
    final api = GoogleAuthService.instance.calendarApi;
    if (api == null) return;

    try {
      final list = await api.calendarList.list();
      _calendars.clear();
      for (final entry in list.items ?? <gcal.CalendarListEntry>[]) {
        if (entry.id == null) continue;
        _calendars[entry.id!] = CalendarMeta(
          id: entry.id!,
          summary: entry.summary ?? 'Untitled',
          color: _parseColor(entry.backgroundColor),
          primary: entry.primary ?? false,
        );
      }
    } catch (e) {
      // If we get a 401, auth may have expired
      rethrow;
    }
  }

  /// Fetch events for a date range from Google Calendar.
  /// Uses incremental sync when possible.
  Future<List<CalendarEvent>> fetchEvents({
    required DateTime start,
    required DateTime end,
    Set<String>? calendarIds,
  }) async {
    final api = GoogleAuthService.instance.calendarApi;
    if (api == null) return [];

    // The calendar list is what says which calendars to read. Callers watch
    // auth state, which flips to signed-in before the list finishes loading,
    // so without this a fresh sign-in fetched from zero calendars, returned
    // nothing, and never retried.
    if (_calendars.isEmpty) {
      try {
        await fetchCalendarList();
      } catch (_) {
        return [];
      }
    }

    final targetCalendars = calendarIds ?? _calendars.keys.toSet();
    final allEvents = <CalendarEvent>[];

    for (final calId in targetCalendars) {
      try {
        final events = await _fetchCalendarEvents(api, calId, start, end);
        allEvents.addAll(events);
      } catch (e) {
        // Skip calendars that fail (e.g. permission issues)
        continue;
      }
    }

    cacheEvents(allEvents);
    _hasSynced = true;
    return allEvents;
  }

  /// Index events by date, replacing any earlier copy of the same event.
  ///
  /// This used to append unconditionally, so every re-fetch of a month stacked
  /// another copy of each event onto the same day — navigate away and back and
  /// everything appeared twice, then three times.
  @visibleForTesting
  void cacheEvents(List<CalendarEvent> events) {
    for (final event in events) {
      final bucket = _eventsByDate.putIfAbsent(_dateKey(event.startTime), () => []);
      final existing = bucket.indexWhere((e) => e.id == event.id);
      if (existing >= 0) {
        bucket[existing] = event;
      } else {
        bucket.add(event);
      }
    }
  }

  Future<List<CalendarEvent>> _fetchCalendarEvents(
    gcal.CalendarApi api,
    String calendarId,
    DateTime start,
    DateTime end,
  ) async {
    final calMeta = _calendars[calendarId];
    final events = <CalendarEvent>[];

    String? pageToken;

    do {
      // Always a bounded range query. There used to be an incremental
      // sync-token branch here, but the API does not issue a nextSyncToken for
      // a request carrying timeMin/timeMax/orderBy, so it could never have
      // engaged — and had it engaged it would have returned recent changes
      // instead of the requested month, blanking the grid on navigation.
      final result = await api.events.list(
        calendarId,
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        pageToken: pageToken,
      );

      for (final item in result.items ?? <gcal.Event>[]) {
        if (item.status == 'cancelled') continue;

        final eventStart = item.start;
        if (eventStart == null) continue;

        final isAllDay = eventStart.date != null;
        DateTime startTime;
        DateTime? endTime;

        if (isAllDay) {
          startTime = eventStart.date!;
          // Google reports an exclusive end date for all-day events, so a
          // one-day event comes back ending the following day. Pull it back
          // to the last day the event actually covers.
          final exclusiveEnd = item.end?.date;
          endTime = exclusiveEnd?.subtract(const Duration(days: 1));
        } else {
          startTime = eventStart.dateTime?.toLocal() ?? DateTime.now();
          endTime = item.end?.dateTime?.toLocal();
        }

        events.add(CalendarEvent(
          id: 'google_${calendarId}_${item.id}',
          title: item.summary ?? '(No title)',
          startTime: startTime,
          endTime: endTime,
          isAllDay: isAllDay,
          source: CalendarEventSource.google,
          calendarId: calendarId,
          color: calMeta?.color,
          location: item.location,
          description: item.description,
        ));
      }

      pageToken = result.nextPageToken;
    } while (pageToken != null);

    return events;
  }

  /// Get cached events for a specific date.
  List<CalendarEvent> cachedEventsForDate(DateTime date) {
    return _eventsByDate[_dateKey(date)] ?? [];
  }

  /// Get cached events for a date range.
  List<CalendarEvent> cachedEventsForRange(DateTime start, DateTime end) {
    final results = <CalendarEvent>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      results.addAll(_eventsByDate[_dateKey(current)] ?? []);
      current = current.add(const Duration(days: 1));
    }
    return results;
  }

  /// Create a new event on Google Calendar.
  Future<CalendarEvent?> createEvent({
    required String calendarId,
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    required bool isAllDay,
    String? location,
    String? description,
  }) async {
    final api = GoogleAuthService.instance.calendarApi;
    if (api == null) return null;

    final event = gcal.Event(
      summary: title,
      location: location,
      description: description,
      start: isAllDay
          ? gcal.EventDateTime(date: startTime)
          : gcal.EventDateTime(dateTime: startTime.toUtc()),
      // All-day ends are exclusive on the wire, so the last covered day is
      // sent as the day after. Mirrors the inclusive end read back above.
      end: isAllDay
          ? gcal.EventDateTime(date: (endTime ?? startTime).add(const Duration(days: 1)))
          : gcal.EventDateTime(dateTime: (endTime ?? startTime.add(const Duration(hours: 1))).toUtc()),
    );

    try {
      final created = await api.events.insert(event, calendarId);
      final result = CalendarEvent(
        id: 'google_${calendarId}_${created.id}',
        title: created.summary ?? title,
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        source: CalendarEventSource.google,
        calendarId: calendarId,
        location: location,
        description: description,
      );

      // Update cache
      final key = _dateKey(startTime);
      _eventsByDate.putIfAbsent(key, () => []).add(result);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a Google Calendar event.
  Future<bool> deleteEvent(CalendarEvent event) async {
    final api = GoogleAuthService.instance.calendarApi;
    if (api == null) return false;
    if (event.calendarId == null) return false;

    // Extract the Google event ID from our composite ID
    final googleEventId = event.id.replaceFirst('google_${event.calendarId}_', '');

    try {
      await api.events.delete(event.calendarId!, googleEventId);

      // Remove from cache
      final key = _dateKey(event.startTime);
      _eventsByDate[key]?.removeWhere((e) => e.id == event.id);

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all cached data (on sign-out).
  void clearCache() {
    _calendars.clear();
    _eventsByDate.clear();
    _hasSynced = false;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    return Color(int.parse('FF$clean', radix: 16));
  }
}

/// Metadata for a Google Calendar.
class CalendarMeta {
  final String id;
  final String summary;
  final Color? color;
  final bool primary;

  const CalendarMeta({
    required this.id,
    required this.summary,
    this.color,
    this.primary = false,
  });
}
