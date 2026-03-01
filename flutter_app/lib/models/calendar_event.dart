import 'package:flutter/material.dart';

/// Source of a calendar event
enum CalendarEventSource { nepali, google, local }

/// Type of auspicious day
enum AuspiciousType { wedding, bratabandha, pasni }

/// Unified calendar event model for both Nepali events and Google Calendar events.
/// Not using freezed here — this is a simple value class and freezed adds
/// code-gen overhead for no benefit when there's no JSON serialization needed.
class CalendarEvent {
  final String id;
  final String title;
  final String? titleNp;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final CalendarEventSource source;
  final String? calendarId;
  final Color? color;
  final String? location;
  final String? description;
  final bool isHoliday;
  final AuspiciousType? auspiciousType;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.titleNp,
    required this.startTime,
    this.endTime,
    required this.isAllDay,
    required this.source,
    this.calendarId,
    this.color,
    this.location,
    this.description,
    this.isHoliday = false,
    this.auspiciousType,
  });

  /// Get localized title
  String localizedTitle(bool isNepali) {
    if (isNepali && titleNp != null) return titleNp!;
    return title;
  }

  /// Duration of the event (null for all-day events without end time)
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}
