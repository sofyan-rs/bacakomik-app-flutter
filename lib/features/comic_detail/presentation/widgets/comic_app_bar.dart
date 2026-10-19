import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Detail bottom bar: bookmark toggle + continue/start reading. While
/// chapters are selected it switches to mark read / unread / all / cancel.
class ComicAppBar extends StatelessWidget {
  const ComicAppBar({
    super.key,
    required this.comicSlug,
    required this.comicDetails,
    required this.selectedChapters,
    required this.selectAllChapter,
    required this.unselectAllChapter,
    required this.onRead,
  });

  final String comicSlug;
  final ComicDetails comicDetails;
  final List<SelectedChapter> selectedChapters;
  final void Function(List<SelectedChapter>) selectAllChapter;
  final VoidCallback unselectAllChapter;

  /// Opens a chapter by slug.
  final void Function(String slug) onRead;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DotSpace.s4,
            DotSpace.s3,
            DotSpace.s4,
            DotSpace.s3,
          ),
          child: selectedChapters.isEmpty
              ? _readBar(context)
              : _selectionBar(context),
        ),
      ),
    );
  }

  Widget _readBar(BuildContext context) {
    final c = Dotline.of(context);
    final bookmarked = context.watch<BookmarkCubit>().isBookmark(comicSlug);
    final latest = context.watch<HistoryCubit>().getLatestHistoryBySlug(
      comicSlug,
    );
    final chapters = comicDetails.chapters;

    // API order is newest first, so the first chapter is the last one.
    final first = chapters.isEmpty ? null : chapters.last;
    final label = latest != null
        ? '${AppText.continueReading} · Ch. ${latest.chapterNumber}'
        : first != null
        ? '${AppText.startReading} · Ch. ${first.number}'
        : AppText.startReading;

    return Row(
      children: [
        Pressable(
          semanticLabel: bookmarked
              ? AppText.removeBookmark
              : AppText.addBookmark,
          onTap: () => _toggleBookmark(context, bookmarked),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.lineStrong, width: DotSize.stroke),
            ),
            child: Center(
              child: bookmarked
                  ? CustomPaint(
                      size: const Size.square(DotSize.icon),
                      painter: _FilledBookmarkPainter(c.ink),
                    )
                  : Icon(LucideIcons300.bookmark, color: c.ink),
            ),
          ),
        ),
        const SizedBox(width: DotSpace.s3),
        Expanded(
          child: DotButton(
            label: label,
            leading: LucideIcons300.bookOpen,
            onTap: latest != null
                ? () => onRead(latest.slug)
                : first != null
                ? () => onRead(first.slug)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _selectionBar(BuildContext context) {
    final c = Dotline.of(context);
    return Row(
      children: [
        RoundIconButton(
          icon: LucideIcons300.x,
          semanticLabel: AppText.cancel,
          onTap: unselectAllChapter,
        ),
        const SizedBox(width: DotSpace.s3),
        Expanded(
          child: Text(
            '${selectedChapters.length} ${AppText.selected}'.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.ink),
          ),
        ),
        RoundIconButton(
          icon: LucideIcons300.list,
          semanticLabel: AppText.selectAll,
          onTap: () => selectAllChapter([
            for (final chapter in comicDetails.chapters.reversed)
              SelectedChapter(
                slug: chapter.slug,
                chapterNumber: chapter.number,
              ),
          ]),
        ),
        const SizedBox(width: DotSpace.s2),
        RoundIconButton(
          icon: LucideIcons300.rotateCcw,
          semanticLabel: AppText.markUnread,
          onTap: () {
            context.read<HistoryCubit>().removeHistoryList([
              for (final chapter in selectedChapters) chapter.slug,
            ]);
            unselectAllChapter();
          },
        ),
        const SizedBox(width: DotSpace.s2),
        RoundIconButton(
          icon: LucideIcons300.check,
          semanticLabel: AppText.markRead,
          background: c.ink,
          foreground: c.onInk,
          onTap: () {
            final now = DateTime.now();
            context.read<HistoryCubit>().addHistoryList([
              for (final chapter in selectedChapters)
                ReadHistory(
                  comicSlug: comicSlug,
                  chapterNumber: chapter.chapterNumber,
                  comicDetails: comicDetails,
                  readDate: now,
                  slug: chapter.slug,
                ),
            ]);
            unselectAllChapter();
          },
        ),
      ],
    );
  }

  void _toggleBookmark(BuildContext context, bool bookmarked) {
    final cubit = context.read<BookmarkCubit>();
    if (bookmarked) {
      cubit.removeBookmark(comicSlug);
      showSnackBar(context: context, message: AppText.removedFromBookmark);
    } else {
      cubit.addBookmark(comicDetails, comicSlug);
      showSnackBar(context: context, message: AppText.addedToBookmark);
    }
  }
}

/// Lucide `bookmark` shape, filled. The icon font has no filled variant.
class _FilledBookmarkPainter extends CustomPainter {
  const _FilledBookmarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    // m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z
    final path = Path()
      ..moveTo(19 * s, 21 * s)
      ..lineTo(12 * s, 17 * s)
      ..lineTo(5 * s, 21 * s)
      ..lineTo(5 * s, 5 * s)
      ..arcToPoint(Offset(7 * s, 3 * s), radius: Radius.circular(2 * s))
      ..lineTo(17 * s, 3 * s)
      ..arcToPoint(Offset(19 * s, 5 * s), radius: Radius.circular(2 * s))
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = DotSize.stroke * s
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_FilledBookmarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
