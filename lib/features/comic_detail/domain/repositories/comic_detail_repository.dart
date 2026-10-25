import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ComicDetailRepository {
  /// Series details and chapter list, fetched in parallel.
  Future<Either<Failure, ComicDetails>> getComicDetails(String slug);

  /// Only the chapter list of [slug], newest first: one source call, for
  /// checks that need the series details only when the chapters changed.
  Future<Either<Failure, List<Chapter>>> getChapters(String slug);

  /// Series details of [slug] with [chapters] (from [getChapters]) as its
  /// chapter list, without fetching the chapters again.
  Future<Either<Failure, ComicDetails>> getSeries(
    String slug,
    List<Chapter> chapters,
  );
}
