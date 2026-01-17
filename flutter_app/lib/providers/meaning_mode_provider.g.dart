// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meaning_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$meaningModeEnabledHash() =>
    r'f8cd566eed656c45d7805e28f0d8d12a10ae123e';

/// Provider for Meaning Mode enabled state
///
/// Copied from [MeaningModeEnabled].
@ProviderFor(MeaningModeEnabled)
final meaningModeEnabledProvider =
    AutoDisposeNotifierProvider<MeaningModeEnabled, bool>.internal(
  MeaningModeEnabled.new,
  name: r'meaningModeEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$meaningModeEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MeaningModeEnabled = AutoDisposeNotifier<bool>;
String _$currentLookupHash() => r'64f7ecb229e665b213160b590f32c4bbb2cb5813';

/// Provider for the current word lookup
///
/// Copied from [CurrentLookup].
@ProviderFor(CurrentLookup)
final currentLookupProvider = AutoDisposeNotifierProvider<CurrentLookup,
    DictionaryLookupResult?>.internal(
  CurrentLookup.new,
  name: r'currentLookupProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLookupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentLookup = AutoDisposeNotifier<DictionaryLookupResult?>;
String _$dictionaryInitializedHash() =>
    r'8357305d1728553f2197b7b9298801e00e49553a';

/// Provider for dictionary initialization state
///
/// Copied from [DictionaryInitialized].
@ProviderFor(DictionaryInitialized)
final dictionaryInitializedProvider =
    AutoDisposeNotifierProvider<DictionaryInitialized, bool>.internal(
  DictionaryInitialized.new,
  name: r'dictionaryInitializedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dictionaryInitializedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DictionaryInitialized = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
