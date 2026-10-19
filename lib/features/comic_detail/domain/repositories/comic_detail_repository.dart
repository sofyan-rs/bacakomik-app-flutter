import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ComicDetailRepository {
  Future<Either<Failure, ComicDetails>> getComicDetails(String slug);
}
