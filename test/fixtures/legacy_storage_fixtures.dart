import 'dart:convert';

/// Persisted shapes written by the pre-refactor app. These must keep loading
/// after storage moves to Hive, so do not regenerate them from current code.
const legacyComicDetails = <String, dynamic>{
  'title': 'Solo Leveling',
  'coverImg': 'https://cdn.example/solo.jpg',
  'alternativeTitle': '-',
  'released': '2018',
  'status': 'Completed',
  'totalChapter': '2',
  'author': 'Chugong',
  'type': 'Manhwa',
  'rating': '9',
  'synopsis': 'Hunter story.',
  'genres': [
    {'name': 'Action', 'slug': '1'},
  ],
  'chapters': [
    {'number': '2', 'slug': 'solo-leveling/2', 'date': '-'},
    {'number': '1', 'slug': 'solo-leveling/1', 'date': '-'},
  ],
};

/// Each list entry is itself an encoded JSON string, because the old models'
/// `toJson()` returned `String`.
final legacyBookmarkEntry = jsonEncode({
  'slug': 'solo-leveling',
  'comicDetails': legacyComicDetails,
  'updatedDate': 1700000000000,
});

String legacyHistoryEntry({
  required String slug,
  required String comicSlug,
  required String chapterNumber,
  required int readDate,
}) =>
    jsonEncode({
      'slug': slug,
      'chapterNumber': chapterNumber,
      'readDate': readDate,
      'comicDetails': legacyComicDetails,
      'comicSlug': comicSlug,
    });

/// HydratedStorage value under key `FavoriteCubit`.
Map<String, dynamic> get legacyBookmarkStorage => {
      'bookmarks_comic': [legacyBookmarkEntry],
    };

/// HydratedStorage value under key `HistoryCubit`.
Map<String, dynamic> get legacyHistoryStorage => {
      'history_read': [
        legacyHistoryEntry(
          slug: 'solo-leveling/1',
          comicSlug: 'solo-leveling',
          chapterNumber: '1',
          readDate: 1700000000000,
        ),
        legacyHistoryEntry(
          slug: 'solo-leveling/2',
          comicSlug: 'solo-leveling',
          chapterNumber: '2',
          readDate: 1700000100000,
        ),
      ],
    };

/// HydratedStorage value under key `SettingsCubit`.
const legacySettingsStorage = <String, dynamic>{
  'value': '{"darkMode":"Aktif"}',
};

/// Backup file written by "Backup data". Older files used `favorites`.
String legacyBackupFile({String bookmarkKey = 'bookmarks'}) => jsonEncode({
      bookmarkKey: [legacyBookmarkEntry],
      'history': legacyHistoryStorage['history_read'],
    });
