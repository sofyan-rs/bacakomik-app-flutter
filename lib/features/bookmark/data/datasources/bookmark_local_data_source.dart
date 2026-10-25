import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

abstract interface class BookmarkLocalDataSource {
  List<BookmarkModel> getAll();

  /// One bookmark by key, decoding only it.
  BookmarkModel? get(String slug);

  Future<void> putAll(List<BookmarkModel> bookmarks);

  Future<void> deleteAll(List<String> slugs);

  RawJsonStore get raw;
}

@LazySingleton(as: BookmarkLocalDataSource)
class BookmarkLocalDataSourceImpl implements BookmarkLocalDataSource {
  BookmarkLocalDataSourceImpl(@Named(HiveBoxes.bookmarks) Box<String> box)
    : _box = JsonBox(
        box,
        fromJson: BookmarkModel.fromJson,
        toJson: (b) => b.toJson(),
        keyOf: (b) => b.slug,
      );

  final JsonBox<BookmarkModel> _box;

  @override
  List<BookmarkModel> getAll() => _box.values();

  /// Null also when the record no longer parses, as [getAll] skips it.
  @override
  BookmarkModel? get(String slug) {
    try {
      return _box.get(slug);
    } catch (e) {
      debugPrint('Skipping unreadable bookmark $slug: $e');
      return null;
    }
  }

  @override
  Future<void> putAll(List<BookmarkModel> bookmarks) => _box.putAll(bookmarks);

  @override
  Future<void> deleteAll(List<String> slugs) => _box.deleteAll(slugs);

  @override
  RawJsonStore get raw => _box;
}
