import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_view_state.dart';
import '../services/nepali_date_service.dart';
import '../services/calendar_event_merger.dart';
import '../services/google_calendar_service.dart';
import '../models/calendar_event.dart';
import 'google_auth_provider.dart';

part 'calendar_view_provider.g.dart';

// ── Singleton event merger ─────────────────────────────────────

final calendarEventMergerProvider = Provider<CalendarEventMerger>((ref) {
  return CalendarEventMerger();
});

// ── Event merger initialization (async) ────────────────────────

@riverpod
Future<void> calendarDataLoader(Ref ref) async {
  final merger = ref.read(calendarEventMergerProvider);
  await merger.loadNepaliData();
}

// ── View mode (day/week/month/year) ────────────────────────────

@riverpod
class CalendarViewModeNotifier extends _$CalendarViewModeNotifier {
  static const _prefKey = 'calendar_view_mode';

  @override
  CalendarViewMode build() {
    _loadSaved();
    return CalendarViewMode.month;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      final mode = CalendarViewMode.values.where((v) => v.name == saved).firstOrNull;
      if (mode != null) state = mode;
    }
  }

  Future<void> setMode(CalendarViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}

// ── Date system (AD/BS) ────────────────────────────────────────

@riverpod
class DateSystemNotifier extends _$DateSystemNotifier {
  static const _prefKey = 'calendar_date_system';

  @override
  DateSystem build() {
    _loadSaved();
    return DateSystem.bs;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      final sys = DateSystem.values.where((v) => v.name == saved).firstOrNull;
      if (sys != null) state = sys;
    }
  }

  Future<void> toggle() async {
    state = state == DateSystem.bs ? DateSystem.ad : DateSystem.bs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, state.name);
  }

  Future<void> setSystem(DateSystem system) async {
    state = system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, system.name);
  }
}

// ── Focused date (the date the user is currently viewing) ──────

@riverpod
class FocusedDateNotifier extends _$FocusedDateNotifier {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;

  void goToToday() => state = DateTime.now();

  /// Navigate by offset months (for month view navigation)
  void navigateMonths(int offset, {required DateSystem dateSystem}) {
    if (dateSystem == DateSystem.bs) {
      // Navigate in BS months
      final bs = NepaliDateService.adToBs(state);
      var newMonth = bs.month + offset;
      var newYear = bs.year;
      while (newMonth > 12) {
        newMonth -= 12;
        newYear++;
      }
      while (newMonth < 1) {
        newMonth += 12;
        newYear--;
      }
      final newBs = NepaliDateService.fromBsDate(newYear, newMonth, 1);
      state = NepaliDateService.bsToAd(newBs);
    } else {
      // Navigate in AD months
      var newMonth = state.month + offset;
      var newYear = state.year;
      while (newMonth > 12) {
        newMonth -= 12;
        newYear++;
      }
      while (newMonth < 1) {
        newMonth += 12;
        newYear--;
      }
      state = DateTime(newYear, newMonth, 1);
    }
  }

  /// Navigate by offset days (for day view navigation)
  void navigateDays(int offset) {
    state = state.add(Duration(days: offset));
  }

  /// Navigate by offset weeks (for week view navigation)
  void navigateWeeks(int offset) {
    state = state.add(Duration(days: 7 * offset));
  }

  /// Navigate by offset years (for year view navigation)
  void navigateYears(int offset, {required DateSystem dateSystem}) {
    if (dateSystem == DateSystem.bs) {
      final bs = NepaliDateService.adToBs(state);
      final newBs = NepaliDateService.fromBsDate(bs.year + offset, bs.month, 1);
      state = NepaliDateService.bsToAd(newBs);
    } else {
      state = DateTime(state.year + offset, state.month, 1);
    }
  }
}

// ── Selected day (tapped day for event detail) ─────────────────

@riverpod
class SelectedDayNotifier extends _$SelectedDayNotifier {
  @override
  DateTime? build() => null;

  void select(DateTime date) {
    if (state != null &&
        state!.year == date.year &&
        state!.month == date.month &&
        state!.day == date.day) {
      state = null; // Toggle off
    } else {
      state = date;
    }
  }

  void clear() => state = null;
}

// ── Events for current BS month (derived) ──────────────────────

@riverpod
List<CalendarEvent> currentMonthEvents(Ref ref) {
  // Ensure data is loaded
  ref.watch(calendarDataLoaderProvider);
  // Trigger Google sync when available
  ref.watch(googleCalendarSyncProvider);

  final merger = ref.read(calendarEventMergerProvider);
  final focused = ref.watch(focusedDateNotifierProvider);
  final bs = NepaliDateService.adToBs(focused);
  return merger.eventsForBsMonth(bs.year, bs.month);
}

