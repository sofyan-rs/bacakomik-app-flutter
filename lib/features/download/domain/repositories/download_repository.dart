import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:fpdart/fpdart.dart';

/// Chapters saved on the device for offline reading. Downloads run one
/// chapter at a time, in the order they were queued, while the app is open.
abstract interface class DownloadRepository {
  /// Emits after every change to the stored downloads, including each
  /// saved page.
  Stream<void> get changes;

  Future<Either<Failure, DownloadLibrary>> getDownloads();

  /// Queues [chapters] in the given order. Completed and already queued
  /// chapters are skipped; failed ones are queued again.
  Future<Either<Failure, Unit>> enqueue({
    required String comicSlug,
    required ComicDetails comicDetails,
    required List<Chapter> chapters,
  });

  /// Queues failed chapters again, by chapter slug.
  Future<Either<Failure, Unit>> retry(List<String> slugs);

  /// Cancels and removes chapters by slug, with their files.
  Future<Either<Failure, Unit>> delete(List<String> slugs);

  Future<Either<Failure, Unit>> clear();

  /// A completed chapter with its pages as file paths, or null.
  Future<ChapterContent?> getOfflineChapter(String slug);

  /// The stored details of a comic with downloads, or null.
  Future<ComicDetails?> getOfflineComic(String comicSlug);
}
