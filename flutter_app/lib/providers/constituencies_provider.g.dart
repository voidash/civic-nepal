// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constituencies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$constituenciesHash() => r'd55e0bb1b6aea3d47ecd39a0d59d6ddbc67060e6';

/// Provider for federal constituencies data
///
/// Copied from [constituencies].
@ProviderFor(constituencies)
final constituenciesProvider =
    AutoDisposeFutureProvider<ConstituencyData>.internal(
  constituencies,
  name: r'constituenciesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$constituenciesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConstituenciesRef = AutoDisposeFutureProviderRef<ConstituencyData>;
String _$constituenciesForDistrictHash() =>
    r'9c63028d37e979d99a1d9b143ae734726d84dc3b';

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

/// Get constituencies for a specific district
///
/// Copied from [constituenciesForDistrict].
@ProviderFor(constituenciesForDistrict)
const constituenciesForDistrictProvider = ConstituenciesForDistrictFamily();

/// Get constituencies for a specific district
///
/// Copied from [constituenciesForDistrict].
class ConstituenciesForDistrictFamily extends Family<List<Constituency>> {
  /// Get constituencies for a specific district
  ///
  /// Copied from [constituenciesForDistrict].
  const ConstituenciesForDistrictFamily();

  /// Get constituencies for a specific district
  ///
  /// Copied from [constituenciesForDistrict].
  ConstituenciesForDistrictProvider call(
    String districtName,
  ) {
    return ConstituenciesForDistrictProvider(
      districtName,
    );
  }

  @override
  ConstituenciesForDistrictProvider getProviderOverride(
    covariant ConstituenciesForDistrictProvider provider,
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
  String? get name => r'constituenciesForDistrictProvider';
}

/// Get constituencies for a specific district
///
/// Copied from [constituenciesForDistrict].
class ConstituenciesForDistrictProvider
    extends AutoDisposeProvider<List<Constituency>> {
  /// Get constituencies for a specific district
  ///
  /// Copied from [constituenciesForDistrict].
  ConstituenciesForDistrictProvider(
    String districtName,
  ) : this._internal(
          (ref) => constituenciesForDistrict(
            ref as ConstituenciesForDistrictRef,
            districtName,
          ),
          from: constituenciesForDistrictProvider,
          name: r'constituenciesForDistrictProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$constituenciesForDistrictHash,
          dependencies: ConstituenciesForDistrictFamily._dependencies,
          allTransitiveDependencies:
              ConstituenciesForDistrictFamily._allTransitiveDependencies,
          districtName: districtName,
        );

  ConstituenciesForDistrictProvider._internal(
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
    List<Constituency> Function(ConstituenciesForDistrictRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConstituenciesForDistrictProvider._internal(
        (ref) => create(ref as ConstituenciesForDistrictRef),
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
  AutoDisposeProviderElement<List<Constituency>> createElement() {
    return _ConstituenciesForDistrictProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConstituenciesForDistrictProvider &&
        other.districtName == districtName;
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
mixin ConstituenciesForDistrictRef
    on AutoDisposeProviderRef<List<Constituency>> {
  /// The parameter `districtName` of this provider.
  String get districtName;
}

class _ConstituenciesForDistrictProviderElement
    extends AutoDisposeProviderElement<List<Constituency>>
    with ConstituenciesForDistrictRef {
  _ConstituenciesForDistrictProviderElement(super.provider);

  @override
  String get districtName =>
      (origin as ConstituenciesForDistrictProvider).districtName;
}

String _$selectedConstituencyHash() =>
    r'3a6b1a356027f25514691be3ca4e8006a3d06135';

/// Selected constituency for drill-down
///
/// Copied from [SelectedConstituency].
@ProviderFor(SelectedConstituency)
final selectedConstituencyProvider =
    AutoDisposeNotifierProvider<SelectedConstituency, Constituency?>.internal(
  SelectedConstituency.new,
  name: r'selectedConstituencyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedConstituencyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedConstituency = AutoDisposeNotifier<Constituency?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
