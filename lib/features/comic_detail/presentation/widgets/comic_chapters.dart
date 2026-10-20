import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_tile.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// "Chapter 49" header with search and sort, then the chapter rows.
///
/// Tap opens a chapter; long press starts selecting (the bottom bar then
/// marks the selection read or unread). While selecting, tap toggles.
class ComicChapters extends StatefulWidget {
  const ComicChapters({
    super.key,
    required this.comicDetails,
    required this.onOpenChapter,
    required this.onToggleSelected,
    required this.isSelected,
    required this.isSelecting,
  });

  final ComicDetails comicDetails;
  final void Function(Chapter chapter) onOpenChapter;
  final void Function(SelectedChapter chapter) onToggleSelected;
  final bool Function(String slug) isSelected;
  final bool isSelecting;

  @override
  State<ComicChapters> createState() => _ComicChaptersState();
}

class _ComicChaptersState extends State<ComicChapters> {
  /// API order is newest first.
  var _newestFirst = true;
  var _searching = false;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Chapter> get _chapters {
    final all = widget.comicDetails.chapters;
    final query = _query.text.trim();
    final filtered = query.isEmpty
        ? all
        : all.where((c) => c.number.contains(query)).toList();
    return _newestFirst ? filtered : filtered.reversed.toList();
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) _query.clear();
  });

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final history = context.watch<HistoryCubit>();
    final chapters = _chapters;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DotSpace.s4,
              DotSpace.s6,
              DotSpace.s4,
              DotSpace.s3,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppText.chapter,
                      style: DotlineText.title.copyWith(color: c.ink),
                    ),
                    const SizedBox(width: DotSpace.s2),
                    Text(
                      '${widget.comicDetails.chapters.length}',
                      style: DotlineText.data.copyWith(color: c.inkFaint),
                    ),
                    const Spacer(),
                    RoundIconButton(
                      icon: _searching
                          ? LucideIcons300.x
                          : LucideIcons300.search,
                      semanticLabel: AppText.searchChapter,
                      iconSize: DotSize.iconSmall,
                      onTap: _toggleSearch,
                    ),
                    const SizedBox(width: DotSpace.s2),
                    RoundIconButton(
                      icon: LucideIcons300.arrowDownUp,
                      semanticLabel: AppText.sortChapter,
                      iconSize: DotSize.iconSmall,
                      onTap: () => setState(() => _newestFirst = !_newestFirst),
                    ),
                  ],
                ),
                if (_searching) ...[
                  const SizedBox(height: DotSpace.s3),
                  SearchField(
                    hint: AppText.searchChapterHint,
                    controller: _query,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(_query.clear),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          sliver: SliverList.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              final selected = SelectedChapter(
                slug: chapter.slug,
                chapterNumber: chapter.number,
              );
              return ChapterTile(
                chapter: chapter,
                history: history.index.chapter(chapter.slug),
                isSelected: widget.isSelected(chapter.slug),
                isFirst: index == 0,
                isLast: index == chapters.length - 1,
                onTap: () => widget.isSelecting
                    ? widget.onToggleSelected(selected)
                    : widget.onOpenChapter(chapter),
                onLongPress: () => widget.onToggleSelected(selected),
              );
            },
          ),
        ),
      ],
    );
  }
}
