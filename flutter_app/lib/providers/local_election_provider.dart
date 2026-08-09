import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_election_provider.g.dart';

// Models and providers for the 2079 local election results.
//
// These used to live inside screens/map/local_body_screen.dart, a pre-GeoJSON
// map screen no route could reach. The screen is gone; this data is still used
// by GeoLocalBodyScreen.

/// Local election results data model
class LocalElectionData {
  final String version;
  final int totalLocalBodies;
  final List<LocalBodyResult> localBodies;

  LocalElectionData({
    required this.version,
    required this.totalLocalBodies,
    required this.localBodies,
  });

  factory LocalElectionData.fromJson(Map<String, dynamic> json) {
    return LocalElectionData(
      version: json['version'] ?? '',
      totalLocalBodies: json['totalLocalBodies'] ?? 0,
      localBodies: (json['localBodies'] as List?)
              ?.map((e) => LocalBodyResult.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LocalBodyResult {
  final String id;
  final String locId;
  final String name;
  final String nameNp;
  final String district;
  final int province;
  final String type;
  final List<ElectedOfficial> officials;

  LocalBodyResult({
    required this.id,
    required this.locId,
    required this.name,
    required this.nameNp,
    required this.district,
    required this.province,
    required this.type,
    required this.officials,
  });

  factory LocalBodyResult.fromJson(Map<String, dynamic> json) {
    return LocalBodyResult(
      id: json['id'] ?? '',
      locId: json['locId'] ?? '',
      name: json['name'] ?? '',
      nameNp: json['nameNp'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? 0,
      type: json['type'] ?? '',
      officials: (json['officials'] as List?)
              ?.map((e) => ElectedOfficial.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ElectedOfficial {
  final String name;
  final String nameNp;
  final String position;
  final String party;
  final int votes;
  final String imageUrl;
  final String partySymbol;

  ElectedOfficial({
    required this.name,
    required this.nameNp,
    required this.position,
    required this.party,
    required this.votes,
    required this.imageUrl,
    required this.partySymbol,
  });

  factory ElectedOfficial.fromJson(Map<String, dynamic> json) {
    return ElectedOfficial(
      name: json['name'] ?? '',
      nameNp: json['nameNp'] ?? '',
      position: json['position'] ?? '',
      party: json['party'] ?? '',
      votes: json['votes'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      partySymbol: json['partySymbol'] ?? '',
    );
  }
}

/// Provider for local election results
@riverpod
Future<LocalElectionData> localElectionResults(LocalElectionResultsRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/election/local_election_results.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return LocalElectionData.fromJson(json);
}

/// Provider for local bodies in a specific district
@riverpod
List<LocalBodyResult> localBodiesForDistrict(LocalBodiesForDistrictRef ref, String districtName) {
  final dataAsync = ref.watch(localElectionResultsProvider);
  final data = dataAsync.valueOrNull;
  if (data == null) return [];

  return data.localBodies
      .where((lb) => lb.district.toLowerCase() == districtName.toLowerCase())
      .toList();
}

/// Selected local body provider
@riverpod
class SelectedLocalBody extends _$SelectedLocalBody {
  @override
  String? build() => null;

  void setLocalBody(String? id) {
    state = id;
  }

  void clear() {
    state = null;
  }
}

