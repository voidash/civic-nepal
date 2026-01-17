import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';

part 'storage_service.g.dart';

/// Service for local data persistence using Hive
@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService._();
}

class StorageService {
  StorageService._();

  static const String _userDataBoxName = 'user_data';
  static const String _notesKey = 'notes';
  static const String _bookmarksKey = 'bookmarks';
  static const String _tagsKey = 'tags';
  static const int _userDataVersion = 1;

  late Box _userDataBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _userDataBox = await Hive.openBox(_userDataBoxName);
  }

  /// Get all notes
  Map<String, Note> getNotes() {
    try {
      final notesData = _userDataBox.get(_notesKey);

      if (notesData == null) {
        return {};
      }

      // Handle different storage formats
      if (notesData is Map<String, Note>) {
        return notesData;
      }

      if (notesData is Map) {
        final result = <String, Note>{};
        for (final entry in notesData.entries) {
          final key = entry.key.toString();
          final value = entry.value;

          if (value is Note) {
            result[key] = value;
          } else if (value is Map<String, dynamic>) {
            try {
              result[key] = Note.fromJson(value);
            } catch (e) {
              // Skip invalid entries
              continue;
            }
          } else if (value is String && value.isNotEmpty) {
            try {
              final json = jsonDecode(value) as Map<String, dynamic>;
              result[key] = Note.fromJson(json);
            } catch (e) {
              // Skip invalid entries
              continue;
            }
          }
        }
        return result;
      }

      return {};
    } catch (e) {
      // Return empty map on error
      return {};
    }
  }

  /// Save a note for an article
  Future<void> saveNote(String articleId, Note note) async {
    final notes = getNotes();
    notes[articleId] = note;

    // Store as JSON map for proper serialization
    await _userDataBox.put(_notesKey, notes.map(
      (key, value) => MapEntry(key, value.toJson()),
    ));
  }

  /// Delete a note
  Future<void> deleteNote(String articleId) async {
    final notes = getNotes();
    notes.remove(articleId);

    await _userDataBox.put(_notesKey, notes.map(
      (key, value) => MapEntry(key, value.toJson()),
    ));
  }

  /// Get all bookmarks
  List<String> getBookmarks() {
    final bookmarks = _userDataBox.get(_bookmarksKey);
    if (bookmarks == null) return [];

    if (bookmarks is List<String>) {
      return bookmarks;
    }

    if (bookmarks is List) {
      return bookmarks.map((e) => e.toString()).toList();
    }

    return [];
  }

  /// Toggle bookmark for an article
  Future<bool> toggleBookmark(String articleId) async {
    final bookmarks = getBookmarks();
    if (bookmarks.contains(articleId)) {
      bookmarks.remove(articleId);
      await _userDataBox.put(_bookmarksKey, bookmarks);
      return false;
    } else {
      bookmarks.add(articleId);
      await _userDataBox.put(_bookmarksKey, bookmarks);
      return true;
    }
  }

  /// Check if article is bookmarked
  bool isBookmarked(String articleId) {
    return getBookmarks().contains(articleId);
  }

  /// Get all tags
  Map<String, List<String>> getTags() {
    final tags = _userDataBox.get(_tagsKey);
    if (tags == null) return {};

    if (tags is Map<String, List<String>>) {
      return tags;
    }

    if (tags is Map) {
      return tags.map((key, value) => MapEntry(
        key.toString(),
        value is List ? value.map((e) => e.toString()).toList() : [],
      ));
    }

    return {};
  }

  /// Save tags for an article
  Future<void> saveTags(String articleId, List<String> tags) async {
    final allTags = getTags();
    allTags[articleId] = tags;
    await _userDataBox.put(_tagsKey, allTags);
  }

  /// Get all user data as a UserData object
  UserData getUserData() {
    return UserData(
      bookmarks: getBookmarks(),
      notes: getNotes(),
      tags: getTags(),
      version: '$_userDataVersion',
    );
  }

  /// Clear all user data
  Future<void> clearAll() async {
    await _userDataBox.clear();
  }

  /// Close all boxes
  Future<void> close() async {
    await _userDataBox.close();
  }

  /// Export all data as JSON string
  String exportData() {
    final data = getUserData();
    return jsonEncode(data.toJson());
  }

  /// Import data from JSON string
  Future<bool> importData(String jsonData) async {
    try {
      final json = jsonDecode(jsonData) as Map<String, dynamic>;
      final userData = UserData.fromJson(json);

      // Import bookmarks
      await _userDataBox.put(_bookmarksKey, userData.bookmarks);

      // Import notes
      await _userDataBox.put(_notesKey, userData.notes.map(
        (key, value) => MapEntry(key, value.toJson()),
      ));

      // Import tags
      await _userDataBox.put(_tagsKey, userData.tags);

      return true;
    } catch (e) {
      return false;
    }
  }
}
