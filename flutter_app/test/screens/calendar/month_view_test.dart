import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagarik_calendar/models/calendar_event.dart';
import 'package:nagarik_calendar/providers/calendar_view_provider.dart';
import 'package:nagarik_calendar/screens/calendar/month_view.dart';
import 'package:nagarik_calendar/services/calendar_event_merger.dart';

/// Merger whose Nepali data only becomes available *after* [loadNepaliData]
/// completes — mirroring the real asset load, which finishes a few frames
/// after the first paint.
class _AsyncLoadingMerger extends CalendarEventMerger {
  bool _ready = false;

  @override
  Future<void> loadNepaliData() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _ready = true;
  }

  @override
  Map<int, NepaliDayInfo> nepaliDayInfoForMonth(int bsYear, int bsMonth) {
    if (!_ready) return {};
    return {
      1: const NepaliDayInfo(
        events: ['Test Festival'],
        eventsNp: ['परीक्षण पर्व'],
        isHoliday: false,
      ),
    };
  }

  @override
  AuspiciousDayData? auspiciousDataForMonth(int bsYear, int bsMonth) =>
      _ready ? const AuspiciousDayData(bibahaLagan: [], bratabandha: [], pasni: []) : null;

  @override
  List<CalendarEvent> eventsForAdDate(DateTime date) => [];
}

/// Counts the small circular event-indicator dots painted in the grid.
int _dotsOfColor(WidgetTester tester, Color color) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle && d.color == color;
      })
      .length;
}

void main() {
  testWidgets(
    'MonthView shows event indicators once calendar data finishes loading, '
    'without requiring user interaction',
    (tester) async {
      final merger = _AsyncLoadingMerger();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calendarEventMergerProvider.overrideWithValue(merger),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MonthView()),
          ),
        ),
      );

      // First paint: data has not loaded yet, so no event dots.
      expect(_dotsOfColor(tester, Colors.orange), 0,
          reason: 'no data loaded yet on first frame');

      // Let the async load complete and settle the widget tree.
      // Crucially: no taps, no navigation — just time passing.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(
        _dotsOfColor(tester, Colors.orange),
        greaterThan(0),
        reason: 'MonthView must rebuild when calendarDataLoaderProvider resolves',
      );
    },
  );
}
