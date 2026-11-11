import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Whether this device can show AVIF images. Flutter has no AVIF decoder of
/// its own: on Android it uses the system's, which has one from Android 12;
/// older Android and the desktops have none. Found once, by decoding a 1x1
/// AVIF; later calls share the answer.
Future<bool> avifSupported() => _avif ??= _decodes(base64Decode(_tinyAvif));

Future<bool>? _avif;

/// The answer of [avifSupported] once it is known; null before.
bool? get avifSupportedNow => _avifNow;
bool? _avifNow;

Future<bool> _decodes(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
    return _avifNow = true;
  } catch (_) {
    return _avifNow = false;
  }
}

/// A white 1x1 AVIF, 307 bytes.
const _tinyAvif =
    'AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADrbWV0YQAAAAAAAAAhaGRscgAA'
    'AAAAAAAAcGljdAAAAAAAAAAAAAAAAAAAAAAOcGl0bQAAAAAAAQAAAB5pbG9jAAAAAEQAAAEA'
    'AQAAAAEAAAETAAAAIAAAAChpaW5mAAAAAAABAAAAGmluZmUCAAAAAAEAAGF2MDFDb2xvcgAA'
    'AABqaXBycAAAAEtpcGNvAAAAFGlzcGUAAAAAAAAAAQAAAAEAAAAQcGl4aQAAAAADCAgIAAAA'
    'DGF2MUOBAAwAAAAAE2NvbHJuY2x4AAEADQAGgAAAABdpcG1hAAAAAAAAAAEAAQQBAoMEAAAA'
    'KG1kYXQSAAoIGAAGiAhoNCAyEh7Hh4VZ3///4sAAAJA1jjx9Nw==';

/// Whether [head], the first bytes of a file, is an AVIF image or image
/// sequence (`ftyp` box with brand `avif` or `avis`).
bool isAvif(Uint8List head) {
  if (head.length < 12) return false;
  final box = String.fromCharCodes(head.sublist(4, 8));
  final brand = String.fromCharCodes(head.sublist(8, 12));
  return box == 'ftyp' && (brand == 'avif' || brand == 'avis');
}
