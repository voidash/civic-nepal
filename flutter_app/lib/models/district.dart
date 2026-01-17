import 'package:freezed_annotation/freezed_annotation.dart';

part 'district.freezed.dart';
part 'district.g.dart';

// DistrictData is a Map<String, DistrictInfo> at the top level
// The fromJson factory expects the raw JSON object
@freezed
class DistrictData with _$DistrictData {
  const factory DistrictData({
    required Map<String, DistrictInfo> districts,
  }) = _DistrictData;

  factory DistrictData.fromJson(Map<String, dynamic> json) {
    return DistrictData(
      districts: json.map(
        (key, value) => MapEntry(
          key,
          DistrictInfo.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

@freezed
class DistrictInfo with _$DistrictInfo {
  const factory DistrictInfo({
    required String name,
    required int province,
  }) = _DistrictInfo;

  factory DistrictInfo.fromJson(Map<String, dynamic> json) =>
      _$DistrictInfoFromJson(json);
}

@freezed
class PartyData with _$PartyData {
  const factory PartyData({
    required String version,
    required int count,
    required List<Party> parties,
  }) = _PartyData;

  factory PartyData.fromJson(Map<String, dynamic> json) =>
      _$PartyDataFromJson(json);
}

@freezed
class Party with _$Party {
  const factory Party({
    required String id,
    required String name,
    required String shortName,
    required String color,
    required int leaderCount,
  }) = _Party;

  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);
}
