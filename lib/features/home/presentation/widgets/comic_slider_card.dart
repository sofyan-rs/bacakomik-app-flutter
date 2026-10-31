import 'package:bacakomik_app/core/presentation/widgets/comic_card.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:flutter/material.dart';

/// New series card: cover with type label, title, latest chapter.
class ComicSliderCard extends StatelessWidget {
  const ComicSliderCard({
    super.key,
    required this.title,
    required this.cover,
    required this.chapter,
    required this.type,
    required this.slug,
    this.width = phoneWidth,
  });

  static const phoneWidth = 132.0;

  /// On wide screens, where [phoneWidth] covers look like thumbnails.
  static const wideWidth = 176.0;

  final String title;
  final String cover;
  final String chapter;
  final String type;
  final String slug;
  final double width;

  @override
  Widget build(BuildContext context) {
    final heroTag = CoverHeroTag(context, cover);
    final c = Dotline.of(context);
    return SizedBox(
      width: width,
      child: Pressable(
        semanticLabel: title,
        hoverScale: DotMotion.hoverScale,
        onTap: () => ComicDetailsScreen.open(
          context,
          slug: slug,
          title: title,
          cover: cover,
          heroTag: heroTag,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverHero(
              tag: heroTag,
              child: ComicCover(
                imageUrl: cover,
                radius: DotRadius.m,
                typeLabel: type,
              ),
            ),
            const SizedBox(height: DotSpace.s3),
            Text(
              title,
              style: DotlineText.body.copyWith(color: c.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // No line at all (not "CH. -") when the source does not say.
            if (ComicCard.hasChapter(chapter)) ...[
              const SizedBox(height: DotSpace.s1),
              Text(
                'CH. $chapter',
                style: DotlineText.data.copyWith(color: c.inkFaint),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
