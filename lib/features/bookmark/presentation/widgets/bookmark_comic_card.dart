import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_progress.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Bookmark grid cell: cover with the source language and new-chapter count
/// badges, title, read meter and `read / total` chapters.
class BookmarkComicCard extends StatelessWidget {
  const BookmarkComicCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  /// Text under the cover: gap, two title lines, gap, meter, gap, numbers.
  static const textHeight =
      DotSpace.s2 + 22 * 2 + DotSpace.s2 + DotSize.dot + DotSpace.s2 + 18;

  final BookmarkProgress item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final details = item.bookmark.comicDetails;
    final lang = context.sourceOf(item.bookmark.slug)?.lang;

    return Semantics(
      selected: isSelected,
      child: Pressable(
        semanticLabel: details.title,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ComicCover(
              imageUrl: details.coverImg,
              overlay: Stack(
                fit: StackFit.expand,
                children: [
                  if (isSelected)
                    ColoredBox(color: c.bg.withValues(alpha: 0.55)),
                  if (lang != null && !isSelected)
                    Positioned(
                      top: DotSpace.s2,
                      left: DotSpace.s2,
                      child: LangBadge(lang: lang),
                    ),
                  if (item.hasUpdate)
                    Positioned(
                      top: DotSpace.s2,
                      right: DotSpace.s2,
                      child: UpdateBadge(count: item.newChapters),
                    ),
                  if (isSelected)
                    Positioned(
                      top: DotSpace.s2,
                      left: DotSpace.s2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.ink,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons300.check,
                          size: 16,
                          color: c.onInk,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DotSpace.s2),
            Text(
              details.title,
              style: DotlineText.body.copyWith(color: c.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DotSpace.s2),
            DotMeter(value: item.read, total: item.total, gap: 3),
            const SizedBox(height: DotSpace.s2),
            Text(
              '${item.read} / ${item.total}',
              style: DotlineText.data.copyWith(color: c.inkFaint),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
