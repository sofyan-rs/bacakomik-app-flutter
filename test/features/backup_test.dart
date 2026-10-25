import 'dart:convert';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/backup/data/datasources/backup_file_data_source.dart';
import 'package:bacakomik_app/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/backup/domain/repositories/backup_repository.dart';
import 'package:bacakomik_app/features/backup/domain/usecases/backup_library.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/library_fixtures.dart';

class MockFiles extends Mock implements BackupFileDataSource {}

class MockBackupRepository extends Mock implements BackupRepository {}

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 3, 4, 5, 6, 7);
}

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

ReadHistory read(int chapter) => ReadHistory(
  slug: 'solo-leveling/$chapter',
  chapterNumber: '$chapter',
  readDate: at(1700000000000 + chapter),
  comicDetails: sampleComicDetails,
  comicSlug: 'solo-leveling',
);

final sampleBackup = LibraryBackup(
  bookmarks: [
    Bookmark(
      slug: 'solo-leveling',
      comicDetails: sampleComicDetails,
      updatedDate: at(1700000000000),
    ),
  ],
  history: [read(2), read(1)],
);

void main() {
  setUpAll(() {
    registerFallbackValue(const LibraryBackup());
  });

  group('backup file format', () {
    test('round-trips bookmarks and history', () {
      expect(
        BackupRepositoryImpl.decode(BackupRepositoryImpl.encode(sampleBackup)),
        sampleBackup,
      );
    });

    test('round-trips added dates', () {
      final backup = sampleBackup.copyWith(
        bookmarks: [
          for (final b in sampleBackup.bookmarks)
            b.copyWith(addedDate: at(1600000000000)),
        ],
      );

      expect(
        BackupRepositoryImpl.decode(BackupRepositoryImpl.encode(backup)),
        backup,
      );
    });

    test('bookmarks without an added date leave it out', () {
      final json = jsonDecode(
        BackupRepositoryImpl.encode(sampleBackup),
      ) as Map<String, dynamic>;

      expect((json['bookmarks'] as List).single, isNot(contains('addedDate')));
    });

    test('writes each history comic once', () {
      final json = jsonDecode(
        BackupRepositoryImpl.encode(sampleBackup),
      ) as Map<String, dynamic>;

      expect(json['version'], BackupRepositoryImpl.formatVersion);
      expect(json['history'], hasLength(2));
      expect(json['historyComics'], hasLength(1));
      expect((json['history'] as List).first, isNot(contains('comicDetails')));
    });

    test('rejects files without the current version', () {
      expect(
        () => BackupRepositoryImpl.decode(jsonEncode({'bookmarks': []})),
        throwsFormatException,
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
      final backup = sampleBackup;

      expect(await repo.exportBackup(backup), right(true));
      verify(
        () => files.writeFile(
          '/backups/bacakomik-backup-2026-3-4-567.json',
          BackupRepositoryImpl.encode(backup),
        ),
      ).called(1);
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
    late MockCategoryRepository categories;
    final backup = sampleBackup;

    setUp(() {
      backupRepo = MockBackupRepository();
      bookmarks = MockBookmarkRepository();
      history = MockHistoryRepository();
      categories = MockCategoryRepository();
      when(() => categories.getCategories()).thenAnswer((_) async => right([]));
      when(() => categories.getComicCategories())
          .thenAnswer((_) async => right({}));
    });

    test('backup with an empty library does not open the picker', () async {
      when(() => bookmarks.getBookmarks()).thenAnswer((_) async => right([]));
      when(() => history.getHistory()).thenAnswer((_) async => right([]));

      final result = await BackupLibrary(
        backupRepo,
        bookmarks,
        history,
        categories,
      )(const NoParams());

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

      final result = await BackupLibrary(
        backupRepo,
        bookmarks,
        history,
        categories,
      )(const NoParams());

      expect(result, right(BackupResult.saved));
      verify(() => backupRepo.exportBackup(backup)).called(1);
    });

    test('restore saves both lists', () async {
      when(() => backupRepo.importBackup())
          .thenAnswer((_) async => right(backup));
      when(() => bookmarks.getBookmarks()).thenAnswer((_) async => right([]));
      when(() => bookmarks.saveBookmarks(any()))
          .thenAnswer((_) async => right(unit));
      when(() => history.saveHistory(any()))
          .thenAnswer((_) async => right(unit));

      final result = await RestoreLibrary(
        backupRepo,
        bookmarks,
        history,
        categories,
      )(const NoParams());

      expect(result, right(RestoreResult.restored));
      verify(() => bookmarks.saveBookmarks(backup.bookmarks)).called(1);
      verify(() => history.saveHistory(backup.history)).called(1);
    });

    test('restore keeps added dates the backup lacks', () async {
      final stored = backup.bookmarks.single.copyWith(addedDate: at(5));
      when(() => backupRepo.importBackup())
          .thenAnswer((_) async => right(backup));
      when(() => bookmarks.getBookmarks())
          .thenAnswer((_) async => right([stored]));
      when(() => bookmarks.saveBookmarks(any()))
          .thenAnswer((_) async => right(unit));
      when(() => history.saveHistory(any()))
          .thenAnswer((_) async => right(unit));

      await RestoreLibrary(backupRepo, bookmarks, history, categories)(
        const NoParams(),
      );

      verify(
        () => bookmarks.saveBookmarks([
          backup.bookmarks.single.copyWith(addedDate: at(5)),
        ]),
      ).called(1);
    });

    test('restore cancelled', () async {
      when(() => backupRepo.importBackup())
          .thenAnswer((_) async => right(null));

      final result = await RestoreLibrary(
        backupRepo,
        bookmarks,
        history,
        categories,
      )(const NoParams());

      expect(result, right(RestoreResult.cancelled));
    });
  });
}
