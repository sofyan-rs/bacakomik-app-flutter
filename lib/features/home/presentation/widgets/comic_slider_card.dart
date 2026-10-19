import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:flutter/material.dart';

/// Hot comic card: cover with type label and rank number, title, chapter and
/// rating.
class ComicSliderCard extends StatelessWidget {
  const ComicSliderCard({
    super.key,
    required this.rank,
    required this.title,
    required this.cover,
    required this.chapter,
    required this.type,
    required this.rating,
    required this.slug,
  });

  static const width = 132.0;

  final int rank;
  final String title;
  final String cover;
  final String chapter;
  final String type;
  final String rating;
  final String slug;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return SizedBox(
      width: width,
      child: Pressable(
        semanticLabel: title,
        onTap: () => ComicDetailsScreen.open(
          context,
          slug: slug,
          title: title,
          cover: cover,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ComicCover(
              imageUrl: cover,
              radius: DotRadius.m,
              typeLabel: type,
              overlay: Positioned(
                left: DotSpace.s3,
                bottom: DotSpace.s1,
                child: Text(
                  rank.toString().padLeft(2, '0'),
                  style: DotlineText.stat.copyWith(
                    fontSize: 40,
                    height: 1.1,
                    color: const Color(0xFFFFFFFF),
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: DotSpace.s3),
            Text(
              title,
              style: DotlineText.body.copyWith(color: c.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DotSpace.s1),
            Text(
              'CH. $chapter · $rating',
              style: DotlineText.data.copyWith(color: c.inkFaint),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
