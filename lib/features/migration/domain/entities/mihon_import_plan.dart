import 'dart:convert';

import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/features/migration/domain/entities/library_import.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:crypto/crypto.dart';

/// The library comics of one Mihon source.
class MihonSourceGroup {
  const MihonSourceGroup({
    required this.name,
    required this.source,
    required this.entries,
    required this.unreadable,
  });

  /// Source name in Mihon.
  final String name;

  /// The matching source here; null when no extension matches.
  final ExtensionMeta? source;

  /// Comics whose link the source could read.
  final List<ImportEntry> entries;

  /// Comics whose link it could not read, or every comic of a source
  /// without a match.
  final int unreadable;

  /// Unique per group: two languages of MangaDex share [name].
  String get id => source?.id ?? name;

  bool get supported => source != null && entries.isNotEmpty;

  int get total => entries.length + unreadable;
}

/// Groups the backup's library comics by source and matches each source to
/// one of [extensions] (installed and offered by the repos). Groups with a
/// match come first, biggest first.
///
/// Sources match by name, ignoring case, spacing and punctuation. For a
/// multi-language extension the language comes from the Mihon source id,
/// which is the MD5 of `<name>/<lang>/<version>`.
///
/// Each entry carries the comic's chapters with read dates; see
/// [importChapters]. [now] stands in for dates the backup lacks.
List<MihonSourceGroup> planMihonImport(
  MihonBackup backup,
  List<ExtensionMeta> extensions, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final byName = <String, ExtensionMeta>{};
  for (final e in extensions) {
    final key = normalizeName(e.name);
    final seen = byName[key];
    // Prefer the copy that can read links, then the newer one.
    final better = switch ((seen?.urlPatterns.isEmpty, e.urlPatterns.isEmpty)) {
      (null, _) => true,
      (true, false) => true,
      (false, true) => false,
      _ => e.isNewerThan(seen!),
    };
    if (better) byName[key] = e;
  }

  final mangaBySource = <int, List<MihonManga>>{};
  for (final m in backup.manga) {
    if (m.favorite) (mangaBySource[m.sourceId] ??= []).add(m);
  }

  final groups = [
    for (final MapEntry(key: sourceId, value: manga) in mangaBySource.entries)
      if (backup.sourceNames[sourceId] ?? '' case final name)
        _group(
          backup,
          name.isEmpty ? '$sourceId' : name,
          manga,
          _sourceFor(byName[normalizeName(name)], name, sourceId),
          at,
        ),
  ];
  return groups..sort((a, b) {
    if (a.supported != b.supported) return a.supported ? -1 : 1;
    return b.total.compareTo(a.total);
  });
}

MihonSourceGroup _group(
  MihonBackup backup,
  String name,
  List<MihonManga> manga,
  ExtensionMeta? source,
  DateTime now,
) {
  final entries = <String, ImportEntry>{};
  var unreadable = 0;
  for (final m in manga) {
    final slug = source?.slugFromUrl(m.url);
    final key = source == null || slug == null
        ? null
        : ComicKey.of(source.id, slug);
    // A key too long for storage would corrupt the library.
    if (key == null || !ComicKey.storable(key)) {
      unreadable++;
      continue;
    }
    entries[key] ??= ImportEntry(
      key: key,
      title: m.title,
      chapters: importChapters(m, now),
      categories: [for (final order in m.categories) ?backup.categories[order]],
    );
  }
  return MihonSourceGroup(
    name: name,
    source: source,
    entries: entries.values.toList(),
    unreadable: unreadable,
  );
}

/// The numbered chapters of [manga], newest first, one per number, with
/// when each read one was read, so the history orders like Mihon's:
///
/// * A chapter in Mihon's history keeps that date.
/// * Read chapters newer than the newest one with a date (all of them when
///   none has one) come right after it, 1 ms apart, the newest last. With
///   no history at all they count from when Mihon fetched the newest of
///   them, or [now].
/// * Older read chapters without a date come right before the next newer
///   one, 1 ms apart, so the newest read chapter stays the latest and the
///   comic sorts by its real last read.
List<ImportChapter> importChapters(MihonManga manga, DateTime now) {
  final byNumber = <String, _Merged>{};
  for (final c in manga.chapters) {
    if (!c.numbered) continue;
    final merged = byNumber[c.numberText] ??= _Merged(c);
    merged.read |= c.read;
    merged.uploaded ??= c.uploaded;
    if (manga.history[c.url] case final date?
        when merged.history?.isAfter(date) != true) {
      merged.history = date;
    }
  }
  final chapters = byNumber.values.toList()
    ..sort((a, b) => b.chapter.number.compareTo(a.chapter.number));

  final read = [
    for (final c in chapters)
      if (c.read) c,
  ];
  if (read.isNotEmpty) {
    var anchor = read.indexWhere((c) => c.history != null);
    final DateTime anchorDate;
    if (anchor < 0) {
      anchor = read.length - 1;
      final fetched = read.first.chapter.fetched;
      anchorDate = (fetched == null || fetched.isAfter(now) ? now : fetched)
          .subtract(Duration(milliseconds: anchor));
    } else {
      anchorDate = read[anchor].history!;
    }
    for (var i = 0; i < anchor; i++) {
      read[i].date = anchorDate.add(Duration(milliseconds: anchor - i));
    }
    read[anchor].date = anchorDate;
    var floor = anchorDate;
    for (final c in read.skip(anchor + 1)) {
      if (c.history case final date?) {
        if (date.isBefore(floor)) floor = date;
        c.date = date;
      } else {
        floor = floor.subtract(const Duration(milliseconds: 1));
        c.date = floor;
      }
    }
  }
  return [
    for (final c in chapters)
      ImportChapter(
        number: c.chapter.numberText,
        uploaded: c.uploaded,
        readDate: c.date,
      ),
  ];
}

class _Merged {
  _Merged(this.chapter);

  final MihonChapter chapter;
  bool read = false;
  DateTime? uploaded;
  DateTime? history;

  /// Read date given by [importChapters].
  DateTime? date;
}

/// [extension] itself, or the language of it whose Mihon id is [mihonId].
ExtensionMeta? _sourceFor(ExtensionMeta? extension, String name, int mihonId) {
  if (extension == null || extension.languages.isEmpty) return extension;
  for (final lang in extension.languages) {
    for (final code in {lang, ...?_mihonLangs[lang]}) {
      if (mihonSourceId(name, code) == mihonId) {
        return extension.forLanguage(lang);
      }
    }
  }
  return null;
}

/// Mihon's codes for languages whose code differs from MangaDex's.
const _mihonLangs = {
  'pt-br': ['pt-BR'],
  'es-la': ['es-419'],
  'zh-hk': ['zh-Hant', 'zh-HK'],
};

/// Mihon's id of the source [name] in [lang]: the first 8 bytes of
/// MD5(`<name lowercase>/<lang>/<versionId>`), sign bit cleared.
int mihonSourceId(String name, String lang, [int versionId = 1]) {
  final digest = md5
      .convert(utf8.encode('${name.toLowerCase()}/$lang/$versionId'))
      .bytes;
  var id = 0;
  for (var i = 0; i < 8; i++) {
    id = (id << 8) | digest[i];
  }
  return id & 0x7fffffffffffffff;
}

/// `West Manga` and `WestManga` are the same source.
String normalizeName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
