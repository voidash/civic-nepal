// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leader.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeadersDataImpl _$$LeadersDataImplFromJson(Map<String, dynamic> json) =>
    _$LeadersDataImpl(
      version: json['version'] as String,
      count: (json['count'] as num).toInt(),
      leaders: (json['leaders'] as List<dynamic>)
          .map((e) => Leader.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LeadersDataImplToJson(_$LeadersDataImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'count': instance.count,
      'leaders': instance.leaders,
    };

_$LeaderImpl _$$LeaderImplFromJson(Map<String, dynamic> json) => _$LeaderImpl(
      id: json['_id'] as String,
      name: json['name'] as String,
      party: json['party'] as String,
      position: json['position'] as String,
      district: json['district'] as String?,
      biography: json['biography'] as String,
      imageUrl: json['imageUrl'] as String,
      featured: json['featured'] as bool? ?? false,
      upvotes: (json['upvotes'] as num).toInt(),
      downvotes: (json['downvotes'] as num).toInt(),
      totalVotes: (json['totalVotes'] as num).toInt(),
    );

Map<String, dynamic> _$$LeaderImplToJson(_$LeaderImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'party': instance.party,
      'position': instance.position,
      'district': instance.district,
      'biography': instance.biography,
      'imageUrl': instance.imageUrl,
      'featured': instance.featured,
      'upvotes': instance.upvotes,
      'downvotes': instance.downvotes,
      'totalVotes': instance.totalVotes,
    };
