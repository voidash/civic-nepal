import 'package:flutter_test/flutter_test.dart';
import 'package:nagarik_calendar/models/calendar_event.dart';
import 'package:nagarik_calendar/services/google_calendar_service.dart';

/// Guards the event cache against re-fetch duplication.
///
/// Fetching a month used to append every event to that day's bucket without
/// checking whether it was already there. Because the calendar re-fetches on
/// every focused-date change, moving to the next month and back stacked a
/// second copy of every Google event onto the grid, then a third.
void main() {
  final service = GoogleCalendarService.instance;

  CalendarEvent event(String id, {DateTime? at, String title = 'Standup'}) {
    return CalendarEvent(
      id: id,
      title: title,
      startTime: at ?? DateTime(2026, 8, 9, 10, 0),
      endTime: (at ?? DateTime(2026, 8, 9, 10, 0)).add(const Duration(hours: 1)),
      isAllDay: false,
      source: CalendarEventSource.google,
      calendarId: 'primary',
    );
  }

  setUp(service.clearCache);

  test('re-caching the same events does not duplicate them', () {
    final batch = [event('google_primary_a'), event('google_primary_b')];

    service.cacheEvents(batch);
    service.cacheEvents(batch);
    service.cacheEvents(batch);

    final cached = service.cachedEventsForDate(DateTime(2026, 8, 9));
    expect(cached, hasLength(2));
    expect(
      cached.map((e) => e.id),
      containsAll(['google_primary_a', 'google_primary_b']),
    );
  });

  test('a re-fetched event replaces the stale copy', () {
    service.cacheEvents([event('google_primary_a', title: 'Standup')]);
    service.cacheEvents([event('google_primary_a', title: 'Standup (moved)')]);

    final cached = service.cachedEventsForDate(DateTime(2026, 8, 9));
    expect(cached, hasLength(1));
    expect(cached.single.title, 'Standup (moved)');
  });

  test('events are kept separate per day', () {
    service.cacheEvents([
      event('google_primary_a', at: DateTime(2026, 8, 9, 9)),
      event('google_primary_b', at: DateTime(2026, 8, 10, 9)),
    ]);

    expect(service.cachedEventsForDate(DateTime(2026, 8, 9)), hasLength(1));
    expect(service.cachedEventsForDate(DateTime(2026, 8, 10)), hasLength(1));
    expect(service.cachedEventsForDate(DateTime(2026, 8, 11)), isEmpty);
  });

  test('a date range returns every day it covers', () {
    service.cacheEvents([
      event('google_primary_a', at: DateTime(2026, 8, 9, 9)),
      event('google_primary_b', at: DateTime(2026, 8, 10, 9)),
      event('google_primary_c', at: DateTime(2026, 8, 20, 9)),
    ]);

    final range = service.cachedEventsForRange(
      DateTime(2026, 8, 9),
      DateTime(2026, 8, 10),
    );
    expect(range, hasLength(2));
  });

  test('clearCache empties the index', () {
    service.cacheEvents([event('google_primary_a')]);
    service.clearCache();
    expect(service.cachedEventsForDate(DateTime(2026, 8, 9)), isEmpty);
    expect(service.hasSynced, isFalse);
  });
}
