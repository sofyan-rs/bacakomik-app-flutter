import 'package:yoru/core/error/failures.dart';
import 'package:yoru/features/reader/domain/entities/chapter_content.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ReaderRepository {
  /// [chapterSlug] has the form `seriesSlug/number`.
  Future<Either<Failure, ChapterContent>> getChapter(String chapterSlug);
}
