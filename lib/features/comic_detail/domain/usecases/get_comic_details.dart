import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Params: series slug.
@injectable
class GetComicDetails implements UseCase<ComicDetails, String> {
  const GetComicDetails(this._repository);

  final ComicDetailRepository _repository;

  @override
  Future<Either<Failure, ComicDetails>> call(String slug) =>
      _repository.getComicDetails(slug);
}
