import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/merged_chapters.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_tile.dart';
import 'package:bacakomik_app/features/download/presentation/bloc/download_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
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
    this.onScanlators,
    this.sources = const [],
    this.source,
    this.sourceChapters,
    this.onPickSource,
    this.keepDuplicates = false,
    this.onKeepDuplicates,
    this.loading = false,
    this.top = DotSpace.s6,
  });

  final ComicDetails comicDetails;
  final void Function(Chapter chapter) onOpenChapter;
  final void Function(SelectedChapter chapter) onToggleSelected;
  final bool Function(String slug) isSelected;
  final bool isSelecting;

  /// Opens the scanlator picker; null hides its button (one scanlator).
  final VoidCallback? onScanlators;

  /// Series keys of a merged comic, in order: the list can show the
  /// chapters of one of them. Empty for a comic with one source.
  final List<String> sources;

  /// The one of [sources] whose chapters alone are shown; null for all.
  final String? source;

  /// Every chapter of [source], merged list or not; null while not loaded,
  /// when the chapters the merged list took from it are shown.
  final List<Chapter>? sourceChapters;

  /// The user picked a source to show, or null for all.
  final void Function(String? key)? onPickSource;

  /// The merged list keeps every source's copy of a number.
  final bool keepDuplicates;

  /// Turns [keepDuplicates] on or off.
  final void Function(bool keep)? onKeepDuplicates;

  /// Space above the heading: less beside the details on wide screens.
  final double top;

  /// The list is still loading: a loader instead of rows.
  final bool loading;

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
    final source = _shownSource;
    final all = source == null
        ? widget.comicDetails.chapters
        : widget.sourceChapters ??
              chaptersOf(widget.comicDetails.chapters, source);
    final query = _query.text.trim();
    final filtered = query.isEmpty
        ? all
        : all
              .where(
                (c) =>
                    c.number.contains(query) ||
                    (c.title?.toLowerCase().contains(query.toLowerCase()) ??
                        false),
              )
              .toList();
    return _newestFirst ? filtered : filtered.reversed.toList();
  }

  /// [ComicChapters.source] while it is still one of the comic's sources.
  String? get _shownSource =>
      widget.sources.contains(widget.source) ? widget.source : null;

  /// Like the scanlator picker: all sources, or the chapters of one; and
  /// whether a number several sources have is listed once.
  Future<void> _pickSource() async {
    final c = Dotline.of(context);
    final picked = await showDotSheet<({String? key, bool? keep})>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ActionSheetHeader(
            icon: LucideIcons300.gitMerge,
            title: AppText.chapterSources,
            subtitle: AppText.chapterSourcesHint,
          ),
          const SizedBox(height: DotSpace.s4),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListGroup(
                  background: c.bg,
                  children: [
                    for (final key in [null, ...widget.sources])
                      ListRow(
                        title: key == null
                            ? AppText.allSources
                            : context.sourceNameOf(key),
                        trailing: key == _shownSource
                            ? Icon(LucideIcons300.check, color: c.ink)
                            : null,
                        onTap: () =>
                            Navigator.of(context).pop((key: key, keep: null)),
                      ),
                  ],
                ),
                const SizedBox(height: DotSpace.s3),
                ListGroup(
                  background: c.bg,
                  children: [
                    ListRow(
                      title: AppText.dedupeChapters,
                      subtitle: AppText.dedupeChaptersHint,
                      trailing: DotSwitch(
                        value: !widget.keepDuplicates,
                        semanticLabel: AppText.dedupeChapters,
                        onChanged: (dedupe) =>
                            Navigator.of(context)
                                .pop((key: _shownSource, keep: !dedupe)),
                      ),
                      onTap: () => Navigator.of(
                        context,
                      ).pop((key: _shownSource, keep: !widget.keepDuplicates)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    if (picked.keep case final keep?) {
      widget.onKeepDuplicates?.call(keep);
    } else if (picked.key != _shownSource) {
      widget.onPickSource?.call(picked.key);
    }
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) _query.clear();
  });

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final history = context.watch<HistoryCubit>();
    final downloads = context.watch<DownloadCubit>().state;
    final chapters = _chapters;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              DotSpace.s4,
              widget.top,
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
                    if (widget.sources.length > 1) ...[
                      RoundIconButton(
                        icon: LucideIcons300.gitMerge,
                        semanticLabel: AppText.chapterSources,
                        iconSize: DotSize.iconSmall,
                        // Filled while one source is picked.
                        background: _shownSource == null ? null : c.ink,
                        foreground: _shownSource == null ? null : c.onInk,
                        onTap: _pickSource,
                      ),
                      const SizedBox(width: DotSpace.s2),
                    ],
                    if (widget.onScanlators case final onTap?) ...[
                      RoundIconButton(
                        icon: LucideIcons300.users,
                        semanticLabel: AppText.scanlators,
                        iconSize: DotSize.iconSmall,
                        onTap: onTap,
                      ),
                      const SizedBox(width: DotSpace.s2),
                    ],
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
        if (widget.loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(DotSpace.s6),
              child: Center(child: DotLoader()),
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
                download: downloads.chapter(chapter.slug),
                isSelected: widget.isSelected(chapter.slug),
                isFirst: index == 0,
                isLast: index == chapters.length - 1,
                onTap: () => widget.isSelecting
                    ? widget.onToggleSelected(selected)
                    : widget.onOpenChapter(chapter),
                onLongPress: () => widget.onToggleSelected(selected),
                source: widget.sources.length > 1
                    ? context.sourceNameOf(seriesKeyOfChapter(chapter.slug))
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
