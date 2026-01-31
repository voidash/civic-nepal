import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/osm_data.dart';

part 'osm_provider.g.dart';

/// Nepal geographic bounds
class NepalBounds {
  static const double minLat = 26.3;
  static const double maxLat = 30.5;
  static const double minLon = 80.0;
  static const double maxLon = 88.2;

  // SVG canvas size (from nepal_districts.svg)
  static const double svgWidth = 1225.0;
  static const double svgHeight = 817.0;

  /// Convert lat/lon to SVG coordinates
  /// Note: This is an approximation - actual SVG may use different projection
  static (double x, double y) latLonToSvg(double lat, double lon) {
    // Normalize to 0-1 range
    final normalizedLon = (lon - minLon) / (maxLon - minLon);
    final normalizedLat = (lat - minLat) / (maxLat - minLat);

    // Convert to SVG coordinates (Y is inverted)
    final x = normalizedLon * svgWidth;
    final y = (1 - normalizedLat) * svgHeight;

    return (x, y);
  }
}

/// Provider for schools data
@Riverpod(keepAlive: true)
Future<OsmPointData> schools(SchoolsRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/osm/schools.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return OsmPointData.fromJson(json);
}

/// Provider for colleges data
@Riverpod(keepAlive: true)
Future<OsmPointData> colleges(CollegesRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/osm/colleges.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return OsmPointData.fromJson(json);
}

/// Provider for government offices data
@Riverpod(keepAlive: true)
Future<OsmPointData> government(GovernmentRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/osm/government.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return OsmPointData.fromJson(json);
}

/// Provider for roads data
@Riverpod(keepAlive: true)
Future<OsmRoadData> roads(RoadsRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/osm/roads.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return OsmRoadData.fromJson(json);
}

/// Provider for religious sites data
@Riverpod(keepAlive: true)
Future<List<ReligiousPoint>> religiousSites(ReligiousSitesRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/osm/religious.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final points = json['points'] as List<dynamic>;
  return points.map((p) => ReligiousPoint.fromJson(p as Map<String, dynamic>)).toList();
}

/// Provider for police stations data
@Riverpod(keepAlive: true)
Future<List<PolicePoint>> policeStations(PoliceStationsRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/osm/police.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final points = json['points'] as List<dynamic>;
  return points.map((p) => PolicePoint.fromJson(p as Map<String, dynamic>)).toList();
}

/// Provider for trekking spots data
@Riverpod(keepAlive: true)
Future<List<TrekkingPoint>> trekkingSpots(TrekkingSpotsRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/osm/trekking.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final points = json['points'] as List<dynamic>;
  return points.map((p) => TrekkingPoint.fromJson(p as Map<String, dynamic>)).toList();
}

/// Map layer state provider
@riverpod
class MapLayers extends _$MapLayers {
  @override
  MapLayerState build() => const MapLayerState();

  void toggleRoads() {
    state = state.copyWith(showRoads: !state.showRoads);
  }

  void toggleSchools() {
    state = state.copyWith(showSchools: !state.showSchools);
  }

  void toggleColleges() {
    state = state.copyWith(showColleges: !state.showColleges);
  }

  void toggleGovernment() {
    state = state.copyWith(showGovernment: !state.showGovernment);
  }

  void toggleReligious() {
    state = state.copyWith(showReligious: !state.showReligious);
  }

  void togglePolice() {
    state = state.copyWith(showPolice: !state.showPolice);
  }

  void toggleTrekking() {
    state = state.copyWith(showTrekking: !state.showTrekking);
  }

  void toggleTrunk() {
    state = state.copyWith(showTrunk: !state.showTrunk);
  }

  void togglePrimary() {
    state = state.copyWith(showPrimary: !state.showPrimary);
  }

  void toggleSecondary() {
    state = state.copyWith(showSecondary: !state.showSecondary);
  }

  void showAll() {
    state = const MapLayerState(
      showRoads: true,
      showSchools: true,
      showColleges: true,
      showGovernment: true,
      showReligious: true,
      showPolice: true,
      showTrekking: true,
    );
  }

  void hideAll() {
    state = const MapLayerState();
  }
}
