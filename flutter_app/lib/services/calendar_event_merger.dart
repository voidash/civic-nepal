import '../models/calendar_event.dart';
import '../services/nepali_date_service.dart';
import '../services/data_service.dart';

/// Merges Nepali calendar events (from JSON) with Google Calendar events
/// into a unified [CalendarEvent] list.
class CalendarEventMerger {
  Map<String, dynamic>? _eventsData;
  Map<String, dynamic>? _auspiciousData;
  bool _loaded = false;

  /// Google Calendar events cached by date key (YYYY-MM-DD).
  final Map<String, List<CalendarEvent>> _googleEventsByDate = {};

  /// Set of calendar IDs that are currently enabled for display.
  Set<String>? _enabledCalendarIds;

  /// Update the set of enabled calendar IDs. Null = show all.
  void setEnabledCalendars(Set<String>? ids) {
    _enabledCalendarIds = ids;
  }

  /// Replace cached Google events with new data.
  void updateGoogleEvents(List<CalendarEvent> events) {
    _googleEventsByDate.clear();
    for (final event in events) {
      final key = _dateKey(event.startTime);
      _googleEventsByDate.putIfAbsent(key, () => []).add(event);
    }
  }

  /// Add a single Google event to the cache (for instant sync after creation).
  void addSingleGoogleEvent(CalendarEvent event) {
    final key = _dateKey(event.startTime);
    _googleEventsByDate.putIfAbsent(key, () => []).add(event);
  }

  /// Clear all Google event data (on sign-out).
  void clearGoogleEvents() {
    _googleEventsByDate.clear();
  }

  /// Get cached Google events for a specific AD date, filtered by enabled calendars.
  List<CalendarEvent> _googleEventsForDate(DateTime date) {
    final key = _dateKey(date);
    final events = _googleEventsByDate[key] ?? [];
    if (_enabledCalendarIds == null) return events;
    return events.where((e) =>
        e.calendarId == null || _enabledCalendarIds!.contains(e.calendarId)).toList();
  }

