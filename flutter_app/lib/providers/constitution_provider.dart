import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/constitution.dart';
import '../services/data_service.dart';

part 'constitution_provider.g.dart';

/// Provider for constitution data
@riverpod
Future<Constitution> constitution(ConstitutionRef ref) async {
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