// ── Enabled calendars (which Google calendars to show) ──────────

@riverpod
class EnabledCalendarsNotifier extends _$EnabledCalendarsNotifier {
  static const _prefKey = 'enabled_calendar_ids';

  @override
  Set<String> build() {
    _loadSaved();
    return {}; // Empty = show all (handled by merger)
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey);
    if (saved != null) {
      state = saved.toSet();
    }
  }

  Future<void> toggle(String calendarId) async {
    final newSet = Set<String>.from(state);
    if (newSet.contains(calendarId)) {
      newSet.remove(calendarId);
    } else {
      newSet.add(calendarId);
    }
    state = newSet;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, newSet.toList());

    // Update merger filter
    final merger = ref.read(calendarEventMergerProvider);
    merger.setEnabledCalendars(newSet.isEmpty ? null : newSet);
  }

  Future<void> enableAll(Iterable<String> ids) async {
    state = ids.toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, state.toList());
    final merger = ref.read(calendarEventMergerProvider);
    merger.setEnabledCalendars(null);
  }
}

// ── Google Calendar sync trigger ────────────────────────────────

/// Watches auth state and focused date, fetches Google events into the merger.
/// This is a "fire and forget" provider — views watch it to trigger sync.
@riverpod
Future<void> googleCalendarSync(Ref ref) async {
  final auth = ref.watch(googleAuthProvider);
  final focused = ref.watch(focusedDateNotifierProvider);
  final merger = ref.read(calendarEventMergerProvider);

  if (!auth.isSignedIn) {
    merger.clearGoogleEvents();
    return;
  }

  // Compute the visible date range (± 45 days around focused date for month transitions)
  final bs = NepaliDateService.adToBs(focused);
  final daysInMonth = NepaliDateService.getDaysInMonth(bs.year, bs.month);
  final firstDay = NepaliDateService.bsToAd(NepaliDateService.fromBsDate(bs.year, bs.month, 1));
  final lastDay = NepaliDateService.bsToAd(NepaliDateService.fromBsDate(bs.year, bs.month, daysInMonth));
  final start = firstDay.subtract(const Duration(days: 14));
  final end = lastDay.add(const Duration(days: 14));

  // Get enabled calendars
  final enabledIds = ref.read(enabledCalendarsNotifierProvider);

  try {
    final events = await GoogleCalendarService.instance.fetchEvents(
      start: start,
      end: end,
      calendarIds: enabledIds.isEmpty ? null : enabledIds,
    );
    merger.updateGoogleEvents(events);

    // Write cache for native menubar app (macOS/Windows only, not web)
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows)) {
      _writeGoogleEventCache(events, auth.email);
    }
  } catch (e) {
    // Silently fail — Nepali events still work
  }
}

/// Writes Google Calendar events to a shared JSON file that the native
/// menubar/tray app can read. Path: ~/Library/Application Support/NagarikPatro/
Future<void> _writeGoogleEventCache(List<CalendarEvent> events, String? email) async {
  try {
    final String cacheDir;
    if (Platform.isMacOS) {
      cacheDir = '${Platform.environment['HOME']}/Library/Application Support/NagarikPatro';
    } else {
      // Windows: %APPDATA%\NagarikPatro
      cacheDir = '${Platform.environment['APPDATA']}\\NagarikPatro';
    }
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final googleEvents = events.where((e) => e.source == CalendarEventSource.google).toList();

    final data = {
      'lastSynced': DateTime.now().toUtc().toIso8601String(),
      'userEmail': email,
      'events': googleEvents.map((e) => {
        'id': e.id,
        'title': e.title,
        'startTime': e.startTime.toUtc().toIso8601String(),
        'endTime': e.endTime?.toUtc().toIso8601String(),
        'isAllDay': e.isAllDay,
        'calendarId': e.calendarId,
        'colorHex': e.color != null
            ? '#${(e.color!.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
            : '#4285F4',
        'location': e.location,
        'description': e.description,
      }).toList(),
    };

    final file = File('$cacheDir/google_calendar_cache.json');
    await file.writeAsString(jsonEncode(data));
  } catch (_) {
    // Cache write failure is non-critical
  }
}

// ── Draft event (provisional block shown while creating) ────────

/// Holds a temporary "draft" event displayed on the timeline while the
/// event editor is open.  Cleared on save or cancel.
final draftEventProvider = StateProvider<CalendarEvent?>((ref) => null);

// ── Google calendar list (for UI selector) ──────────────────────

@riverpod
Map<String, CalendarMeta> googleCalendarList(Ref ref) {
  // Re-evaluate when auth changes
  ref.watch(googleAuthProvider);
  return GoogleCalendarService.instance.calendars;
}
