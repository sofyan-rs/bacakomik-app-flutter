import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:fpdart/fpdart.dart';

/// Runs a remote call after a connectivity check and maps errors to
/// [Failure]s, so repositories don't repeat the same try/catch.
Future<Either<Failure, T>> runRemote<T>(
  NetworkInfo networkInfo,
  Future<T> Function() call,
) async {
  if (!await networkInfo.isConnected) return left(const NetworkFailure());
  try {
    return right(await call());
  } on ServerException catch (e) {
    return left(ServerFailure(e.message));
  } catch (e) {
    return left(ServerFailure(e.toString()));
  }
}
