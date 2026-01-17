import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/constitution.dart';
import '../models/leader.dart';
import '../models/district.dart';
import '../models/know_your_rights.dart';
import 'remote_data_service.dart';

/// Service for loading JSON data from assets
///
/// For files that support remote updates (ministers, calendar, leaders, gov_services),
/// the service will check for cached remote data and use it if available.
class DataService {
  /// Load constitution data from assets
  static Future<ConstitutionData> loadConstitution() async {
    final jsonString = await rootBundle.loadString('assets/data/constitution_bilingual.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final wrapper = ConstitutionWrapper.fromJson(json);
    return wrapper.constitution;
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

  /// Load leaders data (supports remote updates)
  static Future<LeadersData> loadLeaders() async {
    final json = await RemoteDataService.loadJson('leaders.json');
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

  /// Load Know Your Rights data from assets
  static Future<KnowYourRightsData> loadKnowYourRights() async {
    final jsonString = await rootBundle.loadString('assets/data/know_your_rights.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return KnowYourRightsData.fromJson(json);
  }

  /// Load calendar events data (supports remote updates)
  static Future<Map<String, dynamic>> loadCalendarEvents() async {
    return RemoteDataService.loadJson('nepali_calendar_events.json');
  }

  /// Load auspicious days data (supports remote updates)
  static Future<Map<String, dynamic>> loadAuspiciousDays() async {
    return RemoteDataService.loadJson('nepali_calendar_auspicious.json');
  }

  /// Load ministers/government data (supports remote updates)
  static Future<Map<String, dynamic>> loadMinisters() async {
    return RemoteDataService.loadJson('ministers.json');
  }

  /// Load government services data (supports remote updates)
  static Future<Map<String, dynamic>> loadGovServices() async {
    return RemoteDataService.loadJson('gov_services.json');
  }
}
