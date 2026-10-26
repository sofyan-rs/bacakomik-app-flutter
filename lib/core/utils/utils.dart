import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

void showSnackBar({
  required BuildContext context,
  required String message,
  Icon? icon,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          icon ?? const SizedBox(),
          icon != null ? const SizedBox(width: 8) : const SizedBox(),
          Text(message),
        ],
      ),
      duration: const Duration(seconds: 1),
    ),
  );
}

/// Saves a page or cover to the gallery. [img] is a URL (`mihon://` too),
/// or a file path for a downloaded page. A URL is read from [cache] (the reader's cache when
/// not given), which already holds what is on screen and downloads with the
/// app's User-Agent, cookies and [headers] when it does not.
Future saveImg({
  required BuildContext context,
  required String img,
  Map<String, String> headers = const {},
  BaseCacheManager? cache,
}) async {
  File? temp;
  try {
    final Uint8List bytes;
    if (img.startsWith('http') || isMihonImage(img)) {
      final file = await (cache ?? comicImageCache).getSingleFile(
        img,
        headers: headers,
      );
      bytes = await file.readAsBytes();
    } else {
      bytes = await File(img).readAsBytes();
    }
    // The gallery names the file by its extension, and cached files have
    // none it can use.
    final (data, extension) = await galleryImage(bytes);
    final dir = await getTemporaryDirectory();
    temp = File(
      '${dir.path}/bacakomik_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await temp.writeAsBytes(data, flush: true);
    if (!await Gal.hasAccess()) await Gal.requestAccess();
    await Gal.putImage(temp.path);

    if (!context.mounted) return;
    showSnackBar(context: context, message: AppText.successSaveImg);
  } catch (e) {
    debugPrint('saveImg($img): $e');
    if (!context.mounted) return;
    showSnackBar(context: context, message: AppText.failedSaveImg);
  } finally {
    try {
      await temp?.delete();
    } catch (_) {}
  }
}

/// [bytes] as the gallery takes them, with their file extension. JPEG, PNG,
/// GIF and WebP are kept; anything else (AVIF, BMP, ...) is decoded and
/// saved as PNG.
Future<(Uint8List, String)> galleryImage(Uint8List bytes) async {
  if (imageExtension(bytes) case final extension?) return (bytes, extension);
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    if (png == null) throw const FormatException('Image could not be encoded');
    return (png.buffer.asUint8List(), '.png');
  } finally {
    codec.dispose();
  }
}

/// `.jpg`, `.png`, `.gif` or `.webp` from the first bytes of an image; null
/// for any other format.
String? imageExtension(Uint8List b) {
  bool at(int offset, List<int> sig) =>
      b.length >= offset + sig.length &&
      [for (var i = 0; i < sig.length; i++) b[offset + i]].join(',') ==
          sig.join(',');
  if (at(0, [0xFF, 0xD8, 0xFF])) return '.jpg';
  if (at(0, [0x89, 0x50, 0x4E, 0x47])) return '.png';
  if (at(0, [0x47, 0x49, 0x46, 0x38])) return '.gif';
  if (at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50])) {
    return '.webp';
  }
  return null;
}

/// `1.4 MB`, `820 KB`.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit >= 2 && value < 10 ? 1 : 0;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
