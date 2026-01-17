// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constitution_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$constitutionHash() => r'b8025a9b2e5ec0d5be531ddd12e5b65ff8156b2a';

/// Provider for constitution data
///
/// Copied from [constitution].
@ProviderFor(constitution)
final constitutionProvider =
    AutoDisposeFutureProvider<ConstitutionData>.internal(
  constitution,
  name: r'constitutionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$constitutionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConstitutionRef = AutoDisposeFutureProviderRef<ConstitutionData>;
String _$perSentenceDataHash() => r'bf333d5b95b5ad517664577421f1648ecf74fbf8';

/// Provider for per-sentence data
///
/// Copied from [perSentenceData].
@ProviderFor(perSentenceData)
final perSentenceDataProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  perSentenceData,
  name: r'perSentenceDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$perSentenceDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PerSentenceDataRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$dictionaryHash() => r'c46f44d6e78bac2942cabb6541e6b52fa3aef4e2';

/// Provider for dictionary data
///
/// Copied from [dictionary].
@ProviderFor(dictionary)
final dictionaryProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  dictionary,
  name: r'dictionaryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dictionaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DictionaryRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$knowYourRightsHash() => r'df6abff48b41397464d33ed4bb9815699293c387';

/// Provider for Know Your Rights data
///
/// Copied from [knowYourRights].
@ProviderFor(knowYourRights)
final knowYourRightsProvider =
    AutoDisposeFutureProvider<KnowYourRightsData>.internal(
  knowYourRights,
  name: r'knowYourRightsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$knowYourRightsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KnowYourRightsRef = AutoDisposeFutureProviderRef<KnowYourRightsData>;
String _$languageModeHash() => r'14a13491af31c2b0b51ce354710a0caa67e8c94e';

/// Language mode: 'both', 'nepali', 'english'
///
/// Copied from [LanguageMode].
@ProviderFor(LanguageMode)
final languageModeProvider =
    AutoDisposeNotifierProvider<LanguageMode, String>.internal(
  LanguageMode.new,
  name: r'languageModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$languageModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LanguageMode = AutoDisposeNotifier<String>;
String _$viewModeHash() => r'35268863ab71d084eb646ee7df1c2006e6592827';

/// View mode: 'paragraph', 'sentence'
///
/// Copied from [ViewMode].
@ProviderFor(ViewMode)
final viewModeProvider = AutoDisposeNotifierProvider<ViewMode, String>.internal(
  ViewMode.new,
  name: r'viewModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$viewModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ViewMode = AutoDisposeNotifier<String>;
String _$searchQueryHash() => r'a2de29f344488b8b351fbfcf9c230f993798b9ea';

/// Search query for articles
///
/// Copied from [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
  SearchQuery.new,
  name: r'searchQueryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchQuery = AutoDisposeNotifier<String>;
String _$selectedArticleHash() => r'c9f4a06fbe6a06af2501bc76c27ce99831847a42';

/// Currently selected article (defaults to null to show Know Your Rights)
///
/// Copied from [SelectedArticle].
@ProviderFor(SelectedArticle)
final selectedArticleProvider =
    AutoDisposeNotifierProvider<SelectedArticle, SelectedArticleRef?>.internal(
  SelectedArticle.new,
  name: r'selectedArticleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedArticleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedArticle = AutoDisposeNotifier<SelectedArticleRef?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
