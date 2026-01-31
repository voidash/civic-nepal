import 'package:json_annotation/json_annotation.dart';

part 'osm_data.g.dart';

/// A point of interest (school, college, government office)
@JsonSerializable()
class OsmPoint {
  final int id;
  final double lat;
  final double lon;
  final String name;
  final String? type;
  final String? operator;
  @JsonKey(name: 'admin_level')
  final String? adminLevel;

  const OsmPoint({
    required this.id,
    required this.lat,
    required this.lon,
    required this.name,
    this.type,
    this.operator,
    this.adminLevel,
  });

  factory OsmPoint.fromJson(Map<String, dynamic> json) =>
      _$OsmPointFromJson(json);
  Map<String, dynamic> toJson() => _$OsmPointToJson(this);
}

/// A religious site (temple, monastery, church, mosque)
@JsonSerializable()
class ReligiousPoint {
  final double lat;
  final double lon;
  final String name;
  final String religion;
  final String? denomination;

  const ReligiousPoint({
    required this.lat,
    required this.lon,
    required this.name,
    required this.religion,
    this.denomination,
  });

  factory ReligiousPoint.fromJson(Map<String, dynamic> json) =>
      _$ReligiousPointFromJson(json);
  Map<String, dynamic> toJson() => _$ReligiousPointToJson(this);
}

/// A police station
@JsonSerializable()
class PolicePoint {
  final double lat;
  final double lon;
  final String name;
  final String? phone;

  const PolicePoint({
    required this.lat,
    required this.lon,
    required this.name,
    this.phone,
  });

  factory PolicePoint.fromJson(Map<String, dynamic> json) =>
      _$PolicePointFromJson(json);
  Map<String, dynamic> toJson() => _$PolicePointToJson(this);
}

/// A trekking spot (peak, viewpoint, campsite, alpine hut, mountain pass)
@JsonSerializable()
class TrekkingPoint {
  final double lat;
  final double lon;
  final String name;
  final String type; // peak, viewpoint, campsite, alpine_hut, pass, guidepost
  final String? elevation;

  const TrekkingPoint({
    required this.lat,
    required this.lon,
    required this.name,
    required this.type,
    this.elevation,
  });

  factory TrekkingPoint.fromJson(Map<String, dynamic> json) =>
      _$TrekkingPointFromJson(json);
  Map<String, dynamic> toJson() => _$TrekkingPointToJson(this);
}

/// Collection of OSM points
@JsonSerializable()
class OsmPointData {
  final String type;
  final int count;
  final String source;
  final String timestamp;
  final List<OsmPoint> items;

  const OsmPointData({
    required this.type,
    required this.count,
    required this.source,
    required this.timestamp,
    required this.items,
  });

  factory OsmPointData.fromJson(Map<String, dynamic> json) =>
      _$OsmPointDataFromJson(json);
  Map<String, dynamic> toJson() => _$OsmPointDataToJson(this);
}

/// A road segment
@JsonSerializable()
class OsmRoad {
  final int id;
  final String name;
  final String ref;
  final List<List<double>> coords;

  const OsmRoad({
    required this.id,
    required this.name,
    required this.ref,
    required this.coords,
  });

  factory OsmRoad.fromJson(Map<String, dynamic> json) =>
      _$OsmRoadFromJson(json);
  Map<String, dynamic> toJson() => _$OsmRoadToJson(this);
}

/// Road statistics
@JsonSerializable()
class RoadStats {
  @JsonKey(name: 'total_roads')
  final int totalRoads;
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @JsonKey(name: 'by_type')
  final Map<String, int> byType;

  const RoadStats({
    required this.totalRoads,
    required this.totalPoints,
    required this.byType,
  });

  factory RoadStats.fromJson(Map<String, dynamic> json) =>
      _$RoadStatsFromJson(json);
  Map<String, dynamic> toJson() => _$RoadStatsToJson(this);
}

/// Collection of OSM roads
@JsonSerializable()
class OsmRoadData {
  final String type;
  final String source;
  final String timestamp;
  final RoadStats stats;
  final Map<String, List<OsmRoad>> roads;

  const OsmRoadData({
    required this.type,
    required this.source,
    required this.timestamp,
    required this.stats,
    required this.roads,
  });

  factory OsmRoadData.fromJson(Map<String, dynamic> json) =>
      _$OsmRoadDataFromJson(json);
  Map<String, dynamic> toJson() => _$OsmRoadDataToJson(this);
}

/// Map layer visibility state
class MapLayerState {
  final bool showRoads;
  final bool showSchools;
  final bool showColleges;
  final bool showGovernment;
  final bool showReligious;
  final bool showPolice;
  final bool showTrekking;
  final bool showTrunk;
  final bool showPrimary;
  final bool showSecondary;

  const MapLayerState({
    this.showRoads = false,
    this.showSchools = false,
    this.showColleges = false,
    this.showGovernment = false,
    this.showReligious = false,
    this.showPolice = false,
    this.showTrekking = false,
    this.showTrunk = true,
    this.showPrimary = true,
    this.showSecondary = false,
  });

  MapLayerState copyWith({
    bool? showRoads,
    bool? showSchools,
    bool? showColleges,
    bool? showGovernment,
    bool? showReligious,
    bool? showPolice,
    bool? showTrekking,
    bool? showTrunk,
    bool? showPrimary,
    bool? showSecondary,
  }) {
    return MapLayerState(
      showRoads: showRoads ?? this.showRoads,
      showSchools: showSchools ?? this.showSchools,
      showColleges: showColleges ?? this.showColleges,
      showGovernment: showGovernment ?? this.showGovernment,
      showReligious: showReligious ?? this.showReligious,
      showPolice: showPolice ?? this.showPolice,
      showTrekking: showTrekking ?? this.showTrekking,
      showTrunk: showTrunk ?? this.showTrunk,
      showPrimary: showPrimary ?? this.showPrimary,
      showSecondary: showSecondary ?? this.showSecondary,
    );
  }

  bool get hasAnyLayer =>
      showRoads || showSchools || showColleges || showGovernment ||
      showReligious || showPolice || showTrekking;
}
