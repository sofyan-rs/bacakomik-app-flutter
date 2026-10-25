import 'dart:typed_data';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';

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

/// [img] is a URL, or a file path for a downloaded page. A URL is taken
/// from [cache] when given (downloaded into it when missing).
Future saveImg({
  required BuildContext context,
  required String img,
  Map<String, String> headers = const {},
  BaseCacheManager? cache,
}) async {
  try {
    if (cache != null && img.startsWith('http')) {
      final file = await cache.getSingleFile(img, headers: headers);
      await Gal.putImage(file.path);
    } else if (img.startsWith('http')) {
      final response = await Dio().get(
        img,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );
      await Gal.putImageBytes(Uint8List.fromList(response.data));
    } else {
      await Gal.putImage(img);
    }

    if (!context.mounted) return;
    showSnackBar(context: context, message: AppText.successSaveImg);
  } catch (e) {
    if (!context.mounted) return;
    showSnackBar(context: context, message: AppText.failedSaveImg);
  }
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
