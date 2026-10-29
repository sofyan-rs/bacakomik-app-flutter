import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';

import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';

/// One chapter page. Long press (or right click) to save it.
///
/// The reader loads pages in batches; until [load] is true only the dotted
/// placeholder with the page number shows. A page from the network that
/// fails shows a retry in its place; tapping it loads that page again.
class ChapterImg extends StatefulWidget {
  const ChapterImg({
    super.key,
    required this.chapterImage,
    this.isFile = false,
    required this.page,
    this.load = true,
    this.fit = PageFit.width,
    this.fitHeight,
    this.headers = const {},
    @visibleForTesting this.cacheManager,
  });

  /// Defaults to [comicImageCache].
  final BaseCacheManager? cacheManager;

  /// Sent with the image request, from [ChapterContent.imageHeaders].
  final Map<String, String> headers;

  /// URL, or a file path when [isFile].
  final String chapterImage;

  /// A page of a downloaded chapter.
  final bool isFile;

  /// 1-based page number, shown while loading.
  final int page;

  /// False keeps the placeholder until the reader reaches this page's batch.
  final bool load;
  final PageFit fit;

  /// Height used with [PageFit.height] in the vertical reader.
  final double? fitHeight;

  @override
  State<ChapterImg> createState() => _ChapterImgState();
}

class _ChapterImgState extends State<ChapterImg> {
  /// Bumped by [_retry]: a new key makes the image resolve again.
  int _attempt = 0;

  BaseCacheManager get _cache => widget.cacheManager ?? comicImageCache;

  /// Drops the failed page from the memory cache (which keeps the failed
  /// stream under the same key, resized as in [build]) and from the disk
  /// cache, then rebuilds the image so it is requested again.
  Future<void> _retry(int? cacheWidth, int? cacheHeight) async {
    final url = widget.chapterImage;
    await ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      CachedNetworkImageProvider(url, cacheKey: url, cacheManager: _cache),
    ).evict();
    try {
      await _cache.removeFile(url);
    } catch (_) {
      // Nothing stored for it.
    }
    if (mounted) setState(() => _attempt++);
  }

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
            subtitle: '${AppText.pageShort} ${widget.page}',
          ),
          const SizedBox(height: DotSpace.s5),
          DotButton(
            label: AppText.saveImg,
            leading: LucideIcons300.download,
            onTap: () {
              Navigator.of(sheetContext).pop();
              saveImg(
                context: context,
                img: widget.chapterImage,
                headers: widget.headers,
                cache: _cache,
              );
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
      '${AppText.pageShort} ${widget.page}'.toUpperCase(),
      style: DotlineText.data.copyWith(color: c.inkFaint),
    );

    // [progress] is null while queued, then 0..1 once downloading (or -1 when
    // the server sends no content length).
    Widget placeholder({double? progress}) => SizedBox(
      height: widget.fitHeight ?? 480,
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

    if (!widget.load) return placeholder();

    // Decode at screen size instead of the source size; webtoon pages can be
    // thousands of pixels tall and take tens of MB each at full resolution.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final pageWidth = min(
      MediaQuery.sizeOf(context).width,
      DotSize.readerMaxWidth,
    );
    final cacheWidth = widget.fit == PageFit.width
        ? (pageWidth * dpr).round()
        : null;
    final cacheHeight = widget.fit == PageFit.height && widget.fitHeight != null
        ? (widget.fitHeight! * dpr).round()
        : null;
    final boxFit = widget.fit == PageFit.height
        ? BoxFit.contain
        : BoxFit.fitWidth;
    // Same height as [placeholder], so the list does not jump when a page
    // fails or is retried.
    Widget error() => SizedBox(
      height: widget.fitHeight ?? 480,
      child: Center(
        child: Icon(LucideIcons300.image, color: c.inkFaint, size: 32),
      ),
    );

    // A failed network page: tap anywhere on it (or the button) to retry.
    Widget retry() => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _retry(cacheWidth, cacheHeight),
      child: SizedBox(
        height: widget.fitHeight ?? 480,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DotGridPlaceholder(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  label,
                  const SizedBox(height: DotSpace.s3),
                  Icon(LucideIcons300.imageOff, color: c.inkFaint, size: 32),
                  const SizedBox(height: DotSpace.s2),
                  Text(
                    AppText.pageNotLoaded,
                    style: DotlineText.data.copyWith(color: c.inkFaint),
                  ),
                  const SizedBox(height: DotSpace.s4),
                  DotButton.outline(
                    label: AppText.retry,
                    leading: LucideIcons300.rotateCw,
                    size: DotButtonSize.medium,
                    expand: false,
                    onTap: () => _retry(cacheWidth, cacheHeight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final Widget image = widget.isFile
        ? Image.file(
            File(widget.chapterImage),
            width: double.infinity,
            height: widget.fitHeight,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            fit: boxFit,
            frameBuilder: (_, child, frame, sync) =>
                frame == null && !sync ? placeholder() : child,
            errorBuilder: (_, _, _) => error(),
          )
        : CachedNetworkImage(
            key: ValueKey(_attempt),
            cacheManager: _cache,
            cacheKey: widget.chapterImage,
            imageUrl: widget.chapterImage,
            httpHeaders: widget.headers,
            width: double.infinity,
            height: widget.fitHeight,
            memCacheWidth: cacheWidth,
            memCacheHeight: cacheHeight,
            fit: boxFit,
            fadeInDuration: DotMotion.press,
            progressIndicatorBuilder: (_, _, p) =>
                placeholder(progress: p.progress ?? -1),
            errorWidget: (_, _, _) => retry(),
          );

    return GestureDetector(
      onLongPress: () => _showSaveSheet(context),
      onSecondaryTap: () => _showSaveSheet(context),
      child: image,
    );
  }
}
