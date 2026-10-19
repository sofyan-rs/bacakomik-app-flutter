import 'dart:convert';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/backup/data/datasources/backup_file_data_source.dart';
import 'package:bacakomik_app/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/backup/domain/repositories/backup_repository.dart';
import 'package:bacakomik_app/features/backup/domain/usecases/backup_library.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/legacy_storage_fixtures.dart';

class MockFiles extends Mock implements BackupFileDataSource {}

class MockBackupRepository extends Mock implements BackupRepository {}

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 3, 4, 5, 6, 7);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const LibraryBackup());
  });

  group('backup file format', () {
    test('reads files written by earlier versions', () {
      final backup = BackupRepositoryImpl.decode(legacyBackupFile());

      expect(backup.bookmarks.single.slug, 'solo-leveling');
      expect(backup.history, hasLength(2));
    });

    test('reads the legacy favorites key', () {
      final backup = BackupRepositoryImpl.decode(
        legacyBackupFile(bookmarkKey: 'favorites'),
      );

      expect(backup.bookmarks.single.slug, 'solo-leveling');
    });

    test('writes the same shape earlier versions wrote', () {
      final backup = BackupRepositoryImpl.decode(legacyBackupFile());

      expect(
        jsonDecode(BackupRepositoryImpl.encode(backup)),
        jsonDecode(legacyBackupFile()),
      );
    });

    test('file name keeps the old pattern', () {
      expect(
        BackupRepositoryImpl.fileName(DateTime(2026, 3, 4, 5, 6, 7)),
        'bacakomik-backup-2026-3-4-567.json',
      );
    });
  });

  group('BackupRepositoryImpl', () {
    late MockFiles files;
    late BackupRepositoryImpl repo;

    setUp(() {
      files = MockFiles();
      repo = BackupRepositoryImpl(files, FixedClock());
    });

    test('export writes into the chosen folder', () async {
      when(() => files.pickDirectory()).thenAnswer((_) async => '/backups');
      when(() => files.writeFile(any(), any())).thenAnswer((_) async {});
      final backup = BackupRepositoryImpl.decode(legacyBackupFile());

      expect(await repo.exportBackup(backup), right(true));
      verify(() => files.writeFile(
            '/backups/bacakomik-backup-2026-3-4-567.json',
            BackupRepositoryImpl.encode(backup),
          )).called(1);
    });

    test('export cancelled', () async {
      when(() => files.pickDirectory()).thenAnswer((_) async => null);

      expect(await repo.exportBackup(const LibraryBackup()), right(false));
    });

    test('import maps bad files to FileFailure', () async {
      when(() => files.pickAndReadJsonFile())
          .thenAnswer((_) async => 'not json');

      final result = await repo.importBackup();

      expect(result.getLeft().toNullable(), isA<FileFailure>());
    });
  });

  group('use cases', () {
    late MockBackupRepository backupRepo;
    late MockBookmarkRepository bookmarks;
    late MockHistoryRepository history;
    final backup = BackupRepositoryImpl.decode(legacyBackupFile());

    setUp(() {
      backupRepo = MockBackupRepository();
      bookmarks = MockBookmarkRepository();
      history = MockHistoryRepository();
    });

    test('backup with an empty library does not open the picker', () async {
      when(() => bookmarks.getBookmarks()).thenAnswer((_) async => right([]));
      when(() => history.getHistory()).thenAnswer((_) async => right([]));

      final result =
          await BackupLibrary(backupRepo, bookmarks, history)(const NoParams());

      expect(result, right(BackupResult.nothingToSave));
      verifyNever(() => backupRepo.exportBackup(any()));
    });

    test('backup exports bookmarks and history', () async {
      when(() => bookmarks.getBookmarks())
          .thenAnswer((_) async => right(backup.bookmarks));
      when(() => history.getHistory())
          .thenAnswer((_) async => right(backup.history));
      when(() => backupRepo.exportBackup(any()))
          .thenAnswer((_) async => right(true));

      final result =
          await BackupLibrary(backupRepo, bookmarks, history)(const NoParams());

      expect(result, right(BackupResult.saved));
      verify(() => backupRepo.exportBackup(backup)).called(1);
    });

    test('restore saves both lists', () async {
      when(() => backupRepo.importBackup())
          .thenAnswer((_) async => right(backup));
      when(() => bookmarks.saveBookmarks(any()))
          .thenAnswer((_) async => right(unit));
      when(() => history.saveHistory(any()))
          .thenAnswer((_) async => right(unit));

      final result =
          await RestoreLibrary(backupRepo, bookmarks, history)(const NoParams());

      expect(result, right(RestoreResult.restored));
      verify(() => bookmarks.saveBookmarks(backup.bookmarks)).called(1);
      verify(() => history.saveHistory(backup.history)).called(1);
    });

    test('restore cancelled', () async {
      when(() => backupRepo.importBackup())
          .thenAnswer((_) async => right(null));

      final result =
          await RestoreLibrary(backupRepo, bookmarks, history)(const NoParams());

      expect(result, right(RestoreResult.cancelled));
    });
  });
}
