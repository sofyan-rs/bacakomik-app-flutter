import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Last item of the reader: "Chapter N finished", the next chapter card and
/// where to go next.
class ChapterEnd extends StatelessWidget {
  const ChapterEnd({
    super.key,
    required this.chapterNumber,
    required this.pageCount,
    required this.cover,
    required this.next,
    required this.onNext,
    required this.onChapterList,
    required this.onBackToSeries,
  });

  final String chapterNumber;
  final int pageCount;
  final String cover;

  /// Null when this is the latest chapter.
  final Chapter? next;
  final VoidCallback onNext;
  final VoidCallback onChapterList;
  final VoidCallback onBackToSeries;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final next = this.next;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DotSpace.s4,
        DotSpace.s6,
        DotSpace.s4,
        // Clears the floating chapter pill when the controls are shown.
        DotSize.navHeight +
            DotSize.navGap +
            DotSpace.s5 +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: DotMeter(
              value: pageCount,
              total: pageCount,
              dots: pageCount.clamp(1, 22),
            ),
          ),
          const SizedBox(height: DotSpace.s3),
          Text(
            '${AppText.finished} · $pageCount ${AppText.pages}'.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DotSpace.s2),
          Text(
            '${AppText.chapter} $chapterNumber ${AppText.finishedLower}',
            style: DotlineText.title.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DotSpace.s5),
          if (next != null) ...[
            Pressable(
              semanticLabel: AppText.chapterName(next.number, next.title),
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.all(DotSpace.s4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(DotRadius.tile),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: ComicCover(imageUrl: cover, radius: DotRadius.s),
                    ),
                    const SizedBox(width: DotSpace.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const NewBadge(label: AppText.nextChapter),
                          const SizedBox(height: DotSpace.s1),
                          Text(
                            AppText.chapterName(next.number, next.title),
                            style: DotlineText.headline.copyWith(color: c.ink),
                          ),
                          if (next.date != '-')
                            Text(
                              '${AppText.releasedOn} ${next.date}',
                              style: DotlineText.data.copyWith(
                                color: c.inkFaint,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons300.chevronRight,
                      size: DotSize.iconSmall,
                      color: c.inkFaint,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DotSpace.s4),
            DotButton(
              label: '${AppText.continueTo} ${next.number}',
              trailing: LucideIcons300.arrowRight,
              onTap: onNext,
            ),
          ] else
            Text(
              AppText.latestChapterReached,
              style: DotlineText.body.copyWith(color: c.inkMuted),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: DotSpace.s3),
          Row(
            children: [
              Expanded(
                child: DotButton.outline(
                  label: AppText.chapterList,
                  size: DotButtonSize.medium,
                  onTap: onChapterList,
                ),
              ),
              const SizedBox(width: DotSpace.s3),
              Expanded(
                child: DotButton.outline(
                  label: AppText.backToSeries,
                  size: DotButtonSize.medium,
                  onTap: onBackToSeries,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
