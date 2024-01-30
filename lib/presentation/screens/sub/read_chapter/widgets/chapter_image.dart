import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';

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

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
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
    );
  }
}
