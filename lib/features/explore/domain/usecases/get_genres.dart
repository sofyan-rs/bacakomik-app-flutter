import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/explore/domain/repositories/explore_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetGenres implements UseCase<List<Genre>, NoParams> {
  const GetGenres(this._repository);

  final ExploreRepository _repository;

  @override
  Future<Either<Failure, List<Genre>>> call(NoParams params) =>
      _repository.genres();
}
