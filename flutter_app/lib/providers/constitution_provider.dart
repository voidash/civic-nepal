import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/constitution.dart';
import '../models/know_your_rights.dart';
import '../services/data_service.dart';

part 'constitution_provider.freezed.dart';
part 'constitution_provider.g.dart';

/// Provider for constitution data
@riverpod
Future<ConstitutionData> constitution(ConstitutionRef ref) async {
  return await DataService.loadConstitution();
}

/// Provider for per-sentence data
@riverpod
Future<Map<String, dynamic>> perSentenceData(PerSentenceDataRef ref) async {
  return await DataService.loadPerSentenceData();
}

/// Provider for dictionary data
@riverpod
Future<Map<String, dynamic>> dictionary(DictionaryRef ref) async {
  return await DataService.loadDictionary();
}

/// Provider for Know Your Rights data
@riverpod
Future<KnowYourRightsData> knowYourRights(KnowYourRightsRef ref) async {
  return await DataService.loadKnowYourRights();
}

/// Language mode: 'both', 'nepali', 'english'
@riverpod
class LanguageMode extends _$LanguageMode {
  @override
  String build() => 'both';

  void setLanguage(String language) {
    state = language;
  }

  void toggle() {
    if (state == 'both') {
      state = 'nepali';
    } else if (state == 'nepali') {
      state = 'english';
    } else {
      state = 'both';
    }
  }
}

/// View mode: 'paragraph', 'sentence'
@riverpod
class ViewMode extends _$ViewMode {
  @override
  String build() => 'paragraph';

  void setMode(String mode) {
    state = mode;
  }

  void toggle() {
    state = state == 'paragraph' ? 'sentence' : 'paragraph';
  }
}

/// Search query for articles
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Currently selected article (defaults to null to show Know Your Rights)
@riverpod
class SelectedArticle extends _$SelectedArticle {
  @override
  SelectedArticleRef? build() => null;

  void selectArticle(SelectedArticleRef articleRef) {
    state = articleRef;
  }

  void selectPreamble() {
    state = const SelectedArticleRef.preamble();
  }

  void clear() {
    state = null;
  }
}

/// Reference to a selected article or preamble
@freezed
class SelectedArticleRef with _$SelectedArticleRef {
  const factory SelectedArticleRef.preamble() = PreambleRef;
  const factory SelectedArticleRef.article({
    required int partIndex,
    required int articleIndex,
  }) = ArticleRef;
}
