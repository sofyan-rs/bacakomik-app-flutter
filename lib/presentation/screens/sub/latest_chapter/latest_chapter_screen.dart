import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/screens/sub/latest_chapter/widgets/latest_chapter_more.dart';
import 'package:solar_icons/solar_icons.dart';

class LatestChapterScreen extends StatelessWidget {
  const LatestChapterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppText.latest),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            SolarIconsOutline.arrowLeft,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
      body: const LatestChapterMore(),
    );
  }
}
