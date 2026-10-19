import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/bloc/bookmark_cubit/bookmark_cubit.dart';
import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/bookmark_model.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future backupData(
  BuildContext context,
) async {
  try {
    String? selectedDirectory = await FilePicker.getDirectoryPath();

    DateTime now = DateTime.now();
    String formattedDate =
        '${now.year}-${now.month}-${now.day}-${now.hour}${now.minute}${now.second}';
    String fileName = 'bacakomik-backup-$formattedDate.json';

    if (!context.mounted) return;
    final bookmarkData = context.read<BookmarkCubit>().state;
    final historyData = context.read<HistoryCubit>().state;

    if (selectedDirectory == null) {
      return;
    }

    if (bookmarkData.isNotEmpty || historyData.isNotEmpty) {
      String path = '$selectedDirectory/$fileName';
      File backupFile = File(path);

      final json = jsonEncode({
        'bookmarks': bookmarkData,
        'history': historyData,
      });

      await backupFile.writeAsString(json);

      if (!context.mounted) return;
      showSnackBar(
        context: context,
        message: AppText.successBackupData,
      );
    }
  } catch (e) {
    // print(e);
    if (!context.mounted) return;
    showSnackBar(
      context: context,
      message: AppText.failedBackupData,
    );
  }
}

Future restoreData(
  BuildContext context,
) async {
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isNotEmpty) {
      File file = File(files.single.path!);
      String data = await file.readAsString();

      final jsonData = jsonDecode(data);

      // Older backups store bookmarks under the 'favorites' key.
      final bookmarkData = List<BookmarkModel>.from(
        (jsonData['bookmarks'] ?? jsonData['favorites']).map(
          (x) => BookmarkModel.fromJson(x),
        ),
      );

      final historyData = List<HistoryModel>.from(
        jsonData['history'].map(
          (x) => HistoryModel.fromJson(x),
        ),
      );

      if (!context.mounted) return;
      if (bookmarkData.isNotEmpty) {
        context.read<BookmarkCubit>().setBookmark(bookmarkData);
      }

      if (historyData.isNotEmpty) {
        context.read<HistoryCubit>().setHistory(historyData);
      }

      showSnackBar(
        context: context,
        message: AppText.successRestoreData,
      );
    }
  } catch (e) {
    // print(e);
    if (!context.mounted) return;
    showSnackBar(
      context: context,
      message: AppText.failedRestoreData,
    );
  }
}
