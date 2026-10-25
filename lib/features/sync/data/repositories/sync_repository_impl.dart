import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/category/data/datasources/category_local_data_source.dart';
import 'package:bacakomik_app/features/category/data/models/category_model.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:bacakomik_app/features/sync/data/datasources/drive_data_source.dart';
import 'package:bacakomik_app/features/sync/data/datasources/google_auth_data_source.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// The stored JSON of the synced boxes, by key.
typedef LocalLibraryJson = ({
  Map<String, String> bookmarks,
  Map<String, String> entries,
  Map<String, String> comics,
  Map<String, String> categories,
  Map<String, String> comicCategories,
});

/// Deletion times from the journal, per kind.
typedef LocalDeletions = ({
  Map<String, DateTime> bookmarks,
  Map<String, DateTime> history,
  Map<String, DateTime> categories,
});

@LazySingleton(as: SyncRepository)
class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl(
    this._auth,
    this._drive,
    this._bookmarks,
    this._history,
    this._categories,
    this._journal,
    @Named(HiveBoxes.sync) this._state,
  );

  final GoogleAuthDataSource _auth;
  final DriveDataSource _drive;
  final BookmarkLocalDataSource _bookmarks;
  final HistoryLocalDataSource _history;
  final CategoryLocalDataSource _categories;
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

  /// Reads the stored JSON here (cheap) and decodes it in a background
  /// isolate: the whole library is too much to decode on the UI isolate.
  @override
  Future<Either<Failure, SyncSnapshot>> readLocal() => runLocal(() {
    final json = (
      bookmarks: _bookmarks.raw.readRaw(),
      entries: _history.rawEntries.readRaw(),
      comics: _history.rawComics.readRaw(),
      categories: _categories.rawCategories.readRaw(),
      comicCategories: _categories.rawComicCategories.readRaw(),
    );
    final deleted = (
      bookmarks: _journal.deleted(LibraryKind.bookmark),
      history: _journal.deleted(LibraryKind.history),
      categories: _journal.deleted(LibraryKind.category),
    );
    return _decodeLocalInBackground(json, deleted);
  });

  @override
  Future<Either<Failure, bool>> anyLocalComic({
    required bool Function(String key) where,
    required bool Function(String key, ComicDetails details) test,
  }) => runLocal(() {
    for (final key in _bookmarks.raw.keys.where(where).toList()) {
      if (_bookmarks.get(key) case final b?
          when test(key, b.comicDetails.toEntity())) {
        return true;
      }
    }
    for (final key in _history.rawComics.keys.where(where).toList()) {
      if (_history.getComic(key) case final c?
          when test(key, c.comicDetails.toEntity())) {
        return true;
      }
    }
    return false;
  });

  /// Writes through the data sources, not the repositories, so sync's own
  /// writes are not journaled as user edits. Records are encoded in a
  /// background isolate; only those whose JSON changed are written, and
  /// keys missing from [snapshot] are deleted.
  @override
  Future<Either<Failure, Unit>> writeLocal(SyncSnapshot snapshot) =>
      runLocal(() async {
        final json = await _encodeLocalInBackground(snapshot);
        await _bookmarks.raw.replaceRaw(json.bookmarks);
        await _history.rawEntries.replaceRaw(json.entries);
        await _history.rawComics.replaceRaw(json.comics);
        await _categories.rawCategories.replaceRaw(json.categories);
        await _categories.rawComicCategories.replaceRaw(json.comicCategories);

        await _journal.replaceDeleted(
          LibraryKind.bookmark,
          snapshot.deletedBookmarks,
        );
        await _journal.replaceDeleted(
          LibraryKind.history,
          snapshot.deletedHistory,
        );
        await _journal.replaceDeleted(
          LibraryKind.category,
          snapshot.deletedCategories,
        );
        return unit;
      });

  @override
  Future<Either<Failure, SyncSnapshot?>> download() => _remote(() async {
    final content = await _drive.read();
    return content == null ? null : await _decodeInBackground(content);
  });

  @override
  Future<Either<Failure, Unit>> upload(SyncSnapshot snapshot) =>
      _remote(() async {
        await _drive.write(await _encodeInBackground(snapshot));
        return unit;
      });

  // Heavy work runs in a new isolate. The closures are made in static
  // functions so they capture only their arguments, not this repository
  // (its Hive boxes cannot be sent to another isolate).

  static Future<SyncSnapshot> _decodeLocalInBackground(
    LocalLibraryJson json,
    LocalDeletions deleted,
  ) => Isolate.run(() => decodeLocal(json, deleted));

  static Future<LocalLibraryJson> _encodeLocalInBackground(
    SyncSnapshot snapshot,
  ) => Isolate.run(() => encodeLocal(snapshot));

  static Future<SyncSnapshot> _decodeInBackground(Uint8List content) =>
      Isolate.run(() => decode(content));

  static Future<Uint8List> _encodeInBackground(SyncSnapshot snapshot) =>
      Isolate.run(() => encode(snapshot));

  /// The library as stored: JSON string per key, for each box.
  @visibleForTesting
  static SyncSnapshot decodeLocal(
    LocalLibraryJson json,
    LocalDeletions deleted,
  ) {
    List<T> all<T>(
      String box,
      Map<String, String> records,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final result = <T>[];
      for (final MapEntry(:key, :value) in records.entries) {
        try {
          result.add(fromJson(jsonDecode(value) as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Skipping unreadable $box entry $key: $e');
        }
      }
      return result;
    }

    // One details object per comic, shared by its entries.
    final comics = {
      for (final c in all(
        HiveBoxes.historyComics,
        json.comics,
        HistoryComicModel.fromJson,
      ))
        c.slug: c.comicDetails.toEntity(),
    };
    return SyncSnapshot(
      bookmarks: [
        for (final b in all(
          HiveBoxes.bookmarks,
          json.bookmarks,
          BookmarkModel.fromJson,
        ))
          b.toEntity(),
      ],
      history: [
        for (final entry in all(
          HiveBoxes.historyEntries,
          json.entries,
          ReadHistoryModel.fromJson,
        ))
          if (comics[entry.comicSlug] case final details?)
            entry.toEntity(details),
      ],
      deletedBookmarks: deleted.bookmarks,
      deletedHistory: deleted.history,
      categories: [
        for (final c in all(
          HiveBoxes.categories,
          json.categories,
          CategoryModel.fromJson,
        ))
          c.toEntity(),
      ],
      comicCategories: [
        for (final c in all(
          HiveBoxes.comicCategories,
          json.comicCategories,
          ComicCategoriesModel.fromJson,
        ))
          c.toEntity(),
      ],
      deletedCategories: deleted.categories,
    ).sorted();
  }

  /// [snapshot] as the JSON each box stores, by key; the same strings the
  /// data sources write.
  @visibleForTesting
  static LocalLibraryJson encodeLocal(SyncSnapshot snapshot) => (
    bookmarks: {
      for (final b in snapshot.bookmarks)
        b.slug: jsonEncode(BookmarkModel.fromEntity(b).toJson()),
    },
    entries: {
      for (final h in snapshot.history)
        h.slug: jsonEncode(ReadHistoryModel.fromEntity(h).toJson()),
    },
    // Each comic once, with the details of its last entry.
    comics: {
      for (final MapEntry(key: slug, value: details) in {
        for (final h in snapshot.history) h.comicSlug: h.comicDetails,
      }.entries)
        slug: jsonEncode(
          HistoryComicModel(
            slug: slug,
            comicDetails: ComicDetailsModel.fromEntity(details),
          ).toJson(),
        ),
    },
    categories: {
      for (final c in snapshot.categories)
        c.id: jsonEncode(CategoryModel.fromEntity(c).toJson()),
    },
    comicCategories: {
      for (final c in snapshot.comicCategories)
        c.slug: jsonEncode(ComicCategoriesModel.fromEntity(c).toJson()),
    },
  );

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
  /// `deletedBookmarks` / `deletedHistory` / `deletedCategories` (slug or
  /// id to epoch milliseconds). Category fields were added without a new
  /// version: older app versions ignore them, and [SyncSnapshot.merge] keeps
  /// them when such a version uploads a copy without them.
  static Uint8List encode(SyncSnapshot snapshot) {
    Map<String, int> dates(Map<String, DateTime> map) => {
      for (final MapEntry(:key, :value) in map.entries)
        key: value.millisecondsSinceEpoch,
    };
    final json = jsonEncode({
      'version': formatVersion,
      ...BackupRepositoryImpl.libraryToJson(
        LibraryBackup(
          bookmarks: snapshot.bookmarks,
          history: snapshot.history,
          categories: snapshot.categories,
          comicCategories: snapshot.comicCategories,
        ),
      ),
      'deletedBookmarks': dates(snapshot.deletedBookmarks),
      'deletedHistory': dates(snapshot.deletedHistory),
      'deletedCategories': dates(snapshot.deletedCategories),
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
      categories: library.categories,
      comicCategories: library.comicCategories,
      deletedCategories: dates('deletedCategories'),
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
