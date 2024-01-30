import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/screens/sub/latest_chapter/widgets/latest_chapter_more.dart';

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
          icon: Assets.icons.outline.arrowLeftOutline.svg(
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      body: const LatestChapterMore(),
    );
  }
}
