import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';

class ComicAppBar extends StatefulWidget {
  const ComicAppBar({
    super.key,
    required this.comicSlug,
    required this.comicDetails,
    required this.selectedChapters,
    required this.selectAllChapter,
    required this.unselectAllChapter,
  });

  final String comicSlug;
  final ComicDetails comicDetails;
  final List<SelectedChapter> selectedChapters;
  final void Function(List<SelectedChapter>) selectAllChapter;
  final void Function() unselectAllChapter;

  @override
  State<ComicAppBar> createState() => _ComicAppBarState();
}

class _ComicAppBarState extends State<ComicAppBar> {
  void _goToChapterRead(BuildContext context, String slug) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReadChapterScreen(
          slug: slug,
          comicSlug: widget.comicSlug,
          comicDetails: widget.comicDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isInBookmarks =
        context.watch<BookmarkCubit>().isBookmark(widget.comicSlug);
    ReadHistory? latestHistory =
        context.watch<HistoryCubit>().getLatestHistoryBySlug(widget.comicSlug);

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (!isInBookmarks) {
                context
                    .read<BookmarkCubit>()
                    .addBookmark(widget.comicDetails, widget.comicSlug);
                showSnackBar(
                  context: context,
                  message: AppText.addedToBookmark,
                  icon: Icon(
                    SolarIconsOutline.bookmarkSquareMinimalistic,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                );
              } else {
                context.read<BookmarkCubit>().removeBookmark(widget.comicSlug);
                showSnackBar(
                  context: context,
                  message: AppText.removedFromBookmark,
                  icon: Icon(
                    SolarIconsOutline.trashBinMinimalistic,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                );
              }
            },
            icon: Icon(
              isInBookmarks ? SolarIconsBold.heart : SolarIconsOutline.heart,
              color: AppColors.primary,
            ),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              padding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(width: 20),
          widget.selectedChapters.isNotEmpty
              ? Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        List<ReadHistory> historyList = [];
                        for (var chapter in widget.selectedChapters) {
                          historyList.add(
                            ReadHistory(
                              comicSlug: widget.comicSlug,
                              chapterNumber: chapter.chapterNumber,
                              comicDetails: widget.comicDetails,
                              readDate: DateTime.now(),
                              slug: chapter.slug,
                            ),
                          );
                        }
                        context
                            .read<HistoryCubit>()
                            .addHistoryList(historyList);
                        widget.unselectAllChapter();
                      },
                      icon: const Icon(
                        SolarIconsOutline.chatRead,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<HistoryCubit>().removeHistoryList(
                              widget.selectedChapters
                                  .map((e) => e.slug)
                                  .toList(),
                            );
                        widget.unselectAllChapter();
                      },
                      icon: const Icon(
                        SolarIconsOutline.restart,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {
                        widget.selectAllChapter(
                          widget.comicDetails.chapters
                              .map(
                                (e) => SelectedChapter(
                                  chapterNumber: e.number,
                                  slug: e.slug,
                                ),
                              )
                              .toList()
                              .reversed
                              .toList(),
                        );
                      },
                      icon: const Icon(
                        SolarIconsOutline.listCheckMinimalistic,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        widget.unselectAllChapter();
                      },
                      icon: const Icon(
                        SolarIconsOutline.closeCircle,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                )
              : Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (latestHistory != null) {
                        _goToChapterRead(
                          context,
                          latestHistory.slug,
                        );
                      } else {
                        _goToChapterRead(
                          context,
                          widget.comicDetails.chapters.last.slug,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      latestHistory != null
                          ? AppText.continueRead
                          : AppText.readNow,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
