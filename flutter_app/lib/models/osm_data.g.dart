// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OsmPoint _$OsmPointFromJson(Map<String, dynamic> json) => OsmPoint(
      id: (json['id'] as num).toInt(),
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      name: json['name'] as String,
      type: json['type'] as String?,
      operator: json['operator'] as String?,
      adminLevel: json['admin_level'] as String?,
    );

Map<String, dynamic> _$OsmPointToJson(OsmPoint instance) => <String, dynamic>{
      'id': instance.id,
      'lat': instance.lat,
      'lon': instance.lon,
      'name': instance.name,
      'type': instance.type,
      'operator': instance.operator,
      'admin_level': instance.adminLevel,
    };

ReligiousPoint _$ReligiousPointFromJson(Map<String, dynamic> json) =>
    ReligiousPoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      name: json['name'] as String,
      religion: json['religion'] as String,
      denomination: json['denomination'] as String?,
    );

Map<String, dynamic> _$ReligiousPointToJson(ReligiousPoint instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
      'name': instance.name,
      'religion': instance.religion,
      'denomination': instance.denomination,
    };

PolicePoint _$PolicePointFromJson(Map<String, dynamic> json) => PolicePoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$PolicePointToJson(PolicePoint instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
      'name': instance.name,
      'phone': instance.phone,
    };

TrekkingPoint _$TrekkingPointFromJson(Map<String, dynamic> json) =>
    TrekkingPoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      name: json['name'] as String,
      type: json['type'] as String,
      elevation: json['elevation'] as String?,
    );

Map<String, dynamic> _$TrekkingPointToJson(TrekkingPoint instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
      'name': instance.name,
      'type': instance.type,
      'elevation': instance.elevation,
    };

OsmPointData _$OsmPointDataFromJson(Map<String, dynamic> json) => OsmPointData(
      type: json['type'] as String,
      count: (json['count'] as num).toInt(),
      source: json['source'] as String,
      timestamp: json['timestamp'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => OsmPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OsmPointDataToJson(OsmPointData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'count': instance.count,
      'source': instance.source,
      'timestamp': instance.timestamp,
      'items': instance.items,
    };

OsmRoad _$OsmRoadFromJson(Map<String, dynamic> json) => OsmRoad(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      ref: json['ref'] as String,
      coords: (json['coords'] as List<dynamic>)
          .map((e) =>
              (e as List<dynamic>).map((e) => (e as num).toDouble()).toList())
          .toList(),
    );

Map<String, dynamic> _$OsmRoadToJson(OsmRoad instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'ref': instance.ref,
      'coords': instance.coords,
    };

RoadStats _$RoadStatsFromJson(Map<String, dynamic> json) => RoadStats(
      totalRoads: (json['total_roads'] as num).toInt(),
      totalPoints: (json['total_points'] as num).toInt(),
      byType: Map<String, int>.from(json['by_type'] as Map),
    );

Map<String, dynamic> _$RoadStatsToJson(RoadStats instance) => <String, dynamic>{
      'total_roads': instance.totalRoads,
      'total_points': instance.totalPoints,
      'by_type': instance.byType,
    };

OsmRoadData _$OsmRoadDataFromJson(Map<String, dynamic> json) => OsmRoadData(
      type: json['type'] as String,
      source: json['source'] as String,
      timestamp: json['timestamp'] as String,
      stats: RoadStats.fromJson(json['stats'] as Map<String, dynamic>),
      roads: (json['roads'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => OsmRoad.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
    );

Map<String, dynamic> _$OsmRoadDataToJson(OsmRoadData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'source': instance.source,
      'timestamp': instance.timestamp,
      'stats': instance.stats,
      'roads': instance.roads,
    };
