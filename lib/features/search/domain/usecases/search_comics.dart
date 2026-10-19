import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/search/domain/repositories/search_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

typedef SearchParams = ({String keyword, int page});

@injectable
class SearchComics implements UseCase<List<Comic>, SearchParams> {
  const SearchComics(this._repository);

  final SearchRepository _repository;

  @override
  Future<Either<Failure, List<Comic>>> call(SearchParams params) =>
      _repository.search(params.keyword, params.page);
}
