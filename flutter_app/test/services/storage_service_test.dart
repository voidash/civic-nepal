import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepal_civic/models/note.dart';
import 'package:nepal_civic/services/storage_service.dart';

// Note: Hive tests require proper initialization in test environment
// These tests verify the Note model and provider exist

void main() {
  group('StorageService Models', () {
    test('Note model should create valid instance', () {
      // Verify the Note model can be created with all required fields
      final note = Note(
        id: 'test-id',
        articleId: 'article-1',
        content: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: [],
      );
      expect(note.id, equals('test-id'));
      expect(note.articleId, equals('article-1'));
      expect(note.content, equals('test'));
      expect(note.tags, isEmpty);
    });

    test('Note model should serialize to JSON', () {
      final now = DateTime.now();
      final note = Note(
        id: 'test-id',
        articleId: 'article-1',
        content: 'test',
        createdAt: now,
        updatedAt: now,
        tags: ['tag1', 'tag2'],
      );

      final json = note.toJson();
      expect(json['id'], equals('test-id'));
      expect(json['articleId'], equals('article-1'));
      expect(json['content'], equals('test'));
      expect(json['tags'], equals(['tag1', 'tag2']));
    });

    test('Note model should deserialize from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-id',
        'articleId': 'article-1',
        'content': 'test',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'tags': ['tag1', 'tag2'],
      };

      final note = Note.fromJson(json);
      expect(note.id, equals('test-id'));
      expect(note.articleId, equals('article-1'));
      expect(note.content, equals('test'));
      expect(note.tags, equals(['tag1', 'tag2']));
    });
  });

  group('StorageService Provider', () {
    test('storageService provider should be accessible', () {
      // Verify the provider can be read without errors
      final container = ProviderContainer();
      expect(
        () => container.read(storageServiceProvider),
        returnsNormally,
      );
      container.dispose();
    });
  });
}
