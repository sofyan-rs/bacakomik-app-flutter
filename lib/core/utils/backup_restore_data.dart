import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/bloc/favorite_cubit/favorite_cubit.dart';
import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/favorite_model.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future backupData(
  BuildContext context,
) async {
  try {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    DateTime now = DateTime.now();
    String formattedDate =
        '${now.year}-${now.month}-${now.day}-${now.hour}${now.minute}${now.second}';
    String fileName = 'bacakomik-backup-$formattedDate.json';

    if (!context.mounted) return;
    final favoriteData = context.read<FavoriteCubit>().state;
    final historyData = context.read<HistoryCubit>().state;

    if (selectedDirectory == null) {
      return;
    }

    if (favoriteData.isNotEmpty || historyData.isNotEmpty) {
      String path = '$selectedDirectory/$fileName';
      File backupFile = File(path);

      final json = jsonEncode({
        'favorites': favoriteData,
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String data = await file.readAsString();

      final jsonData = jsonDecode(data);

      final favoriteData = List<FavoriteModel>.from(
        jsonData['favorites'].map(
          (x) => FavoriteModel.fromJson(x),
        ),
      );

      final historyData = List<HistoryModel>.from(
        jsonData['history'].map(
          (x) => HistoryModel.fromJson(x),
        ),
      );

      if (!context.mounted) return;
      if (favoriteData.isNotEmpty) {
        context.read<FavoriteCubit>().setFavorite(favoriteData);
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
