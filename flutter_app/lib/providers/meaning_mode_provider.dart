import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/dictionary_service.dart';

part 'meaning_mode_provider.g.dart';

/// Provider for Meaning Mode enabled state
@riverpod
class MeaningModeEnabled extends _$MeaningModeEnabled {
  @override
  bool build() => false;

  void setEnabled(bool enabled) {
    state = enabled;
  }

  void toggle() {
    state = !state;
  }
}

/// Provider for the current word lookup
@riverpod
class CurrentLookup extends _$CurrentLookup {
  @override
  DictionaryLookupResult? build() => null;

  void lookupWord(String word, {bool fromNepali = true}) {
    if (word.trim().isEmpty) {
      state = null;
      return;
    }

    final translations = fromNepali
        ? DictionaryService.getEnglishTranslations(word)
        : DictionaryService.getNepaliTranslations(word);

    if (translations.isEmpty) {
      state = DictionaryLookupResult.notFound(word);
    } else {
      state = DictionaryLookupResult.found(word, translations);
    }
  }

  void clear() {
    state = null;
  }
}

/// Provider for dictionary initialization state
@riverpod
class DictionaryInitialized extends _$DictionaryInitialized {
  @override
  bool build() => false;

  Future<void> initialize() async {
    await DictionaryService.loadDictionary();
    state = true;
  }

  Future<void> ensureInitialized() async {
    if (!state) {
      await initialize();
    }
  }
}
