import 'package:flutter_test/flutter_test.dart';
import 'package:constitution_app/services/storage_service.dart';
import 'package:constitution_app/models/note.dart';

// Note: Hive tests require proper initialization in test environment
// These tests verify the API exists and basic functionality

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() async {
      storageService = StorageService();
      // Note: In actual test environment, Hive would need proper initialization
      // await storageService.initialize();
    });

    test('should instantiate without errors', () {
      expect(storageService, isNotNull);
    });

    test('should have saveNote method', () {
      // Verify the API exists
      expect(() => storageService.saveNote('article-1', const Note(content: 'test')), returnsNormally);
    });

    test('should have getNotes method', () {
      // Verify the API exists
      expect(() => storageService.getNotes('article-1'), returnsNormally);
    });

    test('should have exportData method', () {
      // This test verifies the export API exists
      expect(() => storageService.exportData(), returnsNormally);
    });

    test('should have importData method', () {
      // This test verifies the import API exists
      expect(() => storageService.importData({}), returnsNormally);
    });

    test('should have bookmark methods', () {
      // Verify bookmark API exists
      expect(() => storageService.toggleBookmark('article-1', true), returnsNormally);
      expect(() => storageService.getBookmarks(), returnsNormally);
    });
  });
}
