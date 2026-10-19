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
///
/// The reader loads pages in batches; until [load] is true only the dotted
/// placeholder with the page number shows.
class ChapterImg extends StatelessWidget {
  const ChapterImg({
    super.key,
    required this.chapterImage,
    required this.page,
    this.load = true,
    this.fit = PageFit.width,
    this.fitHeight,
  });

  final String chapterImage;

  /// 1-based page number, shown while loading.
  final int page;

  /// False keeps the placeholder until the reader reaches this page's batch.
  final bool load;
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
    final label = Text(
      '${AppText.pageShort} $page'.toUpperCase(),
      style: DotlineText.data.copyWith(color: c.inkFaint),
    );

    // [progress] is null while queued, then 0..1 once downloading (or -1 when
    // the server sends no content length).
    Widget placeholder({double? progress}) => SizedBox(
      height: fitHeight ?? 480,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DotGridPlaceholder(),
          Center(
            child: progress == null
                ? label
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      label,
                      const SizedBox(height: DotSpace.s3),
                      const DotLoader(),
                      if (progress >= 0) ...[
                        const SizedBox(height: DotSpace.s2),
                        Text(
                          '${(progress * 100).round()}%',
                          style: DotlineText.data.copyWith(color: c.inkFaint),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );

    if (!load) return placeholder();

    // Decode at screen size instead of the source size; webtoon pages can be
    // thousands of pixels tall and take tens of MB each at full resolution.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final image = CachedNetworkImage(
      cacheKey: chapterImage,
      imageUrl: chapterImage,
      width: double.infinity,
      height: fitHeight,
      memCacheWidth: fit == PageFit.width
          ? (screenWidth * dpr).round()
          : null,
      memCacheHeight: fit == PageFit.height && fitHeight != null
          ? (fitHeight! * dpr).round()
          : null,
      fit: fit == PageFit.height ? BoxFit.contain : BoxFit.fitWidth,
      fadeInDuration: DotMotion.press,
      progressIndicatorBuilder: (_, _, p) =>
          placeholder(progress: p.progress ?? -1),
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
