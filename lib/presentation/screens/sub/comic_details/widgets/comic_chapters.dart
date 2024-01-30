import 'package:bacakomik_app/core/constants/colors.dart';
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
    required this.slug,
  }) : super(key: key);

  final ComicDetailsModel comicDetails;
  final String slug;

  @override
  State<ComicChapters> createState() => _ComicChaptersState();
}

class _ComicChaptersState extends State<ComicChapters> {
  bool _isAscending = false;

  void _goToChapterRead(BuildContext context, String chapter, String slug) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReadChapterScreen(
          slug: slug,
          comicSlug: widget.slug,
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
      return Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 25,
            ),
            onTap: () {
              _goToChapterRead(
                context,
                chapters[index].number,
                chapters[index].slug,
              );
            },
            title: Text('Chapter ${chapters[index].number}'),
            trailing: Text(chapters[index].date),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 25,
            endIndent: 25,
            color: Colors.grey.withOpacity(0.1),
          ),
        ],
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
