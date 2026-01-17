// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'district_map_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leadersForDistrictHash() =>
    r'351ebe749085cd312c14420bc4a196c82f6c7694';

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

/// Leaders for selected district
///
/// Copied from [leadersForDistrict].
@ProviderFor(leadersForDistrict)
const leadersForDistrictProvider = LeadersForDistrictFamily();

/// Leaders for selected district
///
/// Copied from [leadersForDistrict].
class LeadersForDistrictFamily extends Family<AsyncValue<List<Leader>>> {
  /// Leaders for selected district
  ///
  /// Copied from [leadersForDistrict].
  const LeadersForDistrictFamily();

  /// Leaders for selected district
  ///
  /// Copied from [leadersForDistrict].
  LeadersForDistrictProvider call(
    String districtName,
  ) {
    return LeadersForDistrictProvider(
      districtName,
    );
  }

  @override
  LeadersForDistrictProvider getProviderOverride(
    covariant LeadersForDistrictProvider provider,
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
  String? get name => r'leadersForDistrictProvider';
}

/// Leaders for selected district
///
/// Copied from [leadersForDistrict].
class LeadersForDistrictProvider
    extends AutoDisposeFutureProvider<List<Leader>> {
  /// Leaders for selected district
  ///
  /// Copied from [leadersForDistrict].
  LeadersForDistrictProvider(
    String districtName,
  ) : this._internal(
          (ref) => leadersForDistrict(
            ref as LeadersForDistrictRef,
            districtName,
          ),
          from: leadersForDistrictProvider,
          name: r'leadersForDistrictProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$leadersForDistrictHash,
          dependencies: LeadersForDistrictFamily._dependencies,
          allTransitiveDependencies:
              LeadersForDistrictFamily._allTransitiveDependencies,
          districtName: districtName,
        );

  LeadersForDistrictProvider._internal(
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
    FutureOr<List<Leader>> Function(LeadersForDistrictRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeadersForDistrictProvider._internal(
        (ref) => create(ref as LeadersForDistrictRef),
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
  AutoDisposeFutureProviderElement<List<Leader>> createElement() {
    return _LeadersForDistrictProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadersForDistrictProvider &&
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
mixin LeadersForDistrictRef on AutoDisposeFutureProviderRef<List<Leader>> {
  /// The parameter `districtName` of this provider.
  String get districtName;
}

class _LeadersForDistrictProviderElement
    extends AutoDisposeFutureProviderElement<List<Leader>>
    with LeadersForDistrictRef {
  _LeadersForDistrictProviderElement(super.provider);

  @override
  String get districtName =>
      (origin as LeadersForDistrictProvider).districtName;
}

String _$selectedDistrictHash() => r'e575590abd7ffe7424fe03e2c631e693630c350b';

/// Selected district provider
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
String _$selectedProvinceHash() => r'7ee53bde37542de242ddec30ad1db44287537995';

/// Selected province filter provider
///
/// Copied from [SelectedProvince].
@ProviderFor(SelectedProvince)
final selectedProvinceProvider =
    AutoDisposeNotifierProvider<SelectedProvince, int?>.internal(
  SelectedProvince.new,
  name: r'selectedProvinceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedProvinceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedProvince = AutoDisposeNotifier<int?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
