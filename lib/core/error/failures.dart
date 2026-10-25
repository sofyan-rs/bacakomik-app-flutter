/// Errors returned from repositories to the domain and presentation layers.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class FileFailure extends Failure {
  const FileFailure(super.message);
}

/// Not signed in, or the account no longer grants access.
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
