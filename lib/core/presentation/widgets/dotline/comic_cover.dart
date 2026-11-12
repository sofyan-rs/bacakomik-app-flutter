import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yoru/core/network/image_cache.dart';

/// Failures per cover URL this session; see [coverKey].
final _coverFailures = <String, int>{};

/// Key for a cover's image widget. It changes after the cover fails, so the
/// next rebuild (a refresh) makes a new image that asks again, instead of
/// keeping the one that failed.
Key coverKey(String url) => ValueKey((url, _coverFailures[url] ?? 0));

/// Forgets a cover that failed to load, so its next showing (a refresh,
/// scrolling back, opening the screen again) downloads it again.
///
/// Flutter's memory cache keeps a failed image under its key for as long as
/// the app runs: without this, a cover that failed while offline stays a
/// placeholder until the app restarts. [decodeWidth] must match the
/// `memCacheWidth` it was shown at, which is part of the key.
void forgetFailedCover(String url, int? decodeWidth) {
  _coverFailures[url] = (_coverFailures[url] ?? 0) + 1;
  ResizeImage.resizeIfNeeded(
    decodeWidth,
    null,
    CachedNetworkImageProvider(url, cacheManager: coverImageCache),
  ).evict().ignore();
  // A file that is not an image (e.g. a bot check page cached in its
  // place) goes too.
  coverImageCache.removeFile(url).ignore();
}

/// 2:3 cover with a faint dot grid while loading (no shimmer). Optional
/// type label pinned top-left and an [overlay] (badge, rank number).
class ComicCover extends StatelessWidget {
  const ComicCover({
    super.key,
    required this.imageUrl,
    this.radius = DotRadius.cover,
    this.typeLabel,
    this.overlay,
    this.aspectRatio = 2 / 3,
  });

  final String imageUrl;
  final double radius;
  final String? typeLabel;
  final Widget? overlay;

  /// Width / height. Pass null to fill the parent instead.
  final double? aspectRatio;

  static int? _decodeWidth(BuildContext context, double width) {
    if (!width.isFinite) return null;
    return (width * MediaQuery.devicePixelRatioOf(context)).round();
  }

  @override
  Widget build(BuildContext context) {
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isEmpty)
            const DotGridPlaceholder()
          else
            LayoutBuilder(
              // Decode at the size shown, not the source size: list
              // thumbnails are 44 wide while covers are often 600+.
              builder: (context, constraints) {
                final width = _decodeWidth(context, constraints.maxWidth);
                return _CoverImage(url: imageUrl, decodeWidth: width);
              },
            ),
          // "-" is what a source without a format maps to.
          if (typeLabel case final label? when label != '-' && label.isNotEmpty)
            Positioned(
              top: DotSpace.s2,
              left: DotSpace.s2,
              child: TypeLabel(label),
            ),
          ?overlay,
        ],
      ),
    );
    final ratio = aspectRatio;
    return ratio == null
        ? cover
        : AspectRatio(aspectRatio: ratio, child: cover);
  }
}

/// A cover image that asks again, a few times, after it fails.
///
/// A failed cover is forgotten ([forgetFailedCover]), but nothing rebuilds
/// it: a library that arrives all at once (the first sync on an empty
/// device) starts hundreds of downloads, some fail (timeouts, a Cloudflare
/// block before the WebView has the host's cookies), and they stayed
/// placeholders until the app restarted.
class _CoverImage extends StatefulWidget {
  const _CoverImage({required this.url, required this.decodeWidth});

  final String url;
  final int? decodeWidth;

  /// Wait before each retry; no more retries after the last.
  static const retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 8),
    Duration(seconds: 30),
  ];

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  int _retries = 0;
  Timer? _retry;

  @override
  void didUpdateWidget(_CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retry?.cancel();
      _retry = null;
      _retries = 0;
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  /// Called from the error builder, which can run more than once for one
  /// failure: schedules one retry at a time.
  void _scheduleRetry() {
    if (_retry != null || _retries >= _CoverImage.retryDelays.length) return;
    _retry = Timer(_CoverImage.retryDelays[_retries], () {
      if (!mounted) return;
      // [coverKey] changed when the cover was forgotten: the rebuild makes
      // a new image that downloads it again.
      setState(() {
        _retries++;
        _retry = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: coverKey(widget.url),
      cacheManager: coverImageCache,
      imageUrl: widget.url,
      fit: BoxFit.cover,
      memCacheWidth: widget.decodeWidth,
      fadeInDuration: DotMotion.press,
      placeholder: (_, _) => const DotGridPlaceholder(),
      errorWidget: (_, url, _) {
        // Once per failure: the builder runs again on rebuilds.
        if (_retry == null) forgetFailedCover(url, widget.decodeWidth);
        _scheduleRetry();
        return const DotGridPlaceholder();
      },
    );
  }
}

/// Black pill with a 10px uppercase mono label: `MANGA`, `MANHWA`.
class TypeLabel extends StatelessWidget {
  const TypeLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DotSpace.s2, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
      child: Text(
        text.toUpperCase(),
        style: DotlineText.label.copyWith(
          fontSize: 10,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

/// `surfaceRaised` fill with r=1 dots every 8px. Image placeholder.
class DotGridPlaceholder extends StatelessWidget {
  const DotGridPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    // Own layer: the image fading in above does not repaint the grid.
    return RepaintBoundary(
      child: ColoredBox(
        color: c.surfaceRaised,
        child: CustomPaint(
          painter: DotGridPainter(color: c.ink.withValues(alpha: 0.16)),
        ),
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  const DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // One draw call for the whole grid; a reader page placeholder has a few
    // thousand dots.
    const pitch = DotSize.dotPitch;
    final columns = (size.width / pitch).ceil();
    final rows = (size.height / pitch).ceil();
    final points = Float32List(columns * rows * 2);
    var i = 0;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        points[i++] = pitch / 2 + column * pitch;
        points[i++] = pitch / 2 + row * pitch;
      }
    }
    canvas.drawRawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) => oldDelegate.color != color;
}
