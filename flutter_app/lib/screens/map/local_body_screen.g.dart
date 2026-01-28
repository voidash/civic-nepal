// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_body_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localElectionResultsHash() =>
    r'd42930bc19af25d4855342bf670b7264b1e32e04';

/// Provider for local election results
///
/// Copied from [localElectionResults].
@ProviderFor(localElectionResults)
final localElectionResultsProvider =
    AutoDisposeFutureProvider<LocalElectionData>.internal(
  localElectionResults,
  name: r'localElectionResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localElectionResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalElectionResultsRef
    = AutoDisposeFutureProviderRef<LocalElectionData>;
String _$localBodiesForDistrictHash() =>
    r'426cc7013fe22dee625be10bebb3d14737e10cf7';

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

/// Provider for local bodies in a specific district
///
/// Copied from [localBodiesForDistrict].
@ProviderFor(localBodiesForDistrict)
const localBodiesForDistrictProvider = LocalBodiesForDistrictFamily();

/// Provider for local bodies in a specific district
///
/// Copied from [localBodiesForDistrict].
class LocalBodiesForDistrictFamily extends Family<List<LocalBodyResult>> {
  /// Provider for local bodies in a specific district
  ///
  /// Copied from [localBodiesForDistrict].
  const LocalBodiesForDistrictFamily();

  /// Provider for local bodies in a specific district
  ///
  /// Copied from [localBodiesForDistrict].
  LocalBodiesForDistrictProvider call(
    String districtName,
  ) {
    return LocalBodiesForDistrictProvider(
      districtName,
    );
  }

  @override
  LocalBodiesForDistrictProvider getProviderOverride(
    covariant LocalBodiesForDistrictProvider provider,
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
  String? get name => r'localBodiesForDistrictProvider';
}

/// Provider for local bodies in a specific district
///
/// Copied from [localBodiesForDistrict].
class LocalBodiesForDistrictProvider
    extends AutoDisposeProvider<List<LocalBodyResult>> {
  /// Provider for local bodies in a specific district
  ///
  /// Copied from [localBodiesForDistrict].
  LocalBodiesForDistrictProvider(
    String districtName,
  ) : this._internal(
          (ref) => localBodiesForDistrict(
            ref as LocalBodiesForDistrictRef,
            districtName,
          ),
          from: localBodiesForDistrictProvider,
          name: r'localBodiesForDistrictProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$localBodiesForDistrictHash,
          dependencies: LocalBodiesForDistrictFamily._dependencies,
          allTransitiveDependencies:
              LocalBodiesForDistrictFamily._allTransitiveDependencies,
          districtName: districtName,
        );

  LocalBodiesForDistrictProvider._internal(
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
    List<LocalBodyResult> Function(LocalBodiesForDistrictRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LocalBodiesForDistrictProvider._internal(
        (ref) => create(ref as LocalBodiesForDistrictRef),
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
  AutoDisposeProviderElement<List<LocalBodyResult>> createElement() {
    return _LocalBodiesForDistrictProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalBodiesForDistrictProvider &&
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
mixin LocalBodiesForDistrictRef
    on AutoDisposeProviderRef<List<LocalBodyResult>> {
  /// The parameter `districtName` of this provider.
  String get districtName;
}

class _LocalBodiesForDistrictProviderElement
    extends AutoDisposeProviderElement<List<LocalBodyResult>>
    with LocalBodiesForDistrictRef {
  _LocalBodiesForDistrictProviderElement(super.provider);

  @override
  String get districtName =>
      (origin as LocalBodiesForDistrictProvider).districtName;
}

String _$selectedLocalBodyHash() => r'3376e3e7c01be970bccbc1d00cba28320690b9b5';

/// Selected local body provider
///
/// Copied from [SelectedLocalBody].
@ProviderFor(SelectedLocalBody)
final selectedLocalBodyProvider =
    AutoDisposeNotifierProvider<SelectedLocalBody, String?>.internal(
  SelectedLocalBody.new,
  name: r'selectedLocalBodyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedLocalBodyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedLocalBody = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
