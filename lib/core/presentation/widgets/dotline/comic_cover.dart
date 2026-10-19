import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DotGridPlaceholder(),
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              fadeInDuration: DotMotion.press,
              placeholder: (_, _) => const SizedBox.shrink(),
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          if (typeLabel != null)
            Positioned(
              top: DotSpace.s2,
              left: DotSpace.s2,
              child: TypeLabel(typeLabel!),
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
    return ColoredBox(
      color: c.surfaceRaised,
      child: CustomPaint(
        painter: DotGridPainter(color: c.ink.withValues(alpha: 0.16)),
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  const DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const pitch = DotSize.dotPitch;
    for (var y = pitch / 2; y < size.height; y += pitch) {
      for (var x = pitch / 2; x < size.width; x += pitch) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) => oldDelegate.color != color;
}
