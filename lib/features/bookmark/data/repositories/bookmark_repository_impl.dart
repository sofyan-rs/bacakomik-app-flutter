import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: BookmarkRepository)
class BookmarkRepositoryImpl implements BookmarkRepository {
  const BookmarkRepositoryImpl(this._local);

  final BookmarkLocalDataSource _local;

  @override
  Future<Either<Failure, List<Bookmark>>> getBookmarks() => runLocal(
        () => _local.getAll().map((m) => m.toEntity()).toList()
          ..sort((a, b) => b.updatedDate.compareTo(a.updatedDate)),
      );

  @override
  Future<Either<Failure, Unit>> saveBookmarks(List<Bookmark> bookmarks) =>
      runLocal(() async {
        await _local.putAll(bookmarks.map(BookmarkModel.fromEntity).toList());
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeBookmarks(List<String> slugs) =>
      runLocal(() async {
        await _local.deleteAll(slugs);
        return unit;
      });
}
