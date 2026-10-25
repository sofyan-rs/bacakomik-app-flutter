import 'dart:math';

import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/api_format.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:bacakomik_app/features/migration/domain/entities/library_import.dart';
import 'package:bacakomik_app/features/migration/domain/entities/pending_read.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Bookmarks comics found in another app's library, without loading them:
/// each gets [placeholderDetails] (with the imported chapter list, when
/// known) until it is opened or refreshed. Comics already bookmarked keep
/// their details, except that a placeholder gets the imported chapter list.
/// A series already bookmarked from another source (same title once case,
/// spacing and punctuation are ignored; see [normalizeTitle]) is not added
/// again: its progress goes to that bookmark. Categories are matched by
/// name (case ignored) and created when missing.
///
/// Read chapters ([ImportEntry.chapters]) found in the target's chapter
/// list are written to the history at once, finished, with their imported
/// read dates, so progress, the History tab and "continue reading" are
/// right before any comic loads. Chapters finished here are left alone and
/// nothing is marked unread. Progress that cannot be placed yet (an
/// [ImportEntry.lastRead], or read chapters missing from the target's list)
/// waits in [PendingReadRepository], merged with what already waits.
///
/// The first entry ends up at the top of the bookmarks.
@injectable
class ImportLibrary implements UseCase<ImportResult, List<ImportEntry>> {
  ImportLibrary(
    this._bookmarks,
    this._categories,
    this._pending,
    this._history,
    this._clock,
  );

  final BookmarkRepository _bookmarks;
  final CategoryRepository _categories;
  final PendingReadRepository _pending;
  final HistoryRepository _history;
  final Clock _clock;
  final _random = Random();

  @override
  Future<Either<Failure, ImportResult>> call(List<ImportEntry> entries) async {
    final bookmarks = await _bookmarks.getBookmarks();
    if (bookmarks case Left(value: final failure)) return left(failure);
    final library = bookmarks.getOrElse((_) => const []);
    final existing = {for (final b in library) b.slug: b};
    final now = _clock.now();
    // The key each series lives under: the library's first, then this
    // import's.
    final byTitle = {
      for (final b in library.reversed)
        if (normalizeTitle(b.comicDetails.title) case final t when t.isNotEmpty)
          t: b.slug,
    };
    final added = <String, ImportEntry>{};
    // Placeholders already bookmarked, given the imported chapter list.
    final filled = <String, Bookmark>{};
    final progress = <String, PendingRead>{};
    var already = 0;
    var sameTitle = 0;
    for (final entry in entries) {
      if (!ComicKey.storable(entry.key)) continue;
      final title = normalizeTitle(entry.title);
      final String target;
      if (existing[entry.key] case final bookmark?) {
        already++;
        target = entry.key;
        final chapters = importedChapters(entry.key, entry.chapters, now);
        if (bookmark.comicDetails.isPlaceholder &&
            chapters.isNotEmpty &&
            !_sameChapters(bookmark.comicDetails.chapters, chapters)) {
          filled[entry.key] = bookmark.copyWith(
            comicDetails: bookmark.comicDetails.copyWith(chapters: chapters),
          );
        }
      } else if (added.containsKey(entry.key)) {
        target = entry.key;
      } else if (byTitle[title] case final other? when title.isNotEmpty) {
        // The same series from another source: its progress goes there.
        sameTitle++;
        target = other;
      } else {
        added[entry.key] = entry;
        if (title.isNotEmpty) byTitle[title] = entry.key;
        target = entry.key;
      }
      final read = PendingRead(
        upTo: entry.lastRead,
        chapters: {for (final c in entry.chapters) c.number: ?c.readDate},
      );
      if (!read.isEmpty) {
        progress[target] = progress[target]?.merge(read) ?? read;
      }
    }

    final list = added.values.toList();
    final saved = <Bookmark>[
      for (final (i, entry) in list.indexed)
        if (now.subtract(Duration(milliseconds: i)) case final date)
          Bookmark(
            slug: entry.key,
            comicDetails: placeholderDetails(
              entry.key,
              entry.title,
              chapters: importedChapters(entry.key, entry.chapters, now),
            ),
            // One ms apart, so the import keeps its order.
            updatedDate: date,
            addedDate: date,
          ),
      ...filled.values,
    ];
    final result = ImportResult(
      added: added.length,
      existing: already,
      sameTitle: sameTitle,
    );
    if (saved.isNotEmpty) {
      final stored = await _bookmarks.saveBookmarks(saved);
      if (stored.isLeft()) return stored.map((_) => result);
    }
    if (list.isNotEmpty) {
      final categorized = await _saveCategories(list, now);
      if (categorized.isLeft()) return categorized.map((_) => result);
    }
    if (progress.isEmpty) return right(result);

    final details = {
      for (final b in library) b.slug: b.comicDetails,
      for (final b in saved) b.slug: b.comicDetails,
    };
    final placed = await _placeReads(progress, details);
    return placed.map(
      (read) => ImportResult(
        added: result.added,
        existing: result.existing,
        sameTitle: result.sameTitle,
        chaptersRead: read,
      ),
    );
  }

