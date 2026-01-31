// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_districts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$geoDistrictsHash() => r'1f7af3a782fa667027eb1ac23ea893e2126f926a';

/// Provider for GeoJSON district boundaries
///
/// Copied from [geoDistricts].
@ProviderFor(geoDistricts)
final geoDistrictsProvider = FutureProvider<GeoDistrictsData>.internal(
  geoDistricts,
  name: r'geoDistrictsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$geoDistrictsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeoDistrictsRef = FutureProviderRef<GeoDistrictsData>;
String _$geoLocalUnitsHash() => r'bf8b7d8c863dfd8d9403180363825e950023e6ee';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for GeoJSON local units of a specific district
///
/// Copied from [geoLocalUnits].
@ProviderFor(geoLocalUnits)
const geoLocalUnitsProvider = GeoLocalUnitsFamily();

/// Provider for GeoJSON local units of a specific district
///
/// Copied from [geoLocalUnits].
class GeoLocalUnitsFamily extends Family<AsyncValue<GeoLocalUnitsData>> {
  /// Provider for GeoJSON local units of a specific district
  ///
  /// Copied from [geoLocalUnits].
  const GeoLocalUnitsFamily();

  /// Provider for GeoJSON local units of a specific district
  ///
  /// Copied from [geoLocalUnits].
  GeoLocalUnitsProvider call(
    String districtName,
  ) {
    return GeoLocalUnitsProvider(
      districtName,
    );
  }

  @override
  GeoLocalUnitsProvider getProviderOverride(
    covariant GeoLocalUnitsProvider provider,
  ) {
    return call(
      provider.districtName,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'geoLocalUnitsProvider';
}

/// Provider for GeoJSON local units of a specific district
///
/// Copied from [geoLocalUnits].
class GeoLocalUnitsProvider
    extends AutoDisposeFutureProvider<GeoLocalUnitsData> {
  /// Provider for GeoJSON local units of a specific district
  ///
  /// Copied from [geoLocalUnits].
  GeoLocalUnitsProvider(
    String districtName,
  ) : this._internal(
          (ref) => geoLocalUnits(
            ref as GeoLocalUnitsRef,
            districtName,
          ),
          from: geoLocalUnitsProvider,
          name: r'geoLocalUnitsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$geoLocalUnitsHash,
          dependencies: GeoLocalUnitsFamily._dependencies,
          allTransitiveDependencies:
              GeoLocalUnitsFamily._allTransitiveDependencies,
          districtName: districtName,
        );

  GeoLocalUnitsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.districtName,
  }) : super.internal();

  final String districtName;

  @override
  Override overrideWith(
    FutureOr<GeoLocalUnitsData> Function(GeoLocalUnitsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GeoLocalUnitsProvider._internal(
        (ref) => create(ref as GeoLocalUnitsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        districtName: districtName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GeoLocalUnitsData> createElement() {
    return _GeoLocalUnitsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GeoLocalUnitsProvider && other.districtName == districtName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, districtName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GeoLocalUnitsRef on AutoDisposeFutureProviderRef<GeoLocalUnitsData> {
  /// The parameter `districtName` of this provider.
  String get districtName;
}

class _GeoLocalUnitsProviderElement
    extends AutoDisposeFutureProviderElement<GeoLocalUnitsData>
    with GeoLocalUnitsRef {
  _GeoLocalUnitsProviderElement(super.provider);

  @override
  String get districtName => (origin as GeoLocalUnitsProvider).districtName;
}

String _$geoConstituenciesHash() => r'627e974913d775711223c29d3f71e0ec39fbb0d5';

/// Provider for simplified constituency boundaries
///
/// Copied from [geoConstituencies].
@ProviderFor(geoConstituencies)
final geoConstituenciesProvider =
    FutureProvider<GeoConstituenciesData>.internal(
  geoConstituencies,
  name: r'geoConstituenciesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geoConstituenciesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeoConstituenciesRef = FutureProviderRef<GeoConstituenciesData>;
String _$selectedGeoDistrictHash() =>
    r'51b527ff251422dd85c50fe3d9ff5e0ab38759db';

/// Selected GeoJSON district provider
///
/// Copied from [SelectedGeoDistrict].
@ProviderFor(SelectedGeoDistrict)
final selectedGeoDistrictProvider =
    AutoDisposeNotifierProvider<SelectedGeoDistrict, GeoDistrict?>.internal(
  SelectedGeoDistrict.new,
  name: r'selectedGeoDistrictProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedGeoDistrictHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedGeoDistrict = AutoDisposeNotifier<GeoDistrict?>;
String _$selectedGeoLocalUnitHash() =>
    r'a5c958428d0794819d5ac91e537bc63e69fdc695';

/// Selected GeoJSON local unit provider
///
/// Copied from [SelectedGeoLocalUnit].
@ProviderFor(SelectedGeoLocalUnit)
final selectedGeoLocalUnitProvider =
    AutoDisposeNotifierProvider<SelectedGeoLocalUnit, GeoLocalUnit?>.internal(
  SelectedGeoLocalUnit.new,
  name: r'selectedGeoLocalUnitProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedGeoLocalUnitHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedGeoLocalUnit = AutoDisposeNotifier<GeoLocalUnit?>;
String _$selectedGeoConstituencyHash() =>
    r'7d04ce23c66ceb2da1305972ff90877603c743c4';

/// Selected constituency provider
///
/// Copied from [SelectedGeoConstituency].
@ProviderFor(SelectedGeoConstituency)
final selectedGeoConstituencyProvider = AutoDisposeNotifierProvider<
    SelectedGeoConstituency, GeoConstituency?>.internal(
  SelectedGeoConstituency.new,
  name: r'selectedGeoConstituencyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedGeoConstituencyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedGeoConstituency = AutoDisposeNotifier<GeoConstituency?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
