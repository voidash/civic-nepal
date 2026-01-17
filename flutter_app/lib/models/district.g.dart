// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'district.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DistrictInfoImpl _$$DistrictInfoImplFromJson(Map<String, dynamic> json) =>
    _$DistrictInfoImpl(
      name: json['name'] as String,
      province: (json['province'] as num).toInt(),
      nameNp: json['nameNp'] as String?,
      headquarters: json['headquarters'] as String?,
      population: (json['population'] as num?)?.toInt(),
      area: (json['area'] as num?)?.toInt(),
      wikiUrl: json['wikiUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      famousFor: json['famousFor'] as String?,
    );

Map<String, dynamic> _$$DistrictInfoImplToJson(_$DistrictInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'province': instance.province,
      'nameNp': instance.nameNp,
      'headquarters': instance.headquarters,
      'population': instance.population,
      'area': instance.area,
      'wikiUrl': instance.wikiUrl,
      'websiteUrl': instance.websiteUrl,
      'famousFor': instance.famousFor,
    };

_$PartyDataImpl _$$PartyDataImplFromJson(Map<String, dynamic> json) =>
    _$PartyDataImpl(
      version: json['version'] as String,
      count: (json['count'] as num).toInt(),
      parties: (json['parties'] as List<dynamic>)
          .map((e) => Party.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PartyDataImplToJson(_$PartyDataImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'count': instance.count,
      'parties': instance.parties,
    };

_$PartyImpl _$$PartyImplFromJson(Map<String, dynamic> json) => _$PartyImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      color: json['color'] as String,
      leaderCount: (json['leaderCount'] as num).toInt(),
    );

Map<String, dynamic> _$$PartyImplToJson(_$PartyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'shortName': instance.shortName,
      'color': instance.color,
      'leaderCount': instance.leaderCount,
    };
