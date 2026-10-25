import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';

/// Reads the parts of a Mihon/Tachiyomi backup the import needs (forks such
/// as TachiyomiSY add fields, which are skipped). The file
/// is a gzipped protobuf `Backup` message; only these fields are read:
///
/// ```proto
/// message Backup         { repeated BackupManga backupManga = 1;
///                          repeated BackupCategory backupCategories = 2;
///                          repeated BackupSource backupSources = 101; }
/// message BackupManga    { int64 source = 1; string url = 2; string title = 3;
///                          repeated BackupChapter chapters = 16;
///                          repeated int64 categories = 17;  // category orders
///                          bool favorite = 100;             // default true
///                          repeated BrokenBackupHistory brokenHistory = 102;
///                          repeated BackupHistory history = 104; }
/// message BackupChapter  { string url = 1; bool read = 4;
///                          int64 dateFetch = 7; int64 dateUpload = 8; // ms
///                          float chapterNumber = 9; }       // default 0
/// message BackupHistory  { string url = 1; int64 lastRead = 2; }  // ms
/// message BrokenBackupHistory { string url = 0; int64 lastRead = 1; }
/// message BackupCategory { string name = 1; int64 order = 2; }
/// message BackupSource   { string name = 1; int64 sourceId = 2; }
/// ```
///
/// Throws [FormatException] when [bytes] is not such a file.
MihonBackup parseMihonBackup(List<int> bytes) {
  final data = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b
      ? gzip.decode(bytes)
      : bytes;
  final manga = <MihonManga>[];
  final sourceNames = <int, String>{};
  final categories = <int, String>{};
  for (final field in _Reader(Uint8List.fromList(data)).fields()) {
    switch (field.number) {
      case 1:
        manga.add(_manga(field.bytes));
      case 2:
        final c = _category(field.bytes);
        categories[c.order] = c.name;
      case 101:
        final s = _source(field.bytes);
        sourceNames[s.id] = s.name;
    }
  }
  if (manga.isEmpty && sourceNames.isEmpty) {
    throw const FormatException('Not a Mihon backup');
  }
  return MihonBackup(
    manga: manga,
    sourceNames: sourceNames,
    categories: categories,
  );
}

MihonManga _manga(Uint8List bytes) {
  var source = 0;
  var url = '';
  var title = '';
  var favorite = true;
  final categories = <int>[];
  final chapters = <MihonChapter>[];
  final history = <String, DateTime>{};
  for (final f in _Reader(bytes).fields()) {
    switch (f.number) {
      case 16:
        chapters.add(_chapter(f.bytes));
      case 104 || 102:
        if (_history(f.bytes, legacy: f.number == 102)
            case (final chapter, final date) when chapter.isNotEmpty) {
          if (history[chapter] case final seen? when seen.isAfter(date)) {
            continue;
          }
          history[chapter] = date;
        }
      case 1:
        source = f.value;
      case 2:
        url = f.text;
      case 3:
        title = f.text;
      case 17:
        // Packed or not, depending on the writer.
        if (f.wireType == _Reader.lengthDelimited) {
          final r = _Reader(f.bytes);
          while (!r.done) {
            categories.add(r.varint());
          }
        } else {
          categories.add(f.value);
        }
      case 100:
        favorite = f.value != 0;
    }
  }
  return MihonManga(
    sourceId: source,
    url: url,
    title: title,
    favorite: favorite,
    categories: categories,
    chapters: chapters,
    history: history,
  );
}

MihonChapter _chapter(Uint8List bytes) {
  var url = '';
  var read = false;
  // Left out when 0, like every default value.
  var number = 0.0;
  DateTime? fetched;
  DateTime? uploaded;
  for (final f in _Reader(bytes).fields()) {
    switch (f.number) {
      case 1:
        url = f.text;
      case 4:
        read = f.value != 0;
      case 7:
        fetched = _date(f.value);
      case 8:
        uploaded = _date(f.value);
      case 9 when f.bytes.length == 4:
        number = ByteData.sublistView(f.bytes).getFloat32(0, Endian.little);
    }
  }
  return MihonChapter(
    url: url,
    number: number,
    read: read,
    fetched: fetched,
    uploaded: uploaded,
  );
}

/// A history entry: chapter url and when it was last read. The legacy
/// form (field 102) numbered its fields from 0.
(String, DateTime)? _history(Uint8List bytes, {required bool legacy}) {
  var url = '';
  DateTime? lastRead;
  final (urlField, dateField) = legacy ? (0, 1) : (1, 2);
  for (final f in _Reader(bytes).fields()) {
    if (f.number == urlField && f.wireType == _Reader.lengthDelimited) {
      url = f.text;
    }
    if (f.number == dateField && f.wireType == _Reader.varintType) {
      lastRead = _date(f.value);
    }
  }
  return lastRead == null ? null : (url, lastRead);
}

/// Epoch milliseconds; null for 0 or out of range.
DateTime? _date(int ms) => ms > 0 && ms < 8640000000000000
    ? DateTime.fromMillisecondsSinceEpoch(ms)
    : null;

({String name, int order}) _category(Uint8List bytes) {
  var name = '';
  var order = 0;
  for (final f in _Reader(bytes).fields()) {
    if (f.number == 1) name = f.text;
    if (f.number == 2) order = f.value;
  }
  return (name: name, order: order);
}

({String name, int id}) _source(Uint8List bytes) {
  var name = '';
  var id = 0;
  for (final f in _Reader(bytes).fields()) {
    if (f.number == 1) name = f.text;
    if (f.number == 2) id = f.value;
  }
  return (name: name, id: id);
}

class _Field {
  const _Field(this.number, this.wireType, this.value, this.bytes);

  final int number;
  final int wireType;

  /// Varint value; 0 for other wire types.
  final int value;

  /// Length-delimited content, or the 4 bytes of a fixed32; empty for
  /// other wire types.
  final Uint8List bytes;

  String get text => utf8.decode(bytes, allowMalformed: true);
}

/// Protobuf wire format reader.
class _Reader {
  _Reader(this._bytes);

  static const varintType = 0;
  static const fixed64 = 1;
  static const lengthDelimited = 2;
  static const fixed32 = 5;

  final Uint8List _bytes;
  var _i = 0;

  bool get done => _i >= _bytes.length;

  Iterable<_Field> fields() sync* {
    while (!done) {
      final key = varint();
      final number = key >> 3;
      final type = key & 7;
      switch (type) {
        case varintType:
          yield _Field(number, type, varint(), Uint8List(0));
        case lengthDelimited:
          final length = varint();
          if (length < 0 || _i + length > _bytes.length) {
            throw const FormatException('Truncated backup');
          }
          yield _Field(
            number,
            type,
            0,
            Uint8List.sublistView(_bytes, _i, _i += length),
          );
        case fixed64:
          _skip(8);
        case fixed32:
          _skip(4);
          yield _Field(
            number,
            type,
            0,
            Uint8List.sublistView(_bytes, _i - 4, _i),
          );
        default:
          throw FormatException('Unknown wire type $type');
      }
    }
  }

  int varint() {
    var result = 0;
    var shift = 0;
    while (true) {
      if (done) throw const FormatException('Truncated backup');
      final b = _bytes[_i++];
      if (shift < 64) result |= (b & 0x7f) << shift;
      if (b < 0x80) return result;
      shift += 7;
    }
  }

  void _skip(int n) {
    if (_i + n > _bytes.length) throw const FormatException('Truncated backup');
    _i += n;
  }
}