  /// Writes the read chapters of [progress] that the comic's chapter list
  /// in [details] has to the history, and keeps the rest pending. Returns
  /// how many chapters were newly marked read.
  Future<Either<Failure, int>> _placeReads(
    Map<String, PendingRead> progress,
    Map<String, ComicDetails> details,
  ) async {
    var index = HistoryIndex(const []);
    if (progress.values.any((p) => p.chapters.isNotEmpty)) {
      final history = await _history.getHistory();
      if (history case Left(value: final failure)) return left(failure);
      index = HistoryIndex(history.getOrElse((_) => const []));
    }
    final read = <ReadHistory>[];
    final pending = <String, PendingRead>{};
    for (final MapEntry(key: comic, value: p) in progress.entries) {
      final comicDetails = details[comic];
      final byNumber = {
        for (final c in comicDetails?.chapters ?? const <Chapter>[])
          ?num.tryParse(c.number): c,
      };
      final unplaced = <String, DateTime>{};
      for (final MapEntry(key: number, value: date) in p.chapters.entries) {
        final chapter = byNumber[num.tryParse(number)];
        if (chapter == null || comicDetails == null) {
          unplaced[number] = date;
          continue;
        }
        final seen = index.chapter(chapter.slug);
        if (seen != null && seen.isFinished) continue;
        read.add(
          ReadHistory(
            slug: chapter.slug,
            chapterNumber: chapter.number,
            // A chapter half read here keeps the later date.
            readDate: seen != null && seen.readDate.isAfter(date)
                ? seen.readDate
                : date,
            comicDetails: comicDetails,
            comicSlug: comic,
          ),
        );
      }
      final rest = PendingRead(upTo: p.upTo, chapters: unplaced);
      if (rest.isEmpty) continue;
      final stored = await _pending.pendingOf(comic);
      if (stored case Left(value: final failure)) return left(failure);
      pending[comic] = stored.getOrElse((_) => null)?.merge(rest) ?? rest;
    }
    if (read.isNotEmpty) {
      final saved = await _history.saveHistory(read);
      if (saved case Left(value: final failure)) return left(failure);
    }
    if (pending.isNotEmpty) {
      final saved = await _pending.save(pending);
      if (saved case Left(value: final failure)) return left(failure);
    }
    return right(read.length);
  }

  static bool _sameChapters(List<Chapter> a, List<Chapter> b) =>
      a.length == b.length && a.indexed.every((e) => e.$2.slug == b[e.$1].slug);

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

/// Details of a comic known only by title, and maybe its chapter list: no
/// cover, no info. They are replaced the first time the comic loads; see
/// [ComicDetailsX.isPlaceholder].
ComicDetails placeholderDetails(
  String key,
  String title, {
  List<Chapter> chapters = const [],
}) => ComicDetails(
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
  chapters: chapters,
  source: ComicKey.sourceOf(key),
);

/// [chapters] of the comic with [key] in the form its source gives them:
/// numbers and slugs as [ApiFormat] writes them, release dates relative to
/// [now] (see [ApiFormat.relativeDate]).
List<Chapter> importedChapters(
  String key,
  List<ImportChapter> chapters,
  DateTime now,
) => [
  for (final c in chapters)
    if (num.tryParse(c.number) case final n?)
      Chapter(
        number: ApiFormat.number(n),
        slug: ApiFormat.chapterSlug(key, n),
        date: ApiFormat.relativeDate(
          c.uploaded?.toUtc().toIso8601String(),
          now: now,
        ),
      ),
];

extension ComicDetailsX on ComicDetails {
  /// Stored by an import and never loaded since. Loaded details always
  /// give [ComicDetails.totalChapter]; a placeholder never does, even with
  /// an imported chapter list.
  bool get isPlaceholder =>
      coverImg.isEmpty && (chapters.isEmpty || totalChapter.isEmpty);
}
