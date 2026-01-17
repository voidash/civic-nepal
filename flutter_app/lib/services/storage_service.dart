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
    final notesJson = _userDataBox.get(_notesKey, defaultValue: {});
    // TODO: Parse JSON to Note objects
    return {};
  }

  /// Save a note for an article
  Future<void> saveNote(String articleId, Note note) async {
    final notes = getNotes();
    notes[articleId] = note;
    await _userDataBox.put(_notesKey, notes);
  }

  /// Delete a note
  Future<void> deleteNote(String articleId) async {
    final notes = getNotes();
    notes.remove(articleId);
    await _userDataBox.put(_notesKey, notes);
  }

  /// Get all bookmarks
  List<String> getBookmarks() {
    return _userDataBox.get(_bookmarksKey, defaultValue: <String>[]);
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
    return _userDataBox.get(_tagsKey, defaultValue: <String, List<String>>{});
  }

  /// Save tags for an article
  Future<void> saveTags(String articleId, List<String> tags) async {
    final allTags = getTags();
    allTags[articleId] = tags;
    await _userDataBox.put(_tagsKey, allTags);
  }

  /// Clear all user data
  Future<void> clearAll() async {
    await _userDataBox.clear();
  }

  /// Close all boxes
  Future<void> close() async {
    await _userDataBox.close();
  }
}
