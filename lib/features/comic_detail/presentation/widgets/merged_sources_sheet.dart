import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/source_migration.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// The sources of a bookmark in their new order, with the series added
/// ([added], not merged yet).
typedef MergedSourcesEdit = ({List<String> keys, Set<String> added});

/// Shows the sources the bookmark [slug] reads from, [keys] in order: drag
/// to reorder, remove (all but [slug]) or add a series found in another
/// source by [title]. Null when dismissed.
Future<MergedSourcesEdit?> showMergedSourcesSheet(
  BuildContext context, {
  required String slug,
  required List<String> keys,
  required String title,
}) => showDotSheet<MergedSourcesEdit>(
  context: context,
  builder: (_) => _MergedSourcesSheet(slug: slug, keys: keys, title: title),
);

class _MergedSourcesSheet extends StatefulWidget {
  const _MergedSourcesSheet({
    required this.slug,
    required this.keys,
    required this.title,
  });

  final String slug;
  final List<String> keys;
  final String title;

  @override
  State<_MergedSourcesSheet> createState() => _MergedSourcesSheetState();
}

class _MergedSourcesSheetState extends State<_MergedSourcesSheet> {
  late final _keys = [...widget.keys];

  /// Series found by title, by key: their name shows in the row.
  final _added = <String, Comic>{};

  Future<void> _add() async {
    final taken = {for (final k in _keys) ComicKey.sourceOf(k)};
    final comic = await showDotSheet<Comic>(
      context: context,
      builder: (_) => _MergeSearchSheet(
        title: widget.title,
        sources: [
          for (final s in context.read<SourcesCubit>().state.installed)
            if (!taken.contains(s.id)) s.id,
        ],
      ),
    );
    if (comic == null || !mounted || _keys.contains(comic.slug)) return;
    setState(() {
      _keys.add(comic.slug);
      _added[comic.slug] = comic;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final changed =
        _added.isNotEmpty ||
        _keys.length != widget.keys.length ||
        _keys.indexed.any((e) => widget.keys[e.$1] != e.$2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActionSheetHeader(
          icon: LucideIcons300.gitMerge,
          title: AppText.mergedSources,
          subtitle: AppText.mergedSourcesHint,
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverReorderableList(
                itemCount: _keys.length,
                onReorderItem: (from, to) =>
                    setState(() => _keys.insert(to, _keys.removeAt(from))),
                itemBuilder: (context, i) {
                  final key = _keys[i];
                  return Padding(
                    key: ValueKey(key),
                    padding: const EdgeInsets.only(bottom: DotSpace.s2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DotRadius.m),
                      child: ColoredBox(
                        color: c.bg,
                        child: ListRow(
                          leading: ReorderableDragStartListener(
                            index: i,
                            child: Icon(
                              LucideIcons300.gripVertical,
                              color: c.inkFaint,
                            ),
                          ),
                          title: '${i + 1}. ${context.sourceNameOf(key)}',
                          subtitle: _added[key]?.title,
                          trailing: key == widget.slug
                              ? null
                              : RoundIconButton(
                                  icon: LucideIcons300.x,
                                  semanticLabel: AppText.removeSource,
                                  size: 36,
                                  iconSize: DotSize.iconSmall,
                                  background: Colors.transparent,
                                  onTap: () => setState(() {
                                    _keys.removeAt(i);
                                    _added.remove(key);
                                  }),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s2),
        DotButton.outline(
          label: AppText.addSource,
          leading: LucideIcons300.plus,
          onTap: _add,
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton(
          label: AppText.done,
          onTap: changed
              ? () =>
                    Navigator.of(context)
                        .pop((keys: [..._keys], added: {..._added.keys}))
              : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Searches [title] in one of [sources] and pops the comic picked.
class _MergeSearchSheet extends StatefulWidget {
  const _MergeSearchSheet({required this.title, required this.sources});

  final String title;
  final List<String> sources;

  @override
  State<_MergeSearchSheet> createState() => _MergeSearchSheetState();
}

class _MergeSearchSheetState extends State<_MergeSearchSheet> {
  late final _query = TextEditingController(text: widget.title);
  late var _source = widget.sources.firstOrNull;
  List<Comic> _results = const [];
  String? _error;
  var _loading = false;

  /// Counts searches so an older one cannot overwrite a newer one.
  var _run = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final source = _source;
    final query = _query.text.trim();
    if (source == null || query.isEmpty) return;
    final run = ++_run;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await getIt<SearchSource>()((
      sourceId: source,
      query: query,
    ));
    if (!mounted || run != _run) return;
    setState(() {
      _loading = false;
      result.fold((failure) {
        _error = failure.message;
        _results = const [];
      }, (comics) => _results = comics);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionSheetHeader(
            icon: LucideIcons300.search,
            title: AppText.addSource,
            subtitle: AppText.mergeSearchHint,
          ),
          const SizedBox(height: DotSpace.s4),
          SearchField(
            hint: AppText.searchHint,
            controller: _query,
            onSubmitted: (_) => _search(),
            onClear: _query.clear,
          ),
          const SizedBox(height: DotSpace.s3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: DotSpace.s2,
              children: [
                for (final source in widget.sources)
                  DotChip(
                    label: getIt<ExtensionManager>().nameOf(source),
                    selected: source == _source,
                    onTap: () {
                      if (source == _source) return;
                      _source = source;
                      _search();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: DotSpace.s3),
          Expanded(
            child: _loading
                ? const Center(child: DotLoader())
                : widget.sources.isEmpty || _error != null || _results.isEmpty
                ? Center(
                    child: Text(
                      widget.sources.isEmpty
                          ? AppText.noOtherSourceToMerge
                          : _error ?? AppText.noResults,
                      style: DotlineText.body.copyWith(color: c.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, i) {
                      final comic = _results[i];
                      return ListRow(
                        leading: SizedBox(
                          width: 40,
                          child: ComicCover(imageUrl: comic.coverImg),
                        ),
                        title: comic.title,
                        subtitle: comic.latestChapter.isEmpty
                            ? null
                            : 'Ch. ${comic.latestChapter}',
                        onTap: () => Navigator.of(context).pop(comic),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
