import 'dart:async';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Runs a local storage operation and maps any error to [CacheFailure].
Future<Either<Failure, T>> runLocal<T>(FutureOr<T> Function() call) async {
  try {
    return right(await call());
  } catch (e) {
    return left(CacheFailure(e.toString()));
  }
}
