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
List<MihonSourceGroup> planMihonImport(
  MihonBackup backup,
  List<ExtensionMeta> extensions,
) {
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
) {
  final entries = <String, ImportEntry>{};
  var unreadable = 0;
  for (final m in manga) {
    final slug = source?.slugFromUrl(m.url);
    if (source == null || slug == null) {
      unreadable++;
      continue;
    }
    final key = ComicKey.of(source.id, slug);
    entries[key] ??= ImportEntry(
      key: key,
      title: m.title,
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
