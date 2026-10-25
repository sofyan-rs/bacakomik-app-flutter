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

/// What [SyncRepositoryImpl.readLocal] read: the stored JSON, and per kind
/// the journal's deletions and save-again times.
typedef _LocalRead = ({
  LocalLibraryJson json,
  LocalDeletions deleted,
  LocalDeletions saved,
});

@LazySingleton(as: SyncRepository)
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(
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

  /// The last [readLocal], which [writeLocal] applies its changes to.
  _LocalRead? _lastRead;

  static const _lastSyncedAtKey = 'lastSyncedAt';

  /// Set while signed in. On Android a restore attempt can show the account
  /// picker, so it is only made after an earlier sign-in.
  static const _accountKey = 'account';

  @override
  String? storedAccount() => _state.get(_accountKey);

  /// Fails, keeping the stored account, when the account could not be
  /// restored (offline, Play services busy, a platform error): that is not a
  /// sign-out.
  @override
  Future<Either<Failure, String?>> restoreAccount() async {
    if (storedAccount() == null) return right(null);
    final restored = await _remote(_auth.restore);
    return restored.flatMap(
      (email) => email == null
          ? left(const ServerFailure('Google account not restored'))
          : right(email),
    );
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
    final saved = (
      bookmarks: _journal.saved(LibraryKind.bookmark),
      history: _journal.saved(LibraryKind.history),
      categories: _journal.saved(LibraryKind.category),
    );
    _lastRead = (json: json, deleted: deleted, saved: saved);
    return _decodeLocalInBackground(json, deleted, saved);
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
  ///
  /// Changes apply to what the last [readLocal] read: a record saved or
  /// deleted since (while the sync downloaded and merged) is left as it is,
  /// and a key added since is not deleted. That edit fired a change, so the
  /// next sync sends it.
  @override
  Future<Either<Failure, Unit>> writeLocal(SyncSnapshot snapshot) => runLocal(
    () async {
      final base = _lastRead;
      _lastRead = null;
      final json = await _encodeLocalInBackground(snapshot);
      final since = base?.json;
      await _bookmarks.raw.replaceRaw(json.bookmarks, since: since?.bookmarks);
      await _history.rawEntries.replaceRaw(json.entries, since: since?.entries);
      await _history.rawComics.replaceRaw(json.comics, since: since?.comics);
      await _categories.rawCategories.replaceRaw(
        json.categories,
        since: since?.categories,
      );
      await _categories.rawComicCategories.replaceRaw(
        json.comicCategories,
        since: since?.comicCategories,
      );

      await _journal.replaceSynced(
        LibraryKind.bookmark,
        deleted: snapshot.deletedBookmarks,
        saved: snapshot.savedBookmarks,
        since: base == null
            ? null
            : (deleted: base.deleted.bookmarks, saved: base.saved.bookmarks),
      );
      await _journal.replaceSynced(
        LibraryKind.history,
        deleted: snapshot.deletedHistory,
        saved: snapshot.savedHistory,
        since: base == null
            ? null
            : (deleted: base.deleted.history, saved: base.saved.history),
      );
      await _journal.replaceSynced(
        LibraryKind.category,
        deleted: snapshot.deletedCategories,
        saved: snapshot.savedCategories,
        since: base == null
            ? null
            : (deleted: base.deleted.categories, saved: base.saved.categories),
      );
      return unit;
    },
  );

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
    LocalDeletions saved,
  ) => Isolate.run(() => decodeLocal(json, deleted, saved: saved));

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
    LocalDeletions deleted, {
    LocalDeletions? saved,
  }) {
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
      savedBookmarks: saved?.bookmarks ?? const {},
      savedHistory: saved?.history ?? const {},
      savedCategories: saved?.categories ?? const {},
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
  /// id to epoch milliseconds), and `savedBookmarks` / `savedHistory` /
  /// `savedCategories` (same shape: deleted entries saved again, written
  /// only when not empty). Category and saved fields were added without a
  /// new version: older app versions ignore them, and [SyncSnapshot.merge]
  /// keeps categories when such a version uploads a copy without them.
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
      if (snapshot.savedBookmarks.isNotEmpty)
        'savedBookmarks': dates(snapshot.savedBookmarks),
      if (snapshot.savedHistory.isNotEmpty)
        'savedHistory': dates(snapshot.savedHistory),
      if (snapshot.savedCategories.isNotEmpty)
        'savedCategories': dates(snapshot.savedCategories),
    });
    return Uint8List.fromList(gzip.encode(utf8.encode(json)));
  }

  static SyncSnapshot decode(Uint8List content) {
    final json =
        jsonDecode(utf8.decode(gzip.decode(content))) as Map<String, dynamic>;
    if (json['version'] != formatVersion) {
      throw FormatException('Unsupported sync version: ${json['version']}');
    }
    // A value that is not a time is skipped.
    Map<String, DateTime> dates(String field) => {
      if (json[field] case final Map<String, dynamic> map)
        for (final MapEntry(:key, :value) in map.entries)
          if (value case final int ms)
            key: DateTime.fromMillisecondsSinceEpoch(ms),
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
      savedBookmarks: dates('savedBookmarks'),
      savedHistory: dates('savedHistory'),
      savedCategories: dates('savedCategories'),
    ).sorted();
  }

  /// Maps sign-in and Drive errors to failures. Any other error (a
  /// platform error from sign-in, a file that does not decode) is a
  /// [ServerFailure].
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
      return left(driveFailure(e));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  /// Drive answers 403 for lost access but also for quotas and rate
  /// limits; only the first means signed out. The reason is in the error
  /// body: `{"error": {"errors": [{"reason": "insufficientPermissions"}]}}`.
  @visibleForTesting
  static Failure driveFailure(DioException e) {
    final response = e.response;
    return switch (response?.statusCode) {
      null => const NetworkFailure(),
      401 => AuthFailure(e.toString()),
      403 when _errorReasons(response!.data).any(_authReasons.contains) =>
        AuthFailure(e.toString()),
      _ => ServerFailure(e.toString()),
    };
  }

  static const _authReasons = {'insufficientPermissions', 'authError'};

  /// `error.errors[].reason` of a Drive error body (JSON, as bytes, text or
  /// decoded); empty when there is none.
  static Set<String> _errorReasons(Object? body) {
    try {
      final json = switch (body) {
        final List<int> bytes => jsonDecode(utf8.decode(bytes)),
        final String text => jsonDecode(text),
        _ => body,
      };
      if (json case {'error': {'errors': final List<Object?> errors}}) {
        return {
          for (final error in errors)
            if (error case {'reason': final String reason}) reason,
        };
      }
    } on Object {
      // Not JSON: no reason.
    }
    return const {};
  }
}
