import 'dart:typed_data';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

showSnackBar({
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

Future saveImg({
  required BuildContext context,
  required String img,
}) async {
  final dio = Dio();
  dio.options.headers['Referer'] = AppVariables.referer;
  try {
    final response = await dio.get(
      img,
      options: Options(responseType: ResponseType.bytes),
    );
    await ImageGallerySaver.saveImage(Uint8List.fromList(response.data));

    if (!context.mounted) return;
    showSnackBar(
      context: context,
      message: AppText.successSaveImg,
    );
  } catch (e) {
    if (!context.mounted) return;
    showSnackBar(
      context: context,
      message: AppText.failedSaveImg,
      icon: const Icon(Icons.error),
    );
  }
}
