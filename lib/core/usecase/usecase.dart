import 'package:bacakomik_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams {
  const NoParams();
}
