import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:flutter/material.dart';

/// Latest-chapter row inside a [ListGroup]. Shared by the home section and
/// the "see all" screen.
class LatestChapterCard extends StatelessWidget {
  const LatestChapterCard({
    super.key,
    required this.title,
    required this.cover,
    required this.chapter,
    required this.type,
    required this.slug,
    required this.isCompleted,
  });

  final String title;
  final String cover;
  final String chapter;
  final String type;
  final String slug;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      leading: SizedBox(
        width: 44,
        height: 60,
        child: ComicCover(
          imageUrl: cover,
          radius: DotRadius.s,
          aspectRatio: null,
        ),
      ),
      title: title,
      subtitle: '$type · ${isCompleted ? 'Completed' : 'Ongoing'}',
      value: chapter == '-' ? null : 'CH. $chapter',
      onTap: () => ComicDetailsScreen.open(
        context,
        slug: slug,
        title: title,
        cover: cover,
      ),
    );
  }
}
