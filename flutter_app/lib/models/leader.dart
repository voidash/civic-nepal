import 'package:freezed_annotation/freezed_annotation.dart';

part 'leader.freezed.dart';
part 'leader.g.dart';

@freezed
class LeadersData with _$LeadersData {
  const factory LeadersData({
    required String version,
    required int count,
    required List<Leader> leaders,
  }) = _LeadersData;

  factory LeadersData.fromJson(Map<String, dynamic> json) =>
      _$LeadersDataFromJson(json);
}

@freezed
class Leader with _$Leader {
  const factory Leader({
    required String id,
    required String name,
    required String party,
    required String position,
    required String? district,
    required String biography,
    required String imageUrl,
    @Default(false) bool featured,
    required int upvotes,
    required int downvotes,
    required int totalVotes,
  }) = _Leader;

  factory Leader.fromJson(Map<String, dynamic> json) => _$LeaderFromJson(json);
}
