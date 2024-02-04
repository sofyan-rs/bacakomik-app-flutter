import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChapterTile extends StatefulWidget {
  const ChapterTile({
    Key? key,
    required this.chNumber,
    required this.slug,
    required this.date,
    required this.goToChapterRead,
    required this.isSelected,
    required this.onSelected,
    required this.isHaveSelectedChapter,
  }) : super(key: key);

  final String chNumber;
  final String slug;
  final String date;
  final void Function(BuildContext context, String slug) goToChapterRead;
  final bool isSelected;
  final void Function(SelectedChapter) onSelected;
  final bool isHaveSelectedChapter;

  @override
  State<ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<ChapterTile> {
  @override
  Widget build(BuildContext context) {
    bool isInHistory = context.watch<HistoryCubit>().isInHistory(widget.slug);

    return Column(
      children: [
        ListTile(
          selected: widget.isSelected,
          selectedTileColor:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
          ),
          onTap: () {
            if (widget.isHaveSelectedChapter) {
              widget.onSelected(SelectedChapter(
                chapterNumber: widget.chNumber,
                slug: widget.slug,
              ));
            } else {
              widget.goToChapterRead(context, widget.slug);
            }
          },
          onLongPress: () {
            widget.onSelected(SelectedChapter(
              chapterNumber: widget.chNumber,
              slug: widget.slug,
            ));
          },
          title: Text(
            'Chapter ${widget.chNumber}',
            style: TextStyle(
              color: isInHistory
                  ? Theme.of(context).colorScheme.onBackground.withOpacity(0.4)
                  : Theme.of(context).colorScheme.onBackground,
            ),
          ),
          trailing: Text(
            widget.date,
            style: TextStyle(
              color: isInHistory
                  ? Theme.of(context).colorScheme.onBackground.withOpacity(0.4)
                  : Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          // indent: 25,
          // endIndent: 25,
          color: Colors.grey.withOpacity(0.2),
        ),
      ],
    );
  }
}
