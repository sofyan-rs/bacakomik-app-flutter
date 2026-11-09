import 'package:yoru/core/domain/entities/comic.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/explore/domain/entities/explore_filter.dart';
import 'package:yoru/features/explore/domain/repositories/explore_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

typedef ExploreParams = ({ExploreFilter filter, int page});

@injectable
class ExploreComics implements UseCase<List<Comic>, ExploreParams> {
  const ExploreComics(this._repository);

  final ExploreRepository _repository;

  @override
  Future<Either<Failure, List<Comic>>> call(ExploreParams params) =>
      _repository.explore(params.filter, params.page);
}
