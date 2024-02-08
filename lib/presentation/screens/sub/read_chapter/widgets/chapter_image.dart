import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:solar_icons/solar_icons.dart';

class ChapterImg extends StatefulWidget {
  const ChapterImg({
    Key? key,
    required this.chapterImage,
  }) : super(key: key);

  final String chapterImage;

  @override
  State<ChapterImg> createState() => _ChapterImgState();
}

class _ChapterImgState extends State<ChapterImg> {
  @override
  void initState() {
    super.initState();
    _sendHttpRequest(widget.chapterImage);
  }

  Future _sendHttpRequest(String imgUrl) async {
    final dio = Dio();
    dio.options.headers['Referer'] = AppVariables.referer;
    final response = await dio.get(imgUrl);
    return response;
  }

  void showModalDownloadImg(imgUrl) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(0),
        ),
      ),
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Row(
                children: [
                  Icon(
                    SolarIconsOutline.galleryDownload,
                    color: Theme.of(context).colorScheme.onBackground,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(AppText.saveImg),
                ],
              ),
              onTap: () async {
                await saveImg(
                  context: context,
                  img: imgUrl,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalDownloadImg(widget.chapterImage);
      },
      child: CachedNetworkImage(
        cacheKey: widget.chapterImage,
        imageUrl: widget.chapterImage,
        progressIndicatorBuilder: (context, url, downloadProgress) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 50,
                horizontal: 20,
              ),
              child: CircularProgressIndicator(
                value: downloadProgress.progress,
              ),
            ),
          );
        },
        errorWidget: (context, url, error) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    AppText.error,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        httpHeaders: const {
          'Referer': AppVariables.referer,
        },
      ),
    );
  }
}
