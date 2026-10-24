import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_progress.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/widgets/history_groups.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// History row for one comic: thumbnail, title, last chapter with a read
/// meter, time. Swipe left for HAPUS.
class HistoryComicCard extends StatelessWidget {
  const HistoryComicCard({super.key, required this.item});

  final ComicLatestHistory item;

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<HistoryCubit>();
    final choice = await showDotSheet<_DeleteChoice>(
      context: context,
      builder: (_) => _DeleteSheet(item: item),
    );
    switch (choice) {
      case _DeleteChoice.lastChapter:
        await cubit.removeHistory(item.latestHistory.slug);
      case _DeleteChoice.allChapters:
        await cubit.removeHistoryBySlug(item.comicSlug);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final details = item.comicDetails;
    final latest = item.latestHistory;
    final progress = ReadProgress.of(details, latest.chapterNumber);

    return Slidable(
      key: ValueKey(item.comicSlug),
      groupTag: 'history',
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.26,
        children: [
          CustomSlidableAction(
            onPressed: _confirmDelete,
            backgroundColor: c.accent,
            foregroundColor: c.onAccent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons300.trash2, color: c.onAccent),
                const SizedBox(height: DotSpace.s2),
                Text(
                  AppText.delete.toUpperCase(),
                  style: DotlineText.label.copyWith(color: c.onAccent),
                ),
              ],
            ),
          ),
        ],
      ),
      child: ColoredBox(
        color: c.surface,
        child: ListRow(
          leading: SizedBox(
            width: 44,
            height: 60,
            child: ComicCover(
              imageUrl: details.coverImg,
              radius: DotRadius.s,
              aspectRatio: null,
            ),
          ),
          title: details.title,
          value: HistoryDay.time(latest.readDate),
          subtitleWidget: Row(
            children: [
              Text(
                'CH. ${latest.chapterNumber}',
                style: DotlineText.data.copyWith(color: c.inkMuted),
              ),
              const SizedBox(width: DotSpace.s3),
              DotMeter(
                value: progress.position,
                total: progress.total,
                dots: 10,
                gap: 2,
              ),
              const SizedBox(width: DotSpace.s3),
              Flexible(
                child: Text(
                  context.sourceNameOf(item.comicSlug).toUpperCase(),
                  style: DotlineText.label.copyWith(color: c.inkFaint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          onTap: () => ComicDetailsScreen.open(
            context,
            slug: item.comicSlug,
            title: details.title,
            cover: details.coverImg,
          ),
        ),
      ),
    );
  }
}

enum _DeleteChoice { lastChapter, allChapters }

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.item});

  final ComicLatestHistory item;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.trash2,
          title: AppText.clearHistory,
          subtitle: item.comicDetails.title,
        ),
        const SizedBox(height: DotSpace.s5),
        ListGroup(
          background: c.bg,
          children: [
            ListRow(
              icon: LucideIcons300.history,
              title: AppText.deleteLastChapter,
              subtitle: 'Chapter ${item.latestHistory.chapterNumber}',
              showChevron: false,
              onTap: () => Navigator.of(context).pop(_DeleteChoice.lastChapter),
            ),
            ListRow(
              icon: LucideIcons300.trash2,
              title: AppText.deleteAllChapters,
              destructive: true,
              showChevron: false,
              onTap: () => Navigator.of(context).pop(_DeleteChoice.allChapters),
            ),
          ],
        ),
        const SizedBox(height: DotSpace.s4),
        DotButton.outline(
          label: AppText.cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
