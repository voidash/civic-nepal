import 'package:freezed_annotation/freezed_annotation.dart';

part 'constituency.freezed.dart';
part 'constituency.g.dart';

/// Top-level constituency data container
@freezed
class ConstituencyData with _$ConstituencyData {
  const factory ConstituencyData({
    required String version,
    required String source,
    @JsonKey(name: 'scraped_at') required String scrapedAt,
    required int totalConstituencies,
    required Map<String, List<Constituency>> districts,
  }) = _ConstituencyData;

  factory ConstituencyData.fromJson(Map<String, dynamic> json) =>
      _$ConstituencyDataFromJson(json);
}

/// Federal election constituency
@freezed
class Constituency with _$Constituency {
  const factory Constituency({
    required String id,
    required String name,
    required int number,
    required String district,
    required String districtId,
    required int province,
    required List<Candidate> candidates,
    @Default('') String svgPathId,
    @Default('') String svgPathD,
  }) = _Constituency;

  factory Constituency.fromJson(Map<String, dynamic> json) =>
      _$ConstituencyFromJson(json);
}

/// Election candidate
@freezed
class Candidate with _$Candidate {
  const factory Candidate({
    required String id,
    required String name,
    required String party,
    @Default('') String partySymbol,
    @Default('') String imageUrl,
    @Default(0) int votes,
  }) = _Candidate;

  factory Candidate.fromJson(Map<String, dynamic> json) =>
      _$CandidateFromJson(json);
}
