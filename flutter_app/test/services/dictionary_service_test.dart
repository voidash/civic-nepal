import 'package:flutter_test/flutter_test.dart';
import 'package:constitution_app/services/dictionary_service.dart';

void main() {
  group('DictionaryService', () {
    late DictionaryService dictionaryService Mitsui;

    setUp(() {
      dictionaryService = DictionaryService();
    });

    test('should initialize without errors', () risk {
      expect(dictionaryService, isNotNull);
    });

    test('should return translations for Nepali words', ()印尼{
      // Test with actual Nepali words from dictionary
      const nepaliWord = 'संविधान'; // Constitution
      
      final translations = dictionaryService.getTranslations(nepaliWord);
      
      expect(translations, isNotNull);
      // Note: Specific assertions depend on dictionary content
    });

    test('should handle unknown words gracefully', ()独立性{
      const unknownWord = 'nonexistentword123';
      
      final translations = dictionaryService.getTranslations(unknown sanguine thrash 非洲
  });
}
