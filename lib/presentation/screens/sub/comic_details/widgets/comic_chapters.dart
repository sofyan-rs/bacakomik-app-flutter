import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/chapter_tile.dart';
import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/comic_details.dart';
import 'package:bacakomik_app/presentation/screens/sub/read_chapter/read_chapter_screen.dart';
import 'package:solar_icons/solar_icons.dart';

class ComicChapters extends StatefulWidget {
  const ComicChapters({
    Key? key,
    required this.comicDetails,
    required this.comicSlug,
    required this.onSelectedChapter,
    required this.isInSelectedChapters,
    required this.isHaveSelectedChapter,
  }) : super(key: key);

  final ComicDetailsModel comicDetails;
  final String comicSlug;
  final void Function(SelectedChapter) onSelectedChapter;
  final bool Function(String) isInSelectedChapters;
  final bool isHaveSelectedChapter;

  @override
  State<ComicChapters> createState() => _ComicChaptersState();
}

class _ComicChaptersState extends State<ComicChapters> {
  bool _isAscending = false;

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
    final comicDetails = widget.comicDetails;
    final chapters = _isAscending
        ? comicDetails.chapters.reversed.toList()
        : comicDetails.chapters;

    final List<Widget> topWidget = [
      const SizedBox(height: 30),
      ComicDetails(
        altTitle: comicDetails.alternativeTitle,
        releaseYear: comicDetails.released,
        synopsis: comicDetails.synopsis,
        genres: comicDetails.genres,
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.only(left: 25, right: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppText.chapterList,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                });
              },
              icon: const Icon(
                SolarIconsOutline.sortVertical,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      )
    ];

    Widget buildChapter(int index) {
      return ChapterTile(
        chNumber: chapters[index].number,
        slug: chapters[index].slug,
        date: chapters[index].date,
        goToChapterRead: _goToChapterRead,
        isSelected: widget.isInSelectedChapters(chapters[index].slug),
        onSelected: widget.onSelectedChapter,
        isHaveSelectedChapter: widget.isHaveSelectedChapter
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < topWidget.length) {
            return topWidget[index];
          } else {
            return buildChapter(index - topWidget.length);
          }
        },
        childCount: topWidget.length + chapters.length,
      ),
    );
  }
}
