import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/constituency.dart';
import '../services/data_service.dart';

part 'constituencies_provider.g.dart';

/// Provider for federal constituencies data
/// Using keepAlive to cache the data and avoid reloading on every screen visit
@Riverpod(keepAlive: true)
Future<ConstituencyData> constituencies(ConstituenciesRef ref) async {
  return await DataService.loadConstituencies();
}

/// Get constituencies for a specific district
@riverpod
List<Constituency> constituenciesForDistrict(
  ConstituenciesForDistrictRef ref,
  String districtName,
) {
  final dataAsync = ref.watch(constituenciesProvider);
  final data = dataAsync.valueOrNull;
  if (data == null) return [];

  return data.districts[districtName] ?? [];
}

/// Remote flag to control vote display - updated via constituencies.json
@riverpod
bool showVotes(ShowVotesRef ref) {
  final dataAsync = ref.watch(constituenciesProvider);
  return dataAsync.valueOrNull?.showVotes ?? false;
}

/// Selected constituency for drill-down
@riverpod
class SelectedConstituency extends _$SelectedConstituency {
  @override
  Constituency? build() => null;

  void setConstituency(Constituency? constituency) {
    state = constituency;
  }

  void clear() {
    state = null;
  }
}
