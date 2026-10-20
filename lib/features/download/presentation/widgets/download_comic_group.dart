import 'dart:io';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:bacakomik_app/features/download/presentation/bloc/download_cubit.dart';
import 'package:bacakomik_app/features/download/presentation/widgets/confirm_delete_sheet.dart';
import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// One comic's downloaded chapters: a comic row (opens the comic, trash
/// deletes all its downloads), then a row per chapter. Tap reads the
/// chapter; swipe left deletes it.
class DownloadComicGroup extends StatelessWidget {
  const DownloadComicGroup({
    super.key,
    required this.comic,
    required this.chapters,
  });

  final DownloadedComic comic;
  final List<DownloadedChapter> chapters;

  Future<void> _confirmDeleteComic(BuildContext context) async {
    final cubit = context.read<DownloadCubit>();
    final confirmed = await showConfirmDeleteSheet(
      context,
      title: AppText.deleteDownloads,
      subtitle: comic.comicDetails.title,
      message: AppText.deleteComicDownloads,
    );
    if (confirmed) await cubit.deleteComic(comic.slug);
  }

  void _read(BuildContext context, DownloadedChapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadChapterScreen(
          slug: chapter.slug,
          comicSlug: comic.slug,
          comicDetails: comic.comicDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final details = comic.comicDetails;
    final size = chapters.fold(0, (sum, c) => sum + c.sizeBytes);

    return SliverListGroup(
      itemCount: chapters.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListRow(
            leading: SizedBox(
              width: 44,
              height: 60,
              child: _Cover(comic: comic),
            ),
            title: details.title,
            subtitleWidget: Text(
              '${chapters.length} ${AppText.chapter} · ${formatBytes(size)}'
                  .toUpperCase(),
              style: DotlineText.data.copyWith(color: c.inkMuted),
            ),
            trailing: RoundIconButton(
              icon: LucideIcons300.trash2,
              semanticLabel: AppText.deleteDownloads,
              iconSize: DotSize.iconSmall,
              onTap: () => _confirmDeleteComic(context),
            ),
            onTap: () => ComicDetailsScreen.open(
              context,
              slug: comic.slug,
              title: details.title,
              cover: details.coverImg,
            ),
          );
        }
        final chapter = chapters[index - 1];
        return Slidable(
          key: ValueKey(chapter.slug),
          groupTag: 'downloads',
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.26,
            children: [
              CustomSlidableAction(
                onPressed: (_) =>
                    context.read<DownloadCubit>().delete([chapter.slug]),
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
              title: '${AppText.chapter} ${chapter.chapterNumber}',
              value: formatBytes(chapter.sizeBytes),
              onTap: () => _read(context, chapter),
            ),
          ),
        );
      },
    );
  }
}

/// The saved cover, or the online one until it has been saved.
class _Cover extends StatelessWidget {
  const _Cover({required this.comic});

  final DownloadedComic comic;

  @override
  Widget build(BuildContext context) {
    final path = comic.coverPath;
    if (path == null) {
      return ComicCover(
        imageUrl: comic.comicDetails.coverImg,
        radius: DotRadius.s,
        aspectRatio: null,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(DotRadius.s),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: (44 * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => ComicCover(
          imageUrl: comic.comicDetails.coverImg,
          radius: DotRadius.s,
          aspectRatio: null,
        ),
      ),
    );
  }
}
