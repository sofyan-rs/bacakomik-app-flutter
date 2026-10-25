import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';

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
              builder: (context, constraints) => CachedNetworkImage(
                cacheManager: comicImageCache,
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: _decodeWidth(context, constraints.maxWidth),
                fadeInDuration: DotMotion.press,
                placeholder: (_, _) => const DotGridPlaceholder(),
                errorWidget: (_, _, _) => const DotGridPlaceholder(),
              ),
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
