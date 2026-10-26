import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bacakomik_app/core/source/extension_meta.dart';

/// Mihon 0.20.1+ "extension store" index (`index_v2` in a repo's
/// `repo.json`): a protobuf message, often gzipped. The repo's
/// `index.min.json` then only lists a stub asking to update the app.
///
/// ```
/// Store     { 1 name, 2 badge, 3 signingKey, 4 contact,
///             101 ExtensionList, 102 extensionListUrl }
/// ExtensionList { repeated 1 Extension }
/// Extension { 1 name, 2 packageName, 3 Resources {1 apkUrl, 2 iconUrl},
///             4 extensionLib, 5 versionCode, 6 versionName,
///             7 contentWarning (0 unset, 1 safe, 2 mixed, 3 NSFW),
///             8 repeated Source }
/// Source    { 1 id, 2 name, 3 language, 4 homeUrl }
/// ```
///
/// Field numbers as SCANCORE reads them (src/extensions/Index.cpp).
abstract final class MihonStore {
  /// The store's signing key, its extensions (null when it links to a
  /// list instead) and that link.
  static ({
    String? signingKey,
    List<StoreExtension>? extensions,
    String? listUrl,
  })
  parse(List<int> data) {
    final bytes = _gunzip(data);
    String? key;
    String? listUrl;
    List<StoreExtension>? extensions;
    // Only a store has its extensions (101) or their link (102); a bare
    // list has nothing but field 1, which a store's name shares.
    var isStore = false;
    final r = _Proto(bytes);
    while (r.next()) {
      switch (r.field) {
        case 3:
          key = r.text();
        case 101:
          isStore = true;
          extensions = _list(r.bytes());
        case 102:
          isStore = true;
          listUrl = r.text();
        default:
          r.skip();
      }
    }
    if (!isStore) {
      return (signingKey: null, extensions: _list(bytes), listUrl: null);
    }
    return (signingKey: key, extensions: extensions, listUrl: listUrl);
  }

  /// An extension list on its own (a store's `extensionListUrl`).
  static List<StoreExtension> parseList(List<int> data) => _list(_gunzip(data));

  /// Largest index read, packed or unpacked (Keiyoushi's is under 1 MB):
  /// a hostile repo's gzip bomb stops here instead of filling memory.
  static const maxBytes = 64 << 20;

  static Uint8List _gunzip(List<int> data) {
    if (data.length > maxBytes) {
      throw const FormatException('Mihon repo index too large');
    }
    final bytes = Uint8List.fromList(data);
    if (bytes.length < 2 || bytes[0] != 0x1f || bytes[1] != 0x8b) return bytes;
    final out = _CappedSink();
    gzip.decoder.startChunkedConversion(out)
      ..add(bytes)
      ..close();
    return out.bytes.takeBytes();
  }

  static List<StoreExtension> _list(Uint8List data) {
    final out = <StoreExtension>[];
    final r = _Proto(data);
    while (r.next()) {
      if (r.field == 1 && r.wire == 2) {
        if (_extension(r.bytes()) case final e?) out.add(e);
      } else {
        r.skip();
      }
    }
    return out;
  }

  /// Null when the message is cut short: half an extension is no use.
  static StoreExtension? _extension(Uint8List data) {
    final e = StoreExtension();
    final r = _Proto(data);
    var bad = false;
    while (r.next()) {
      switch (r.field) {
        case 1:
          e.name = r.text();
        case 2:
          e.pkg = r.text();
        case 3:
          final res = _Proto(r.bytes());
          while (res.next()) {
            switch (res.field) {
              case 1:
                e.apkUrl = res.text();
              case 2:
                e.iconUrl = res.text();
              default:
                res.skip();
            }
          }
          bad |= res.bad;
        case 4:
          e.lib = r.text();
        case 5:
          e.versionCode = r.varint();
        case 6:
          e.versionName = r.text();
        case 7:
          e.contentWarning = r.varint();
        // Mihon's sources; Aniyomi's 8 is a bool and its sources are 9.
        case 8 when r.wire == 2:
          final source = _source(r.bytes());
          if (source == null) {
            bad = true;
          } else {
            e.sources.add(source);
          }
        default:
          r.skip();
      }
    }
    return r.bad || bad ? null : e;
  }

  static MihonSourceRef? _source(Uint8List data) {
    var id = '';
    var name = '';
    var lang = 'all';
    var home = '';
    final r = _Proto(data);
    while (r.next()) {
      switch (r.field) {
        case 1:
          id = '${r.varint()}';
        case 2:
          name = r.text();
        case 3:
          lang = r.text();
        case 4:
          home = r.text();
        default:
          r.skip();
      }
    }
    return r.bad
        ? null
        : MihonSourceRef(id: id, name: name, lang: lang, baseUrl: home);
  }
}

/// Collects unpacked bytes, failing once they pass [MihonStore.maxBytes].
class _CappedSink implements Sink<List<int>> {
  final bytes = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    bytes.add(chunk);
    if (bytes.length > MihonStore.maxBytes) {
      throw const FormatException('Mihon repo index too large');
    }
  }

  @override
  void close() {}
}

/// One extension of a [MihonStore].
class StoreExtension {
  String name = '';
  String pkg = '';
  String apkUrl = '';
  String iconUrl = '';
  String lib = '';
  int versionCode = 0;
  String versionName = '';
  int contentWarning = 0;
  final sources = <MihonSourceRef>[];

  bool get nsfw => contentWarning == 3;
}

/// A minimal protobuf reader: varints and length-delimited fields; other
/// wire types are skipped.
class _Proto {
  _Proto(this._b);

  final Uint8List _b;
  var _i = 0;
  var field = 0;
  var wire = 0;
  var bad = false;

  bool next() {
    if (bad || _i >= _b.length) return false;
    final key = _varint();
    if (bad) return false;
    field = key >> 3;
    wire = key & 7;
    return field > 0;
  }

  int varint() => _varint();

  Uint8List bytes() {
    final length = _varint();
    if (bad || length < 0 || length > _b.length - _i) {
      bad = true;
      return Uint8List(0);
    }
    final out = Uint8List.sublistView(_b, _i, _i + length);
    _i += length;
    return out;
  }

  String text() => utf8.decode(bytes(), allowMalformed: true);

  void skip() {
    switch (wire) {
      case 0:
        _varint();
      case 1:
        _i += 8;
      case 2:
        bytes();
      case 5:
        _i += 4;
      default:
        bad = true;
    }
    if (_i > _b.length) bad = true;
  }

  // Unsigned 64-bit: Mihon ids use all 63 bits, which Dart's int holds.
  int _varint() {
    var result = 0;
    var shift = 0;
    while (_i < _b.length) {
      final c = _b[_i++];
      result |= (c & 0x7f) << shift;
      if (c < 0x80) return result;
      shift += 7;
      if (shift > 63) break;
    }
    bad = true;
    return 0;
  }
}
