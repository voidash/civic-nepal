// Emits AD -> BS for every day in a range, using the same nepali_utils package
// the app depends on. The extension's JS conversion is diffed against this so
// the two can never drift apart.
//
// Run from flutter_app/:
//   dart run tool/dump_dart_bs.dart > /tmp/dart_bs.txt

import 'dart:io';
import 'package:nepali_utils/nepali_utils.dart';

void main() {
  var date = DateTime(1944, 1, 1);
  final end = DateTime(2090, 12, 31);

  while (!date.isAfter(end)) {
    final bs = date.toNepaliDateTime();
    final ad = '${date.year}-${date.month}-${date.day}';
    stdout.writeln('$ad ${bs.year}-${bs.month}-${bs.day}');
    date = DateTime(date.year, date.month, date.day + 1);
  }
}
