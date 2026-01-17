// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leadersHash() => r'117622656ba5cfa2c55bd4812c4cfec386595332';

/// Provider for leaders data
///
/// Copied from [leaders].
@ProviderFor(leaders)
final leadersProvider = AutoDisposeFutureProvider<LeadersData>.internal(
  leaders,
  name: r'leadersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$leadersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeadersRef = AutoDisposeFutureProviderRef<LeadersData>;
String _$partiesHash() => r'383cde0dbb51dc9e38b4a886bbf8225e9bf28581';

/// Provider for parties data
///
/// Copied from [parties].
@ProviderFor(parties)
final partiesProvider = AutoDisposeFutureProvider<PartyData>.internal(
  parties,
  name: r'partiesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$partiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PartiesRef = AutoDisposeFutureProviderRef<PartyData>;
String _$districtsHash() => r'ffdf0ceab34a26e2354496b0754567584a1d8407';

/// Provider for districts data
///
/// Copied from [districts].
@ProviderFor(districts)
final districtsProvider = AutoDisposeFutureProvider<DistrictData>.internal(
  districts,
  name: r'districtsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$districtsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DistrictsRef = AutoDisposeFutureProviderRef<DistrictData>;
String _$filteredLeadersHash() => r'26fe30cc11ecdde5c51344c2fd4cc2f6eb0433bc';

/// Filtered and sorted leaders
///
/// Copied from [filteredLeaders].
@ProviderFor(filteredLeaders)
final filteredLeadersProvider = AutoDisposeProvider<List<Leader>>.internal(
  filteredLeaders,
  name: r'filteredLeadersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredLeadersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredLeadersRef = AutoDisposeProviderRef<List<Leader>>;
String _$selectedPartyHash() => r'78cda65a474d5c9315cc37b61c82b93888d7b1de';

/// Selected party filter
///
/// Copied from [SelectedParty].
@ProviderFor(SelectedParty)
final selectedPartyProvider =
    AutoDisposeNotifierProvider<SelectedParty, String?>.internal(
  SelectedParty.new,
  name: r'selectedPartyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedPartyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedParty = AutoDisposeNotifier<String?>;
String _$selectedDistrictHash() => r'e575590abd7ffe7424fe03e2c631e693630c350b';

/// Selected district filter
///
/// Copied from [SelectedDistrict].
@ProviderFor(SelectedDistrict)
final selectedDistrictProvider =
    AutoDisposeNotifierProvider<SelectedDistrict, String?>.internal(
  SelectedDistrict.new,
  name: r'selectedDistrictProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedDistrictHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDistrict = AutoDisposeNotifier<String?>;
String _$leadersSortOptionHash() => r'8e63c2c4161867d0f65ee8ffae356f9b228b1488';

/// Leaders sort option: 'name', 'votes', 'district'
///
/// Copied from [LeadersSortOption].
@ProviderFor(LeadersSortOption)
final leadersSortOptionProvider =
    AutoDisposeNotifierProvider<LeadersSortOption, String>.internal(
  LeadersSortOption.new,
  name: r'leadersSortOptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$leadersSortOptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LeadersSortOption = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
