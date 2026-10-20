import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/download/domain/repositories/download_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetDownloads implements UseCase<DownloadLibrary, NoParams> {
  const GetDownloads(this._repository);

  final DownloadRepository _repository;

  @override
  Future<Either<Failure, DownloadLibrary>> call(NoParams params) =>
      _repository.getDownloads();
}

/// Emits after every change to the stored downloads.
@injectable
class WatchDownloads {
  const WatchDownloads(this._repository);

  final DownloadRepository _repository;

  Stream<void> call() => _repository.changes;
}

class EnqueueParams {
  const EnqueueParams({
    required this.comicSlug,
    required this.comicDetails,
    required this.chapters,
  });

  final String comicSlug;
  final ComicDetails comicDetails;

  /// In download order.
  final List<Chapter> chapters;
}

@injectable
class EnqueueDownloads implements UseCase<Unit, EnqueueParams> {
  const EnqueueDownloads(this._repository);

  final DownloadRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EnqueueParams params) =>
      _repository.enqueue(
        comicSlug: params.comicSlug,
        comicDetails: params.comicDetails,
        chapters: params.chapters,
      );
}

/// Params: chapter slugs of failed downloads.
@injectable
class RetryDownloads implements UseCase<Unit, List<String>> {
  const RetryDownloads(this._repository);

  final DownloadRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<String> slugs) =>
      _repository.retry(slugs);
}

/// Params: chapter slugs to cancel or delete.
@injectable
class DeleteDownloads implements UseCase<Unit, List<String>> {
  const DeleteDownloads(this._repository);

  final DownloadRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<String> slugs) =>
      _repository.delete(slugs);
}

/// Catches up with pages saved while the app was in the background.
@injectable
class SyncDownloads implements UseCase<Unit, NoParams> {
  const SyncDownloads(this._repository);

  final DownloadRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.sync();
}

@injectable
class ClearDownloads implements UseCase<Unit, NoParams> {
  const ClearDownloads(this._repository);

  final DownloadRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.clear();
}
