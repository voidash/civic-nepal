import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/constituency.dart';
import '../services/data_service.dart';

part 'constituencies_provider.g.dart';

/// Provider for federal constituencies data
@riverpod
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
