import '../l10n/app_localizations.dart';

/// Calendar day info with events (bilingual support).
///
/// Parsed from `assets/data/nepali_calendar_events.json`.
class CalendarDayInfo {
  final int day;
  final List<String> events; // English events
  final List<String> eventsNp; // Nepali events
  final bool isHoliday;

  CalendarDayInfo({
    required this.day,
    required this.events,
    required this.eventsNp,
    required this.isHoliday,
  });

  factory CalendarDayInfo.fromJson(Map<String, dynamic> json) {
    final events = (json['events'] as List<dynamic>).cast<String>();
    // Use events_np if available, otherwise fallback to events
    final eventsNp = json['events_np'] != null
        ? (json['events_np'] as List<dynamic>).cast<String>()
        : events;
    return CalendarDayInfo(
      day: json['day'] as int,
      events: events,
      eventsNp: eventsNp,
      isHoliday: json['is_holiday'] as bool? ?? false,
    );
  }

  /// Get events based on locale
  List<String> getLocalizedEvents(bool isNepali) {
    return isNepali ? eventsNp : events;
  }
}

/// Auspicious days info for a Bikram Sambat month.
///
/// Parsed from `assets/data/nepali_calendar_auspicious.json`.
class AuspiciousDaysInfo {
  final List<int> bibahaLagan;
  final List<int> bratabandha;
  final List<int> pasni;

  AuspiciousDaysInfo({
    required this.bibahaLagan,
    required this.bratabandha,
    required this.pasni,
  });

  factory AuspiciousDaysInfo.fromJson(Map<String, dynamic> json) {
    return AuspiciousDaysInfo(
      bibahaLagan: (json['bibaha_lagan'] as List<dynamic>?)?.cast<int>() ?? [],
      bratabandha: (json['bratabandha'] as List<dynamic>?)?.cast<int>() ?? [],
      pasni: (json['pasni'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  bool hasAuspiciousDay(int day) {
    return bibahaLagan.contains(day) ||
        bratabandha.contains(day) ||
        pasni.contains(day);
  }

  List<String> getAuspiciousTypes(int day, AppLocalizations l10n) {
    final types = <String>[];
    if (bibahaLagan.contains(day)) types.add(l10n.weddingAuspicious);
    if (bratabandha.contains(day)) types.add(l10n.bratabandhaAuspicious);
    if (pasni.contains(day)) types.add(l10n.pasniAuspicious);
    return types;
  }
}
