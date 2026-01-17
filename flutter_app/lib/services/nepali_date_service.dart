/// Nepali Bikram Sambat (BS) calendar service
/// Uses nepali_utils package for accurate conversions
library;

import 'dart:async';
import 'package:nepali_utils/nepali_utils.dart';

export 'package:nepali_utils/nepali_utils.dart' show NepaliDateTime, Language;

/// Wrapper service for Nepali date operations
class NepaliDateService {
  /// Get today's date in BS
  static NepaliDateTime today() {
    return NepaliDateTime.now();
  }

  /// Convert AD date to BS date
  static NepaliDateTime adToBs(DateTime ad) {
    return NepaliDateTime.fromDateTime(ad);
  }

  /// Convert BS date to AD date
  static DateTime bsToAd(NepaliDateTime bs) {
    return bs.toDateTime();
  }

  /// Create a NepaliDateTime from year, month, day
  static NepaliDateTime fromBsDate(int year, int month, int day) {
    return NepaliDateTime(year, month, day);
  }

  /// Get days in a specific BS month
  static int getDaysInMonth(int year, int month) {
    return NepaliDateTime(year, month).totalDays;
  }

  /// Validate if a BS date is valid
  static bool isValidBsDate(int year, int month, int day) {
    try {
      if (month < 1 || month > 12) return false;
      if (day < 1) return false;
      final daysInMonth = NepaliDateTime(year, month).totalDays;
      return day <= daysInMonth;
    } catch (e) {
      return false;
    }
  }

  /// Format date in Nepali
  static String formatNp(NepaliDateTime date) {
    return date.format('dd MMMM, yyyy', Language.nepali);
  }

  /// Format date in English
  static String formatEn(NepaliDateTime date) {
    return date.format('dd MMMM, yyyy', Language.english);
  }

  /// Format date short in Nepali
  static String formatShortNp(NepaliDateTime date) {
    return date.format('dd MMMM', Language.nepali);
  }

  /// Format date short in English
  static String formatShortEn(NepaliDateTime date) {
    return date.format('dd MMMM', Language.english);
  }

  /// Get weekday name in Nepali
  static String getWeekdayNp(NepaliDateTime date) {
    return date.format('EEE', Language.nepali);
  }

  /// Get weekday name in English
  static String getWeekdayEn(NepaliDateTime date) {
    return date.format('EEE', Language.english);
  }

  /// Get weekday short name in Nepali
  static String getWeekdayShortNp(NepaliDateTime date) {
    return date.format('EEE', Language.nepali);
  }

  /// Get month name in Nepali
  static String getMonthNameNp(int month) {
    final date = NepaliDateTime(2080, month);
    return date.format('MMMM', Language.nepali);
  }

  /// Get month name in English
  static String getMonthNameEn(int month) {
    final date = NepaliDateTime(2080, month);
    return date.format('MMMM', Language.english);
  }

  /// Get supported year range (approximate)
  static (int, int) get supportedYearRange => (1970, 2100);
}

/// Nepali month names for reference
class NepaliMonth {
  static const List<String> names = [
    'Baisakh', 'Jestha', 'Ashadh', 'Shrawan',
    'Bhadra', 'Ashwin', 'Kartik', 'Mangsir',
    'Poush', 'Magh', 'Falgun', 'Chaitra',
  ];

  static const List<String> namesNp = [
    'बैशाख', 'जेठ', 'असार', 'श्रावण',
    'भाद्र', 'आश्विन', 'कार्तिक', 'मंसिर',
    'पौष', 'माघ', 'फागुन', 'चैत्र',
  ];
}

/// A timer that fires at the next midnight
class MidnightTimer {
  Timer? _timer;
  final void Function() onMidnight;

  MidnightTimer({required this.onMidnight}) {
    _scheduleNextMidnight();
  }

  void _scheduleNextMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);

    _timer = Timer(duration, () {
      onMidnight();
      _scheduleNextMidnight();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
