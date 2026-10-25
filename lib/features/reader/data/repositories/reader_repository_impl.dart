import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/core/utils/api_format.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  const ReaderRepositoryImpl(this._remote, this._networkInfo);

  /// Message of the failure for a chapter the source returns no pages for.
  static const noPages = 'This chapter has no pages';

  final SeriesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, ChapterContent>> getChapter(String chapterSlug) async {
    final separator = chapterSlug.lastIndexOf('/');
    if (separator <= 0) {
      return left(ServerFailure('Invalid chapter: $chapterSlug'));
    }
    final seriesSlug = chapterSlug.substring(0, separator);
    final number = chapterSlug.substring(separator + 1);

    return runRemote(_networkInfo, () async {
      final res = await _remote.getChapter(seriesSlug, number);
      // The reader and downloads need at least one page.
      if (res.images.isEmpty) throw const ServerException(noPages);
      final chapterNumber = ApiFormat.number(res.number);
      return ChapterContent(
        chapterTitle: res.title ?? 'Chapter $chapterNumber',
        chapterNumber: chapterNumber,
        seriesSlug: seriesSlug,
        previousChapterSlug: res.prev != null
            ? ApiFormat.chapterSlug(seriesSlug, res.prev!)
            : null,
        nextChapterSlug: res.next != null
            ? ApiFormat.chapterSlug(seriesSlug, res.next!)
            : null,
        images: res.images,
        imageHeaders: res.headers,
      );
    });
  }
}
