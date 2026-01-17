import 'package:flutter_test/flutter_test.dart';
import 'package:constitution_app/services/dictionary_service.dart';

void main() {
  group('DictionaryService', () {
    late DictionaryService dictionaryService;

    setUp(() {
      dictionaryService = DictionaryService();
    });

    test('should initialize without errors', () {
      expect(dictionaryService, isNotNull);
    });

    test('should return translations for Nepali words', () async {
      // Test with actual Nepali words from dictionary
      const nepaliWord = 'संविधान'; // Constitution

      await dictionaryService.initialize();
      final translations = dictionaryService.getTranslations(nepaliWord);

      expect(translations, isNotNull);
      // Note: Specific assertions depend on dictionary content
      // The dictionary should have the word 'संविधान' with English translations
    });

    test('should return translations for English words', () async {
      // Test reverse lookup
      const englishWord = 'constitution';

      await dictionaryService.initialize();
      final translations = dictionaryService.getTranslations(englishWord);

      expect(translations, isNotNull);
    });

    test('should handle unknown words gracefully', () async {
      const unknownWord = 'nonexistentword123';

      await dictionaryService.initialize();
      final translations = dictionaryService.getTranslations(unknownWord);

      // Should return empty list or null for unknown words
      expect(translations, isEmpty);
    });

    test('should handle empty string', () async {
      const emptyWord = '';

      await dictionaryService.initialize();
      final translations = dictionaryService.getTranslations(emptyWord);

      expect(translations, isEmpty);
    });
  });
}
