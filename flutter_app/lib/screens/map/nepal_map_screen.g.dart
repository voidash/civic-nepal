// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nepal_map_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$boundariesHash() => r'de05d778cd4b60ac9f40d3cdfd5f14ee2046c459';

/// Provider for boundaries data
///
/// Copied from [boundaries].
@ProviderFor(boundaries)
final boundariesProvider = FutureProvider<OsmBoundaries>.internal(
  boundaries,
  name: r'boundariesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$boundariesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BoundariesRef = FutureProviderRef<OsmBoundaries>;
String _$selectedMapDistrictHash() =>
    r'938c19f9b864b2701f8f03eed8af0a6b308b9918';

/// Selected district state
///
/// Copied from [SelectedMapDistrict].
@ProviderFor(SelectedMapDistrict)
final selectedMapDistrictProvider =
    AutoDisposeNotifierProvider<SelectedMapDistrict, BoundaryFeature?>.internal(
  SelectedMapDistrict.new,
  name: r'selectedMapDistrictProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedMapDistrictHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedMapDistrict = AutoDisposeNotifier<BoundaryFeature?>;
String _$selectedMapPOIHash() => r'a867a034ef34618ec13e13e6a8316692000a0e96';

/// Selected point state
///
/// Copied from [SelectedMapPOI].
@ProviderFor(SelectedMapPOI)
final selectedMapPOIProvider =
    AutoDisposeNotifierProvider<SelectedMapPOI, SelectedPOI?>.internal(
  SelectedMapPOI.new,
  name: r'selectedMapPOIProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedMapPOIHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedMapPOI = AutoDisposeNotifier<SelectedPOI?>;
String _$selectedMapPointHash() => r'597232bbb0c7ef70cc6d9eacf0b101c1da5ff150';

/// Selected point state (for schools, colleges, government offices)
///
/// Copied from [SelectedMapPoint].
@ProviderFor(SelectedMapPoint)
final selectedMapPointProvider =
    AutoDisposeNotifierProvider<SelectedMapPoint, OsmPoint?>.internal(
  SelectedMapPoint.new,
  name: r'selectedMapPointProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedMapPointHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedMapPoint = AutoDisposeNotifier<OsmPoint?>;
String _$selectedPointTypeHash() => r'77b7299ed9385654a7ed6942d00c43baaf809d0e';

/// Selected point type
///
/// Copied from [SelectedPointType].
@ProviderFor(SelectedPointType)
final selectedPointTypeProvider =
    AutoDisposeNotifierProvider<SelectedPointType, String?>.internal(
  SelectedPointType.new,
  name: r'selectedPointTypeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedPointTypeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedPointType = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
