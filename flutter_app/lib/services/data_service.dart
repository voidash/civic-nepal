import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/constitution.dart';
import '../models/leader.dart';
import '../models/district.dart';

/// Service for loading JSON data from assets
class DataService {
  /// Load constitution data from assets
  static Future<Constitution> loadConstitution() async {
    final jsonString = await rootBundle.loadString('assets/data/constitution_bilingual.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Constitution.fromJson(json);
  }

  /// Load per-sentence aligned data from assets
  static Future<Map<String, dynamic>> loadPerSentenceData() async {
    final jsonString = await rootBundle.loadString('assets/data/per-sentence.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Load dictionary data from assets
  static Future<Map<String, dynamic>> loadDictionary() async {
    final jsonString = await rootBundle.loadString('assets/data/dictionary.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Load leaders data from assets
  static Future<LeadersData> loadLeaders() async {
    final jsonString = await rootBundle.loadString('assets/data/leaders.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return LeadersData.fromJson(json);
  }

  /// Load parties data from assets
  static Future<PartyData> loadParties() async {
    final jsonString = await rootBundle.loadString('assets/data/parties.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PartyData.fromJson(json);
  }

  /// Load districts data from assets
  static Future<DistrictData> loadDistricts() async {
    final jsonString = await rootBundle.loadString('assets/data/districts.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DistrictData.fromJson(json);
  }

  /// Load SVG map string from assets
  static Future<String> loadNepalMapSvg() async {
    return await rootBundle.loadString('assets/images/nepal_districts.svg');
  }
}
