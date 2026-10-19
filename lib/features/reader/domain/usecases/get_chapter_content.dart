import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Params: chapter slug (`seriesSlug/number`).
@injectable
class GetChapterContent implements UseCase<ChapterContent, String> {
  const GetChapterContent(this._repository);

  final ReaderRepository _repository;

  @override
  Future<Either<Failure, ChapterContent>> call(String chapterSlug) =>
      _repository.getChapter(chapterSlug);
}
