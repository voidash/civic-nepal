import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/leader.dart';
import '../models/district.dart';
import '../services/data_service.dart';

part 'leaders_provider.g.dart';

/// Provider for leaders data
@riverpod
Future<LeadersData> leaders(LeadersRef ref) async {
  return await DataService.loadLeaders();
}

/// Provider for parties data
@riverpod
Future<PartyData> parties(PartiesRef ref) async {
  return await DataService.loadParties();
}

/// Provider for districts data
@riverpod
Future<DistrictData> districts(DistrictsRef ref) async {
  return await DataService.loadDistricts();
}

/// Selected party filter
@riverpod
class SelectedParty extends _$SelectedParty {
  @override
  String? build() => null;

  void setParty(String? partyId) {
    state = partyId;
  }

  void clear() {
    state = null;
  }
}

/// Selected district filter
@riverpod
class SelectedDistrict extends _$SelectedDistrict {
  @override
  String? build() => null;

  void setDistrict(String? districtId) {
    state = districtId;
  }

  void clear() {
    state = null;
  }
}

/// Leaders sort option: 'name', 'votes', 'district'
@riverpod
class LeadersSortOption extends _$LeadersSortOption {
  @override
  String build() => 'name';

  void setSortOption(String option) {
    state = option;
  }
}

/// Filtered and sorted leaders
@riverpod
List<Leader> filteredLeaders(FilteredLeadersRef ref) {
  final leadersAsync = ref.watch(leadersProvider);
  final selectedParty = ref.watch(selectedPartyProvider);
  final selectedDistrict = ref.watch(selectedDistrictProvider);
  final sortOption = ref.watch(leadersSortOptionProvider);

  final leaders = leadersAsync.valueOrNull?.leaders ?? [];

  // Apply filters
  var filtered = leaders.where((leader) {
    if (selectedParty != null && leader.party != selectedParty) {
      return false;
    }
    if (selectedDistrict != null && leader.district != selectedDistrict) {
      return false;
    }
    return true;
  }).toList();

  // Apply sorting
  switch (sortOption) {
    case 'name':
      filtered.sort((a, b) => a.name.compareTo(b.name));
      break;
    case 'votes':
      filtered.sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
      break;
    case 'district':
      filtered.sort((a, b) =>
          (a.district ?? '').compareTo(b.district ?? ''));
      break;
  }

  return filtered;
}
