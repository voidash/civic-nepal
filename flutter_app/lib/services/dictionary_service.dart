import 'dart:convert';
import 'package:flutter/services.dart';

/// Service for looking up Nepali words in the dictionary
class DictionaryService {
  static Map<String, dynamic>? _npToEn;
  static Map<String, dynamic>? _enToNp;

  /// Load dictionary data from assets
  static Future<void> loadDictionary() async {
    if (_npToEn != null && _enToNp != null) return; // Already loaded

    try {
      final jsonString = await rootBundle.loadString('assets/data/dictionary.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      _npToEn = (json['np_to_en'] as Map<String, dynamic>?) ?? {};
      _enToNp = (json['en_to_np'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      // If dictionary fails to load, initialize empty maps
      _npToEn = {};
      _enToNp = {};
    }
  }

  /// Check if dictionary is loaded
  static bool get isLoaded => _npToEn != null && _enToNp != null;

  /// Get English translations for a Nepali word
  /// Returns a list of translations, or empty list if not found
  static List<String> getEnglishTranslations(String nepaliWord) {
    if (_npToEn == null) return [];

    // Try exact match first
    if (_npToEn!.containsKey(nepaliWord)) {
      final translations = _npToEn![nepaliWord];
      if (translations is List) {
        return translations.cast<String>();
      }
      return [translations.toString()];
    }

    // Try case-insensitive match
    final lowerKey = _npToEn!.keys.firstWhere(
      (key) => key.toLowerCase() == nepaliWord.toLowerCase(),
      orElse: () => '',
    );

    if (lowerKey.isNotEmpty && _npToEn!.containsKey(lowerKey)) {
      final translations = _npToEn![lowerKey];
      if (translations is List) {
        return translations.cast<String>();
      }
      return [translations.toString()];
    }

    return [];
  }

  /// Get Nepali translations for an English word
  /// Returns a list of translations, or empty list if not found
  static List<String> getNepaliTranslations(String englishWord) {
    if (_enToNp == null) return [];

    // Try exact match first
    if (_enToNp!.containsKey(englishWord)) {
      final translations = _enToNp![englishWord];
      if (translations is List) {
        return translations.cast<String>();
      }
      return [translations.toString()];
    }

    // Try case-insensitive match
    final lowerKey = _enToNp!.keys.firstWhere(
      (key) => key.toLowerCase() == englishWord.toLowerCase(),
      orElse: () => '',
    );

    if (lowerKey.isNotEmpty && _enToNp!.containsKey(lowerKey)) {
      final translations = _enToNp![lowerKey];
      if (translations is List) {
        return translations.cast<String>();
      }
      return [translations.toString()];
    }

    return [];
  }

  /// Clear cached dictionary data (useful for testing)
  static void clearCache() {
    _npToEn = null;
    _enToNp = null;
  }

  /// Get dictionary statistics
  static Map<String, int> getStats() {
    return {
      'np_to_en_count': _npToEn?.length ?? 0,
      'en_to_np_count': _enToNp?.length ?? 0,
    };
  }
}

/// Result of a dictionary lookup
class DictionaryLookupResult {
  final String queriedWord;
  final List<String> translations;
  final bool found;

  const DictionaryLookupResult({
    required this.queriedWord,
    required this.translations,
    required this.found,
  });

  factory DictionaryLookupResult.notFound(String word) {
    return DictionaryLookupResult(
      queriedWord: word,
      translations: [],
      found: false,
    );
  }

  factory DictionaryLookupResult.found(String word, List<String> translations) {
    return DictionaryLookupResult(
      queriedWord: word,
      translations: translations,
      found: true,
    );
  }

  String get formattedTranslations {
    if (!found) return 'No translations found';
    return translations.join(', ');
  }
}
