// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constituency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConstituencyDataImpl _$$ConstituencyDataImplFromJson(
        Map<String, dynamic> json) =>
    _$ConstituencyDataImpl(
      version: json['version'] as String,
      source: json['source'] as String,
      scrapedAt: json['scraped_at'] as String,
      totalConstituencies: (json['totalConstituencies'] as num).toInt(),
      districts: (json['districts'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => Constituency.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
    );

Map<String, dynamic> _$$ConstituencyDataImplToJson(
        _$ConstituencyDataImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'source': instance.source,
      'scraped_at': instance.scrapedAt,
      'totalConstituencies': instance.totalConstituencies,
      'districts': instance.districts,
    };

_$ConstituencyImpl _$$ConstituencyImplFromJson(Map<String, dynamic> json) =>
    _$ConstituencyImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      number: (json['number'] as num).toInt(),
      district: json['district'] as String,
      districtId: json['districtId'] as String,
      province: (json['province'] as num).toInt(),
      candidates: (json['candidates'] as List<dynamic>)
          .map((e) => Candidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      svgPathId: json['svgPathId'] as String? ?? '',
      svgPathD: json['svgPathD'] as String? ?? '',
    );

Map<String, dynamic> _$$ConstituencyImplToJson(_$ConstituencyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'number': instance.number,
      'district': instance.district,
      'districtId': instance.districtId,
      'province': instance.province,
      'candidates': instance.candidates,
      'svgPathId': instance.svgPathId,
      'svgPathD': instance.svgPathD,
    };

_$CandidateImpl _$$CandidateImplFromJson(Map<String, dynamic> json) =>
    _$CandidateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      party: json['party'] as String,
      partySymbol: json['partySymbol'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$CandidateImplToJson(_$CandidateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'party': instance.party,
      'partySymbol': instance.partySymbol,
      'imageUrl': instance.imageUrl,
      'votes': instance.votes,
    };
