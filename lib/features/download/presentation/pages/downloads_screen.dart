import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:bacakomik_app/features/download/presentation/bloc/download_cubit.dart';
import 'package:bacakomik_app/features/download/presentation/widgets/confirm_delete_sheet.dart';
import 'package:bacakomik_app/features/download/presentation/widgets/download_comic_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Downloads (from More): storage used, the download queue, then the
/// downloaded chapters grouped by comic.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const DownloadsScreen()));

  Future<void> _confirmClear(BuildContext context) async {
    final cubit = context.read<DownloadCubit>();
    final confirmed = await showConfirmDeleteSheet(
      context,
      title: AppText.clearDownloads,
      message: AppText.clearDownloadsConfirmation,
    );
    if (confirmed) await cubit.clear();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<DownloadCubit>().state;
    final pending = library.pending;
    final groups = library.completedByComic;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Outside the scroll view so the title stays put.
            DotTopBar(
              title: AppText.downloads,
              actions: [
                if (library.chapters.isNotEmpty)
                  RoundIconButton(
                    icon: LucideIcons300.trash2,
                    semanticLabel: AppText.clearDownloads,
                    iconSize: DotSize.iconSmall,
                    onTap: () => _confirmClear(context),
                  ),
              ],
            ),
            Expanded(
              child: SlidableAutoCloseBehavior(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        DotSpace.s4,
                        DotSpace.s3,
                        DotSpace.s4,
                        DotSpace.s5,
                      ),
                      sliver: SliverToBoxAdapter(child: _stats(library)),
                    ),
                    if (library.chapters.isEmpty)
                      const SliverToBoxAdapter(
                        child: EmptyState(
                          icon: LucideIcons300.download,
                          title: AppText.downloadsEmpty,
                          message: AppText.downloadsEmptyHint,
                        ),
                      ),
                    if (pending.isNotEmpty)
                      ..._queue(context, library, pending),
                    for (final (comic, chapters) in groups) ...[
                      DownloadComicGroup(
                        key: ValueKey(comic.slug),
                        comic: comic,
                        chapters: chapters,
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: DotSpace.s3),
                      ),
                    ],
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: bottomInset + DotSpace.s4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(DownloadLibrary library) => Row(
    children: [
      Expanded(
        child: StatTile(
          value: '${library.completedCount}',
          label: AppText.downloadedChapters,
          labelOnTop: true,
        ),
      ),
      const SizedBox(width: DotSpace.s3),
      Expanded(
        child: StatTile(
          value: formatBytes(library.totalBytes),
          label: AppText.storageUsed,
          labelOnTop: true,
        ),
      ),
    ],
  );

  List<Widget> _queue(
    BuildContext context,
    DownloadLibrary library,
    List<DownloadedChapter> pending,
  ) {
    final failed = [
      for (final chapter in pending)
        if (chapter.status == DownloadStatus.failed) chapter.slug,
    ];
    return [
      SliverToBoxAdapter(
        child: SectionLabel(
          label: AppText.downloadQueue,
          actionLabel: failed.isEmpty ? null : AppText.downloadRetryAll,
          onAction: failed.isEmpty
              ? null
              : () => context.read<DownloadCubit>().retry(failed),
        ),
      ),
      SliverListGroup(
        itemCount: pending.length,
        itemBuilder: (context, index) => _PendingRow(
          chapter: pending[index],
          comicTitle:
              library.comics[pending[index].comicSlug]?.comicDetails.title ??
              pending[index].comicSlug,
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: DotSpace.s5)),
    ];
  }
}

/// A queued, downloading or failed chapter with retry and cancel.
class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.chapter, required this.comicTitle});

  final DownloadedChapter chapter;
  final String comicTitle;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final cubit = context.read<DownloadCubit>();
    final failed = chapter.status == DownloadStatus.failed;
    final status = switch (chapter.status) {
      DownloadStatus.queued => AppText.downloadWaiting,
      DownloadStatus.failed => AppText.downloadFailed,
      _ when chapter.pageCount == 0 => '…',
      _ => '${chapter.savedPages}/${chapter.pageCount} ${AppText.pages}',
    };

    return ListRow(
      title: comicTitle,
      subtitleWidget: Row(
        children: [
          Text(
            'CH. ${chapter.chapterNumber}',
            style: DotlineText.data.copyWith(color: c.inkMuted),
          ),
          const SizedBox(width: DotSpace.s3),
          Flexible(
            child: Text(
              status.toUpperCase(),
              style: DotlineText.data.copyWith(
                color: failed ? c.accentText : c.inkFaint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chapter.status == DownloadStatus.downloading &&
              chapter.pageCount > 0) ...[
            const SizedBox(width: DotSpace.s3),
            DotMeter(
              value: chapter.savedPages,
              total: chapter.pageCount,
              dots: 10,
              gap: 2,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failed) ...[
            RoundIconButton(
              icon: LucideIcons300.rotateCw,
              semanticLabel: AppText.downloadRetry,
              iconSize: DotSize.iconSmall,
              onTap: () => cubit.retry([chapter.slug]),
            ),
            const SizedBox(width: DotSpace.s2),
          ],
          RoundIconButton(
            icon: LucideIcons300.x,
            semanticLabel: AppText.downloadCancel,
            iconSize: DotSize.iconSmall,
            onTap: () => cubit.delete([chapter.slug]),
          ),
        ],
      ),
    );
  }
}
