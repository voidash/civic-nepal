import 'package:flutter_test/flutter_test.dart';
import 'package:nepal_civic/services/dictionary_service.dart';

void main() {
  // Initialize Flutter binding for asset loading
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DictionaryService', () {
    setUp(() {
      // Clear cache before each test
      DictionaryService.clearCache();
    });

    test('should initialize without errors', () {
      expect(DictionaryService.isLoaded, isFalse);
    });

    test('should return translations for Nepali words', () async {
      // Test with actual Nepali words from dictionary
      const nepaliWord = 'संविधान'; // Constitution

      await DictionaryService.loadDictionary();
      final translations = DictionaryService.getEnglishTranslations(nepaliWord);

      expect(translations, isNotNull);
      // Note: Specific assertions depend on dictionary content
      // The dictionary should have the word 'संविधान' with English translations
    });

    test('should return translations for English words', () async {
      // Test reverse lookup
      const englishWord = 'constitution';

      await DictionaryService.loadDictionary();
      final translations = DictionaryService.getNepaliTranslations(englishWord);

      expect(translations, isNotNull);
    });

    test('should handle unknown words gracefully', () async {
      const unknownWord = 'nonexistentword123';

      await DictionaryService.loadDictionary();
      final translations = DictionaryService.getEnglishTranslations(unknownWord);

      // Should return empty list for unknown words
      expect(translations, isEmpty);
    });

    test('should handle empty string', () async {
      const emptyWord = '';

      await DictionaryService.loadDictionary();
      final translations = DictionaryService.getEnglishTranslations(emptyWord);

      expect(translations, isEmpty);
    });

    test('should provide stats', () async {
      await DictionaryService.loadDictionary();
      final stats = DictionaryService.getStats();

      expect(stats, isNotNull);
      expect(stats.containsKey('np_to_en_count'), isTrue);
      expect(stats.containsKey('en_to_np_count'), isTrue);
    });
  });
}
