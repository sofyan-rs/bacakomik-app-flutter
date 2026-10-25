import 'dart:math';

import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/migration/domain/entities/library_import.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Bookmarks comics found in another app's library, without loading them:
/// each gets [placeholderDetails] until it is opened or refreshed. Comics
/// already bookmarked are left alone. Categories are matched by name
/// (case ignored) and created when missing, and each entry's
/// [ImportEntry.lastRead] waits in [PendingReadRepository], also for comics
/// already bookmarked.
///
/// The first entry ends up at the top of the bookmarks.
@injectable
class ImportLibrary implements UseCase<ImportResult, List<ImportEntry>> {
  ImportLibrary(this._bookmarks, this._categories, this._pending, this._clock);

  final BookmarkRepository _bookmarks;
  final CategoryRepository _categories;
  final PendingReadRepository _pending;
  final Clock _clock;
  final _random = Random();

  @override
  Future<Either<Failure, ImportResult>> call(List<ImportEntry> entries) async {
    final bookmarks = await _bookmarks.getBookmarks();
    if (bookmarks case Left(value: final failure)) return left(failure);
    final existing = {
      for (final b in bookmarks.getOrElse((_) => const [])) b.slug,
    };
    final added = <String, ImportEntry>{};
    for (final entry in entries) {
      if (!existing.contains(entry.key)) {
        added.putIfAbsent(entry.key, () => entry);
      }
    }
    final result = ImportResult(
      added: added.length,
      existing: entries.length - added.length,
    );
    if (added.isEmpty) return (await _saveLastRead(entries)).map((_) => result);

    final now = _clock.now();
    final list = added.values.toList();
    final saved = await _bookmarks.saveBookmarks([
      for (final (i, entry) in list.indexed)
        Bookmark(
          slug: entry.key,
          comicDetails: placeholderDetails(entry.key, entry.title),
          // One ms apart, so the import keeps its order.
          updatedDate: now.subtract(Duration(milliseconds: i)),
        ),
    ]);
    if (saved.isLeft()) return saved.map((_) => result);

    final categorized = await _saveCategories(list, now);
    if (categorized.isLeft()) return categorized.map((_) => result);

    return (await _saveLastRead(entries)).map((_) => result);
  }

  /// Progress of comics already bookmarked waits too.
  Future<Either<Failure, Unit>> _saveLastRead(List<ImportEntry> entries) async {
    final lastRead = {for (final entry in entries) entry.key: ?entry.lastRead};
    if (lastRead.isEmpty) return right(unit);
    return _pending.save(lastRead);
  }

  Future<Either<Failure, Unit>> _saveCategories(
    List<ImportEntry> entries,
    DateTime now,
  ) async {
    final names = {
      for (final entry in entries)
        for (final name in entry.categories)
          if (name.trim().isNotEmpty) name.trim(),
    };
    if (names.isEmpty) return right(unit);
    final current = await _categories.getCategories();
    if (current case Left(value: final failure)) return left(failure);
    final categories = current.getOrElse((_) => const []);

    final idByName = {for (final c in categories) c.name.toLowerCase(): c.id};
    var order = categories.fold(-1, (m, c) => max(m, c.order));
    final created = <LibraryCategory>[];
    for (final name in names) {
      if (idByName.containsKey(name.toLowerCase())) continue;
      final category = LibraryCategory(
        id: _newId(now),
        name: name,
        order: ++order,
        updatedDate: now,
      );
      created.add(category);
      idByName[name.toLowerCase()] = category.id;
    }
    if (created.isNotEmpty) {
      final saved = await _categories.saveCategories(created);
      if (saved.isLeft()) return saved;
    }
    return _categories.saveComicCategories([
      for (final entry in entries)
        if (entry.categories.isNotEmpty)
          ComicCategories(
            slug: entry.key,
            categoryIds: {
              for (final name in entry.categories)
                ?idByName[name.trim().toLowerCase()],
            }.toList(),
            updatedDate: now,
          ),
    ]);
  }

  String _newId(DateTime now) =>
      now.microsecondsSinceEpoch.toRadixString(36) +
      _random.nextInt(1 << 32).toRadixString(36);
}

/// Details of a comic known only by title: no cover, no chapters. They are
/// replaced the first time the comic loads; see [ComicDetailsX.isPlaceholder].
ComicDetails placeholderDetails(String key, String title) => ComicDetails(
  title: title,
  coverImg: '',
  alternativeTitle: '',
  released: '',
  status: '',
  totalChapter: '',
  author: '',
  type: '',
  rating: '',
  synopsis: '',
  genres: const [],
  chapters: const [],
  source: ComicKey.sourceOf(key),
);

extension ComicDetailsX on ComicDetails {
  /// Stored by an import and never loaded since.
  bool get isPlaceholder => chapters.isEmpty && coverImg.isEmpty;
}