  /// Get cached Google events for an AD date range, filtered by enabled calendars.
  List<CalendarEvent> _googleEventsForRange(DateTime start, DateTime end) {
    final results = <CalendarEvent>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDay)) {
      results.addAll(_googleEventsForDate(current));
      current = current.add(const Duration(days: 1));
    }
    return results;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Load Nepali event data from bundled JSON. Call once at startup.
  Future<void> loadNepaliData() async {
    if (_loaded) return;
    try {
      _eventsData = await DataService.loadCalendarEvents();
      _auspiciousData = await DataService.loadAuspiciousDays();
    } catch (e) {
      // Gracefully degrade — no events rather than crash
      _eventsData = {};
      _auspiciousData = {};
    }
    _loaded = true;
  }

  /// Force reload data (e.g. after remote update).
  Future<void> reload() async {
    _loaded = false;
    await loadNepaliData();
  }

  /// Get month key for JSON lookup ("YYYY-MM").
  static String _monthKey(int bsYear, int bsMonth) =>
      '$bsYear-${bsMonth.toString().padLeft(2, '0')}';

  /// Get all Nepali events for a BS month, converted to [CalendarEvent].
  List<CalendarEvent> nepaliEventsForMonth(int bsYear, int bsMonth) {
    if (_eventsData == null) return [];

    final key = _monthKey(bsYear, bsMonth);
    final monthData = _eventsData![key] as Map<String, dynamic>?;
    if (monthData == null) return [];

    final days = monthData['days'] as List<dynamic>?;
    if (days == null) return [];

    final events = <CalendarEvent>[];
    for (final dayJson in days) {
      final day = dayJson as Map<String, dynamic>;
      final dayNum = day['day'] as int;
      final eventNames = (day['events'] as List<dynamic>?)?.cast<String>() ?? [];
      final eventNamesNp = (day['events_np'] as List<dynamic>?)?.cast<String>();
      final isHoliday = day['is_holiday'] as bool? ?? false;

      // Convert BS date to AD for the startTime
      final bsDate = NepaliDateService.fromBsDate(bsYear, bsMonth, dayNum);
      final adDate = NepaliDateService.bsToAd(bsDate);

      for (int i = 0; i < eventNames.length; i++) {
        events.add(CalendarEvent(
          id: 'nepali_${bsYear}_${bsMonth}_${dayNum}_$i',
          title: eventNames[i],
          titleNp: (eventNamesNp != null && i < eventNamesNp.length)
              ? eventNamesNp[i]
              : null,
          startTime: adDate,
          isAllDay: true,
          source: CalendarEventSource.nepali,
          isHoliday: isHoliday,
        ));
      }
    }
    return events;
  }

  /// Get auspicious days for a BS month as [CalendarEvent].
  List<CalendarEvent> auspiciousEventsForMonth(int bsYear, int bsMonth) {
    if (_auspiciousData == null) return [];

    final key = _monthKey(bsYear, bsMonth);
    final monthData = _auspiciousData![key] as Map<String, dynamic>?;
    if (monthData == null) return [];

    final events = <CalendarEvent>[];

    void addAuspicious(String jsonKey, AuspiciousType type, String titleEn, String titleNp) {
      final days = (monthData[jsonKey] as List<dynamic>?)?.cast<int>() ?? [];
      for (final dayNum in days) {
        final bsDate = NepaliDateService.fromBsDate(bsYear, bsMonth, dayNum);
        final adDate = NepaliDateService.bsToAd(bsDate);
        events.add(CalendarEvent(
          id: 'auspicious_${type.name}_${bsYear}_${bsMonth}_$dayNum',
          title: titleEn,
          titleNp: titleNp,
          startTime: adDate,
          isAllDay: true,
          source: CalendarEventSource.nepali,
          auspiciousType: type,
        ));
      }
    }

    addAuspicious('bibaha_lagan', AuspiciousType.wedding, 'Auspicious for Wedding', 'बिबाह लगन');
    addAuspicious('bratabandha', AuspiciousType.bratabandha, 'Auspicious for Bratabandha', 'ब्रतबन्ध');
    addAuspicious('pasni', AuspiciousType.pasni, 'Auspicious for Pasni', 'पास्नी');

    return events;
  }

  /// Get all events for a BS month (Nepali + auspicious + Google).
  /// Returns events sorted by day.
  List<CalendarEvent> eventsForBsMonth(int bsYear, int bsMonth) {
    final nepali = nepaliEventsForMonth(bsYear, bsMonth);
    final auspicious = auspiciousEventsForMonth(bsYear, bsMonth);

    // Compute AD date range for this BS month to fetch Google events
    final daysInMonth = NepaliDateService.getDaysInMonth(bsYear, bsMonth);
    final firstAd = NepaliDateService.bsToAd(NepaliDateService.fromBsDate(bsYear, bsMonth, 1));
    final lastAd = NepaliDateService.bsToAd(NepaliDateService.fromBsDate(bsYear, bsMonth, daysInMonth));

    final all = <CalendarEvent>[
      ...nepali,
      ...auspicious,
      ..._googleEventsForRange(firstAd, lastAd),
    ];
    all.sort((a, b) => a.startTime.compareTo(b.startTime));
    return all;
  }

  /// Get events for a specific AD date range (for day/week views).
  /// Converts the range to BS months, fetches Nepali events, adds Google, filters to range.
  List<CalendarEvent> eventsForAdRange(DateTime start, DateTime end) {
    // Convert start and end to BS to know which months to fetch
    final bsStart = NepaliDateService.adToBs(start);
    final bsEnd = NepaliDateService.adToBs(end);

    final all = <CalendarEvent>[];
    final visited = <String>{};

    // Iterate through all BS months in the range (Nepali + auspicious only, no Google — added below)
    var year = bsStart.year;
    var month = bsStart.month;
    while (year < bsEnd.year || (year == bsEnd.year && month <= bsEnd.month)) {
      final key = _monthKey(year, month);
      if (!visited.contains(key)) {
        visited.add(key);
        all.addAll(nepaliEventsForMonth(year, month));
        all.addAll(auspiciousEventsForMonth(year, month));
      }
      if (month == 12) {
        month = 1;
        year++;
      } else {
        month++;
      }
    }

    // Add Google events for the range
    all.addAll(_googleEventsForRange(start, end));

    // Filter to the actual AD date range
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final filtered = all.where((e) =>
        !e.startTime.isBefore(startDay) && !e.startTime.isAfter(endDay)).toList();
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  /// Get events for a specific AD date.
  List<CalendarEvent> eventsForAdDate(DateTime date) {
    return eventsForAdRange(date, date);
  }

  /// Check Nepali event data for a specific BS day.
  /// Returns raw data for backward compatibility with existing code.
  Map<int, NepaliDayInfo> nepaliDayInfoForMonth(int bsYear, int bsMonth) {
    if (_eventsData == null) return {};
    final key = _monthKey(bsYear, bsMonth);
    final monthData = _eventsData![key] as Map<String, dynamic>?;
    if (monthData == null) return {};

    final days = monthData['days'] as List<dynamic>?;
    if (days == null) return {};

    final result = <int, NepaliDayInfo>{};
    for (final dayJson in days) {
      final day = dayJson as Map<String, dynamic>;
      final dayNum = day['day'] as int;
      result[dayNum] = NepaliDayInfo(
        events: (day['events'] as List<dynamic>?)?.cast<String>() ?? [],
        eventsNp: (day['events_np'] as List<dynamic>?)?.cast<String>() ?? [],
        isHoliday: day['is_holiday'] as bool? ?? false,
      );
    }
    return result;
  }

  /// Get auspicious data for a BS month (raw).
  AuspiciousDayData? auspiciousDataForMonth(int bsYear, int bsMonth) {
    if (_auspiciousData == null) return null;
    final key = _monthKey(bsYear, bsMonth);
    final monthData = _auspiciousData![key] as Map<String, dynamic>?;
    if (monthData == null) return null;
    return AuspiciousDayData(
      bibahaLagan: (monthData['bibaha_lagan'] as List<dynamic>?)?.cast<int>() ?? [],
      bratabandha: (monthData['bratabandha'] as List<dynamic>?)?.cast<int>() ?? [],
      pasni: (monthData['pasni'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }
}

/// Raw Nepali day event info.
class NepaliDayInfo {
  final List<String> events;
  final List<String> eventsNp;
  final bool isHoliday;
  const NepaliDayInfo({required this.events, required this.eventsNp, required this.isHoliday});
}

/// Raw auspicious day data for a month.
class AuspiciousDayData {
  final List<int> bibahaLagan;
  final List<int> bratabandha;
  final List<int> pasni;
  const AuspiciousDayData({required this.bibahaLagan, required this.bratabandha, required this.pasni});

  bool hasAuspiciousDay(int day) =>
      bibahaLagan.contains(day) || bratabandha.contains(day) || pasni.contains(day);
}
