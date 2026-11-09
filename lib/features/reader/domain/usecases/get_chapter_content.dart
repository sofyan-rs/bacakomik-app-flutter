import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/download/domain/repositories/download_repository.dart';
import 'package:yoru/features/reader/domain/entities/chapter_content.dart';
import 'package:yoru/features/reader/domain/repositories/reader_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Params: chapter slug (`seriesSlug/number`). A downloaded chapter is read
/// from the device, online or not.
@injectable
class GetChapterContent implements UseCase<ChapterContent, String> {
  const GetChapterContent(this._repository, this._downloads);

  final ReaderRepository _repository;
  final DownloadRepository _downloads;

  @override
  Future<Either<Failure, ChapterContent>> call(String chapterSlug) async {
    final offline = await _downloads.getOfflineChapter(chapterSlug);
    if (offline != null) return right(offline);
    return _repository.getChapter(chapterSlug);
  }
}
