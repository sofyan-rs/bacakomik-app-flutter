import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:flutter/material.dart';

/// Grid cell for Explore and search: 2:3 cover with type label, two-line
/// title, latest chapter.
class ComicCard extends StatelessWidget {
  const ComicCard({
    super.key,
    required this.title,
    required this.cover,
    required this.chapter,
    required this.type,
    required this.slug,
  });

  /// Height of everything under the cover; the grid adds it to the cover
  /// height to size each cell.
  static const textHeight =
      DotSpace.s2 + 22 * 2 + DotSpace.s1 + 18 + DotSpace.s1;

  /// [textHeight] for a grid where no comic has a latest chapter (many
  /// Mihon sources list none).
  static const textHeightWithoutChapter = DotSpace.s2 + 22 * 2 + DotSpace.s1;

  /// Whether [chapter] is a latest chapter to show; sources without one
  /// send `-`.
  static bool hasChapter(String chapter) =>
      chapter.isNotEmpty && chapter != '-';

  final String title;
  final String cover;
  final String chapter;
  final String type;
  final String slug;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Pressable(
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
          ComicCover(imageUrl: cover, typeLabel: type),
          const SizedBox(height: DotSpace.s2),
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
    );
  }
}
