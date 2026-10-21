import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:bacakomik_app/features/sync/data/datasources/drive_data_source.dart';
import 'package:bacakomik_app/features/sync/data/datasources/google_auth_data_source.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SyncRepository)
class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl(
    this._auth,
    this._drive,
    this._bookmarks,
    this._history,
    this._journal,
    @Named(HiveBoxes.sync) this._state,
  );

  final GoogleAuthDataSource _auth;
  final DriveDataSource _drive;
  final BookmarkLocalDataSource _bookmarks;
  final HistoryLocalDataSource _history;
  final LibraryJournal _journal;
  final Box<String> _state;

  static const _lastSyncedAtKey = 'lastSyncedAt';

  /// Set while signed in. On Android a restore attempt can show the account
  /// picker, so it is only made after an earlier sign-in.
  static const _accountKey = 'account';

  @override
  Future<Either<Failure, String?>> restoreAccount() async {
    if (_state.get(_accountKey) == null) return right(null);
    return _remote(_auth.restore);
  }

  @override
  Future<Either<Failure, String?>> signIn() => _remote(() async {
    final email = await _auth.signIn();
    if (email != null) await _state.put(_accountKey, email);
    return email;
  });

  @override
  Future<Either<Failure, Unit>> signOut() => _remote(() async {
    await _auth.signOut();
    await _state.delete(_accountKey);
    return unit;
  });

  @override
  Future<Either<Failure, SyncSnapshot>> readLocal() => runLocal(() {
    final comics = _history.getComics();
    return SyncSnapshot(
      bookmarks: [for (final b in _bookmarks.getAll()) b.toEntity()],
      history: [
        for (final entry in _history.getEntries())
          if (comics[entry.comicSlug] case final comic?)
            entry.toEntity(comic.comicDetails.toEntity()),
      ],
      deletedBookmarks: _journal.deleted(LibraryKind.bookmark),
      deletedHistory: _journal.deleted(LibraryKind.history),
    ).sorted();
  });

  /// Writes through the data sources, not the repositories, so sync's own
  /// writes are not journaled as user edits.
  @override
  Future<Either<Failure, Unit>> writeLocal(SyncSnapshot snapshot) =>
      runLocal(() async {
        final bookmarkSlugs = {for (final b in snapshot.bookmarks) b.slug};
        await _bookmarks.putAll(
          snapshot.bookmarks.map(BookmarkModel.fromEntity).toList(),
        );
        await _bookmarks.deleteAll([
          for (final b in _bookmarks.getAll())
            if (!bookmarkSlugs.contains(b.slug)) b.slug,
        ]);

        final historySlugs = {for (final h in snapshot.history) h.slug};
        final comics = {
          for (final h in snapshot.history)
            h.comicSlug: HistoryComicModel(
              slug: h.comicSlug,
              comicDetails: ComicDetailsModel.fromEntity(h.comicDetails),
            ),
        };
        await _history.putEntries(
          snapshot.history.map(ReadHistoryModel.fromEntity).toList(),
        );
        await _history.putComics(comics.values.toList());
        await _history.deleteEntries([
          for (final e in _history.getEntries())
            if (!historySlugs.contains(e.slug)) e.slug,
        ]);
        await _history.deleteComics([
          for (final slug in _history.getComics().keys)
            if (!comics.containsKey(slug)) slug,
        ]);

        await _journal.replaceDeleted(
          LibraryKind.bookmark,
          snapshot.deletedBookmarks,
        );
        await _journal.replaceDeleted(
          LibraryKind.history,
          snapshot.deletedHistory,
        );
        return unit;
      });

  @override
  Future<Either<Failure, SyncSnapshot?>> download() => _remote(() async {
    final content = await _drive.read();
    return content == null ? null : decode(content);
  });

  @override
  Future<Either<Failure, Unit>> upload(SyncSnapshot snapshot) =>
      _remote(() async {
        await _drive.write(encode(snapshot));
        return unit;
      });

  @override
  DateTime? lastSyncedAt() =>
      switch (int.tryParse(_state.get(_lastSyncedAtKey) ?? '')) {
        final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
        null => null,
      };

  @override
  Future<void> saveLastSyncedAt(DateTime? time) => time == null
      ? _state.delete(_lastSyncedAtKey)
      : _state.put(_lastSyncedAtKey, '${time.millisecondsSinceEpoch}');

  /// Current sync file format. Files with another version are rejected.
  static const formatVersion = 1;

  /// Gzipped JSON: the backup file's library fields plus
  /// `deletedBookmarks` / `deletedHistory` (slug to epoch milliseconds).
  static Uint8List encode(SyncSnapshot snapshot) {
    Map<String, int> dates(Map<String, DateTime> map) => {
      for (final MapEntry(:key, :value) in map.entries)
        key: value.millisecondsSinceEpoch,
    };
    final json = jsonEncode({
      'version': formatVersion,
      ...BackupRepositoryImpl.libraryToJson(
        LibraryBackup(bookmarks: snapshot.bookmarks, history: snapshot.history),
      ),
      'deletedBookmarks': dates(snapshot.deletedBookmarks),
      'deletedHistory': dates(snapshot.deletedHistory),
    });
    return Uint8List.fromList(gzip.encode(utf8.encode(json)));
  }

  static SyncSnapshot decode(Uint8List content) {
    final json =
        jsonDecode(utf8.decode(gzip.decode(content))) as Map<String, dynamic>;
    if (json['version'] != formatVersion) {
      throw FormatException('Unsupported sync version: ${json['version']}');
    }
    Map<String, DateTime> dates(String field) => {
      for (final MapEntry(:key, :value)
          in (json[field] as Map<String, dynamic>? ?? {}).entries)
        key: DateTime.fromMillisecondsSinceEpoch(value as int),
    };
    final library = BackupRepositoryImpl.libraryFromJson(json);
    return SyncSnapshot(
      bookmarks: library.bookmarks,
      history: library.history,
      deletedBookmarks: dates('deletedBookmarks'),
      deletedHistory: dates('deletedHistory'),
    ).sorted();
  }

  /// Maps sign-in and Drive errors to failures.
  static Future<Either<Failure, T>> _remote<T>(
    Future<T> Function() call,
  ) async {
    try {
      return right(await call());
    } on SignedOutException catch (e) {
      return left(AuthFailure(e.toString()));
    } on GoogleSignInException catch (e) {
      return left(AuthFailure(e.toString()));
    } on DioException catch (e) {
      return switch (e.response?.statusCode) {
        401 || 403 => left(AuthFailure(e.toString())),
        null => left(const NetworkFailure()),
        _ => left(ServerFailure(e.toString())),
      };
    } on FormatException catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
