// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$schoolsHash() => r'3c4bced2e01e93bf3bbb183e6b4cd7897837ab44';

/// Provider for schools data
///
/// Copied from [schools].
@ProviderFor(schools)
final schoolsProvider = FutureProvider<OsmPointData>.internal(
  schools,
  name: r'schoolsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$schoolsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SchoolsRef = FutureProviderRef<OsmPointData>;
String _$collegesHash() => r'73eb0692f5377279525ab07f692ee736cefec333';

/// Provider for colleges data
///
/// Copied from [colleges].
@ProviderFor(colleges)
final collegesProvider = FutureProvider<OsmPointData>.internal(
  colleges,
  name: r'collegesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$collegesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CollegesRef = FutureProviderRef<OsmPointData>;
String _$governmentHash() => r'1fa4eacb1e1a7ebd901e5078ac08b608ad0c5f39';

/// Provider for government offices data
///
/// Copied from [government].
@ProviderFor(government)
final governmentProvider = FutureProvider<OsmPointData>.internal(
  government,
  name: r'governmentProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$governmentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GovernmentRef = FutureProviderRef<OsmPointData>;
String _$roadsHash() => r'd164b0aee506e8b42d1a06c86886b2fbf818d542';

/// Provider for roads data
///
/// Copied from [roads].
@ProviderFor(roads)
final roadsProvider = FutureProvider<OsmRoadData>.internal(
  roads,
  name: r'roadsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$roadsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RoadsRef = FutureProviderRef<OsmRoadData>;
String _$religiousSitesHash() => r'fcb22a76211f68e0f11cf7904d62992b60dcfffa';

/// Provider for religious sites data
///
/// Copied from [religiousSites].
@ProviderFor(religiousSites)
final religiousSitesProvider = FutureProvider<List<ReligiousPoint>>.internal(
  religiousSites,
  name: r'religiousSitesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$religiousSitesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReligiousSitesRef = FutureProviderRef<List<ReligiousPoint>>;
String _$policeStationsHash() => r'657ca1b140db0362c32531ad9571b494b2374a43';

/// Provider for police stations data
///
/// Copied from [policeStations].
@ProviderFor(policeStations)
final policeStationsProvider = FutureProvider<List<PolicePoint>>.internal(
  policeStations,
  name: r'policeStationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$policeStationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PoliceStationsRef = FutureProviderRef<List<PolicePoint>>;
String _$trekkingSpotsHash() => r'e11082a7dc51c279af090b0f029c10c28868d11d';

/// Provider for trekking spots data
///
/// Copied from [trekkingSpots].
@ProviderFor(trekkingSpots)
final trekkingSpotsProvider = FutureProvider<List<TrekkingPoint>>.internal(
  trekkingSpots,
  name: r'trekkingSpotsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trekkingSpotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrekkingSpotsRef = FutureProviderRef<List<TrekkingPoint>>;
String _$mapLayersHash() => r'e8e76402f641b01191eb9733a2c9ff96df830c3c';

/// Map layer state provider
///
/// Copied from [MapLayers].
@ProviderFor(MapLayers)
final mapLayersProvider =
    AutoDisposeNotifierProvider<MapLayers, MapLayerState>.internal(
  MapLayers.new,
  name: r'mapLayersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mapLayersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MapLayers = AutoDisposeNotifier<MapLayerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
