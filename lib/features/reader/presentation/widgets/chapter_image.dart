import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// One chapter page. Long press to save it to the gallery.
class ChapterImg extends StatelessWidget {
  const ChapterImg({
    super.key,
    required this.chapterImage,
    required this.page,
    this.fit = PageFit.width,
    this.fitHeight,
  });

  final String chapterImage;

  /// 1-based page number, shown while loading.
  final int page;
  final PageFit fit;

  /// Height used with [PageFit.height] in the vertical reader.
  final double? fitHeight;

  void _showSaveSheet(BuildContext context) {
    showDotSheet<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionSheetHeader(
            icon: LucideIcons300.image,
            title: AppText.saveImg,
            subtitle: '${AppText.pageShort} $page',
          ),
          const SizedBox(height: DotSpace.s5),
          DotButton(
            label: AppText.saveImg,
            leading: LucideIcons300.download,
            onTap: () {
              Navigator.of(sheetContext).pop();
              saveImg(context: context, img: chapterImage);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final placeholder = SizedBox(
      height: fitHeight ?? 480,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DotGridPlaceholder(),
          Center(
            child: Text(
              '${AppText.pageShort} $page'.toUpperCase(),
              style: DotlineText.data.copyWith(color: c.inkFaint),
            ),
          ),
        ],
      ),
    );

    final image = CachedNetworkImage(
      cacheKey: chapterImage,
      imageUrl: chapterImage,
      width: double.infinity,
      height: fitHeight,
      fit: fit == PageFit.height ? BoxFit.contain : BoxFit.fitWidth,
      fadeInDuration: DotMotion.press,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => SizedBox(
        height: fitHeight ?? 320,
        child: Center(
          child: Icon(LucideIcons300.image, color: c.inkFaint, size: 32),
        ),
      ),
    );

    return GestureDetector(
      onLongPress: () => _showSaveSheet(context),
      child: image,
    );
  }
}
