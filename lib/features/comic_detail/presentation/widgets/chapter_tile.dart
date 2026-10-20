import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_date.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// One chapter row. Rows are laid out one by one in a sliver, so each row
/// draws its own part of the rounded list group ([isFirst] / [isLast]).
/// A finished chapter shows a check, an unfinished one its page (`5 / 24`).
class ChapterTile extends StatelessWidget {
  const ChapterTile({
    super.key,
    required this.chapter,
    required this.history,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
  });

  final Chapter chapter;

  /// Null when the chapter was never opened.
  final ReadHistory? history;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    const radius = Radius.circular(DotRadius.m);
    final isNew = history == null && ChapterDate.isNew(chapter.date);

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: DotMotion.press,
          decoration: BoxDecoration(
            color: isSelected ? c.surfaceRaised : c.surface,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? radius : Radius.zero,
              bottom: isLast ? radius : Radius.zero,
            ),
          ),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(
                  minHeight: DotSize.rowMin + 8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: DotSpace.s5),
                child: _row(c, isNew),
              ),
              if (!isLast) const Divider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(DotlineColors c, bool isNew) {
    final history = this.history;
    final isRead = history?.isFinished ?? false;
    return Row(
      children: [
        if (isSelected) ...[
          Icon(LucideIcons300.check, size: DotSize.iconSmall, color: c.ink),
          const SizedBox(width: DotSpace.s3),
        ],
        Expanded(
          child: Text(
            '${AppText.chapter} ${chapter.number}',
            style: DotlineText.headline.copyWith(
              color: isRead ? c.inkFaint : c.ink,
            ),
          ),
        ),
        if (isNew) ...[
          const NewBadge(label: AppText.newLabel),
          const SizedBox(width: DotSpace.s3),
        ] else if (isRead) ...[
          Icon(LucideIcons300.check, size: 18, color: c.inkFaint),
          const SizedBox(width: DotSpace.s3),
        ] else if (history?.page case final page?) ...[
          Text(
            '${page + 1} / ${history?.pageCount}',
            style: DotlineText.data.copyWith(color: c.ink),
          ),
          const SizedBox(width: DotSpace.s3),
        ],
        Text(
          ChapterDate.short(chapter.date),
          style: DotlineText.data.copyWith(color: c.inkFaint),
        ),
      ],
    );
  }
}
