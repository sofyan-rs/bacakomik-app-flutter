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
  });

  static const width = 132.0;

  final String title;
  final String cover;
  final String chapter;
  final String type;
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
              'CH. $chapter',
              style: DotlineText.data.copyWith(color: c.inkFaint),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
