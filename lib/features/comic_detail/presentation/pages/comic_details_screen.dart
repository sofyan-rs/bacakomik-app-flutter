import 'dart:async';

import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/deep_links.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/merge_sources.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/merged_sources_sheet.dart';
import 'package:bacakomik_app/features/migration/presentation/widgets/source_choice_sheet.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_app_bar.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_chapters.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_cover.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_info.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_title.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/source_migration_screen.dart';
import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/pages/web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/missing_source.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/mihon_source.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_error.dart';

class ComicDetailsScreen extends StatelessWidget {
  const ComicDetailsScreen({
    super.key,
    required this.title,
    required this.slug,
    this.cover,
  });

  final String title;
  final String slug;
  final String? cover;

  static Future<void> open(
    BuildContext context, {
    required String slug,
    required String title,
    String? cover,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ComicDetailsScreen(slug: slug, title: title, cover: cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ComicDetailsBloc>(),
      child: _ComicDetailsView(title: title, slug: slug, cover: cover),
    );
  }
}

class _ComicDetailsView extends StatefulWidget {
  const _ComicDetailsView({
    required this.title,
    required this.slug,
    this.cover,
  });

  final String title;
  final String slug;
  final String? cover;

  @override
  State<_ComicDetailsView> createState() => _ComicDetailsViewState();
}

class _ComicDetailsViewState extends State<_ComicDetailsView> {
  /// Selected chapters by slug, in selection order.
  final _selected = <String, SelectedChapter>{};

  late final _sourceId = ComicKey.sourceOf(widget.slug);

  /// The comic's source extension is not installed: show [MissingSource]
  /// instead of loading.
  var _sourceMissing = false;

  /// The source's filters, to open Explore on a genre; null until loaded
  /// or when they don't load (genres are then plain labels).
  SourceFeatures? _features;

  @override
  void initState() {
    super.initState();
    _load(fetch: false);
    _loadFeatures();
    _loadScanlators();
  }

  /// Scanlators of a Mihon comic with several (empty otherwise), and the
  /// one picked.
  var _scanlators = const <String>[];
  String? _scanlator;

  Future<void> _loadScanlators() async {
    try {
      final backend = await getIt<ExtensionManager>().backend(_sourceId);
      if (backend is! MihonSource) return;
      final result = await backend.scanlators(ComicKey.slugOf(widget.slug));
      if (!mounted) return;
      setState(() {
        _scanlators = result.names.length > 1 ? result.names : const [];
        _scanlator = result.picked;
      });
    } catch (_) {
      // Offline or failed: no picker.
    }
  }

  Future<void> _pickScanlator() async {
    final c = Dotline.of(context);
    final picked = await showDotSheet<({String? name})>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ActionSheetHeader(
            icon: LucideIcons300.users,
            title: AppText.scanlators,
            subtitle: AppText.scanlatorsHint,
          ),
          const SizedBox(height: DotSpace.s4),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListGroup(
                  background: c.bg,
                  children: [
                    for (final name in [null, ..._scanlators])
                      ListRow(
                        title: name ?? AppText.sourceOrder,
                        trailing: name == _scanlator
                            ? Icon(LucideIcons300.check, color: c.ink)
                            : null,
                        onTap: () => Navigator.of(context).pop((name: name)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null || picked.name == _scanlator || !mounted) return;
    final backend = await getIt<ExtensionManager>().backend(_sourceId);
    if (backend is! MihonSource) return;
    await backend.setScanlator(ComicKey.slugOf(widget.slug), picked.name);
    if (!mounted) return;
    setState(() => _scanlator = picked.name);
    await _load();
  }

  Future<void> _loadFeatures() async {
    try {
      final backend = await getIt<ExtensionManager>().backend(_sourceId);
      final features = await backend.features();
      if (mounted) setState(() => _features = features);
    } catch (_) {
      // Offline or missing source: genres stay plain.
    }
  }

  /// Without [fetch], a bookmarked comic shows its bookmark's details
  /// without a request; pull-to-refresh fetches them. An imported bookmark
  /// not loaded yet is always fetched.
  Future<void> _load({bool fetch = true}) async {
    final missing = getIt<ExtensionManager>().meta(_sourceId) == null;
    if (missing != _sourceMissing) setState(() => _sourceMissing = missing);
    if (missing) return;
    if (fetch) {
      // The picked source's chapters load again with the rest.
      _sourceChapters.clear();
      if (_chapterSource != null) unawaited(_pickChapterSource(_chapterSource));
    }
    ComicDetails? stored;
    if (!fetch) {
      for (final bookmark in context.read<BookmarkCubit>().state) {
        if (bookmark.slug != widget.slug) continue;
        final details = bookmark.comicDetails;
        if (!details.isPlaceholder && details.chapters.isNotEmpty) {
          stored = details;
        }
        break;
      }
    }
    context.read<ComicDetailsBloc>().add(
      ComicDetailsRequested(widget.slug, stored: stored),
    );
  }

  void _toggleSelected(SelectedChapter chapter) {
    setState(() {
      if (_selected.remove(chapter.slug) == null) {
        _selected[chapter.slug] = chapter;
      }
    });
  }

  void _setSelected(List<SelectedChapter> chapters) => setState(() {
    _selected
      ..clear()
      ..addEntries(chapters.map((c) => MapEntry(c.slug, c)));
  });

  bool _isSelected(String slug) => _selected.containsKey(slug);

  void _read(ComicDetails details, String chapterSlug) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadChapterScreen(
          slug: chapterSlug,
          comicSlug: widget.slug,
          comicDetails: details,
        ),
      ),
    );
  }

  /// The merged comic's source whose chapters alone are listed; null for
  /// all.
  String? _chapterSource;

  /// Every chapter of each source picked, by series key: the merged list
  /// has only those it took from it.
  final _sourceChapters = <String, List<Chapter>>{};

  /// The chapters of [_chapterSource] are loading.
  var _sourceLoading = false;

  /// Lists the chapters of [key] alone, loading them all from the source
  /// the first time; offline, those the merged list took from it.
  Future<void> _pickChapterSource(String? key) async {
    final load = key != null && !_sourceChapters.containsKey(key);
    setState(() {
      _chapterSource = key;
      _sourceLoading = load;
    });
    if (!load) return;
    final result = await getIt<FetchMergedChapters>()([key], const []);
    if (!mounted || _chapterSource != key) return;
    setState(() {
      _sourceLoading = false;
      result.fold((_) {}, (chapters) => _sourceChapters[key] = chapters);
    });
  }

  /// Opens the comic's page on its site; a merged comic asks which
  /// source's.
  Future<void> _openWebView(Bookmark? bookmark) async {
    var key = widget.slug;
    if (bookmark != null && bookmark.isMerged) {
      final picked = await showSourceChoiceSheet(
        context,
        title: AppText.openWebView,
        choices: [
          for (final k in bookmark.sourceKeys)
            (id: k, name: context.sourceNameOf(k), detail: null),
        ],
      );
      if (picked == null || !mounted) return;
      key = picked;
    }
    await WebViewScreen.openSeries(
      context,
      sourceId: ComicKey.sourceOf(key),
      key: key,
    );
  }

  /// Lists every source's copy of a number, or one per number; the comic
  /// loads again to list the copies it dropped.
  Future<void> _setKeepDuplicates(bool keep) async {
    await context.read<BookmarkCubit>().setKeepDuplicates(widget.slug, keep);
    if (!mounted) return;
    await context.read<HistoryCubit>().load();
    await _load();
  }

  /// Edits the sources the bookmark reads from: series added are merged
  /// in, then the order and removals saved, and the comic loaded again.
  Future<void> _editSources(Bookmark bookmark, String title) async {
    final edit = await showMergedSourcesSheet(
      context,
      slug: widget.slug,
      keys: bookmark.sourceKeys,
      title: title,
    );
    if (edit == null || !mounted) return;
    final bookmarks = context.read<BookmarkCubit>();
    final history = context.read<HistoryCubit>();
    for (final key in edit.added) {
      await bookmarks.merge(into: widget.slug, add: key);
    }
    await bookmarks.setMergedSources(widget.slug, edit.keys);
    if (!mounted) return;
    await history.load();
    if (edit.added.isNotEmpty && mounted) {
      showSnackBar(context: context, message: AppText.merged);
    }
    await _load();
  }

  /// Explore filtered by [genre] alone, in this comic's source, on top of
  /// the tabs.
  void _exploreGenre(Genre genre) {
    final filter = _features?.genreFilter(genre.slug, genre.name);
    if (filter == null) return;
    final source = ComicKey.sourceOf(widget.slug);
    context.read<FilterCubit>().showGenre(source, filter.key, filter.value);
    context.read<SourcesCubit>().select(source);
    RootTabsScope.read(context).openExploreFiltered();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Gives the bookmark the loaded details (cover, chapter count) and
  /// applies imported reading progress.
  Future<void> _onLoaded(BuildContext context, ComicDetailsState state) async {
    if (state is! ComicDetailsLoaded) return;
    final history = context.read<HistoryCubit>();
    final changed = await context.read<BookmarkCubit>().comicLoaded(
      widget.slug,
      state.comicDetails,
      fresh: !state.stored,
    );
    if (changed) await history.load();
  }

  void _share(String title) {
    final link = DeepLinks.comic(widget.slug);
    SharePlus.instance.share(
      ShareParams(
        text: '$title — ${AppText.shareSuffix}\n$link',
        subject: title,
      ),
    );
  }

  /// A chapter list that takes long (sources that read it page by page)
  /// gets a note after [_slowAfter]; the note goes once the list is in.
  static const _slowAfter = Duration(seconds: 4);
  Timer? _slowChapters;
  ScaffoldMessengerState? _slowNote;

  @override
  void dispose() {
    _slowChapters?.cancel();
    _slowNote?.hideCurrentSnackBar();
    super.dispose();
  }

  void _onChaptersLoading(BuildContext context, ComicDetailsState state) {
    if (state is ComicDetailsLoaded && state.chaptersLoading) {
      _slowChapters ??= Timer(_slowAfter, () {
        if (!mounted) return;
        _slowNote = ScaffoldMessenger.of(this.context);
        showSnackBar(
          context: this.context,
          message: AppText.chaptersLoadingSlow,
          duration: const Duration(minutes: 5),
        );
      });
      return;
    }
    _slowChapters?.cancel();
    _slowChapters = null;
    _slowNote?.hideCurrentSnackBar();
    _slowNote = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ComicDetailsBloc, ComicDetailsState>(
      listener: _onChaptersLoading,
      child: _content(),
    );
  }

  Widget _content() {
    return BlocConsumer<ComicDetailsBloc, ComicDetailsState>(
      listenWhen: (_, state) =>
          state is ComicDetailsLoaded && !state.chaptersLoading,
      listener: _onLoaded,
      builder: (context, state) {
        final details = state is ComicDetailsLoaded ? state.comicDetails : null;
        final bookmark = context
            .watch<BookmarkCubit>()
            .state
            .where((b) => b.slug == widget.slug)
            .firstOrNull;
        // Bookmarking or downloading waits for the chapter list.
        final ready = state is ComicDetailsLoaded && !state.chaptersLoading;
        return PopScope(
          canPop: _selected.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _setSelected(const []);
          },
          child: Scaffold(
            bottomNavigationBar: details == null || !ready
                ? null
                : ComicAppBar(
                    comicSlug: widget.slug,
                    comicDetails: details,
                    selectedChapters: _selected.values.toList(),
                    selectAllChapter: _setSelected,
                    unselectAllChapter: () => _setSelected(const []),
                    onRead: (slug) => _read(details, slug),
                  ),
            body: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: Dotline.of(context).ink,
                backgroundColor: Dotline.of(context).surface,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DotTopBar(
                        // Hidden until the source is installed.
                        actions: [
                          if (!_sourceMissing) ...[
                            if (bookmark != null)
                              RoundIconButton(
                                icon: LucideIcons300.gitMerge,
                                semanticLabel: AppText.mergedSources,
                                iconSize: DotSize.iconSmall,
                                onTap: () => _editSources(
                                  bookmark,
                                  details?.title ?? widget.title,
                                ),
                              ),
                            // Migrating would drop the other merged sources.
                            if (bookmark != null && !bookmark.isMerged)
                              RoundIconButton(
                                icon: LucideIcons300.arrowRightLeft,
                                semanticLabel: AppText.migrateSource,
                                iconSize: DotSize.iconSmall,
                                onTap: () => SourceMigrationScreen.open(
                                  context,
                                  keys: {widget.slug},
                                ),
                              ),
                            RoundIconButton(
                              icon: LucideIcons300.globe,
                              semanticLabel: AppText.openWebView,
                              iconSize: DotSize.iconSmall,
                              onTap: () => _openWebView(bookmark),
                            ),
                            RoundIconButton(
                              icon: LucideIcons300.share2,
                              semanticLabel: AppText.share,
                              iconSize: DotSize.iconSmall,
                              onTap: () =>
                                  _share(details?.title ?? widget.title),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DetailCover(
                        cover: details?.coverImg ?? widget.cover,
                      ),
                    ),
                    ..._body(state),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: DotSpace.s6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Bookmark? get _bookmark => context
      .watch<BookmarkCubit>()
      .state
      .where((b) => b.slug == widget.slug)
      .firstOrNull;

  List<Widget> _body(ComicDetailsState state) => _sourceMissing
      ? [
          SliverToBoxAdapter(child: _loadingTitle(loading: false)),
          SliverToBoxAdapter(
            child: MissingSource(sourceId: _sourceId, onInstalled: _load),
          ),
        ]
      : switch (state) {
          ComicDetailsLoaded(:final comicDetails, :final chaptersLoading) => [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DotSpace.s4,
                DotSpace.s5,
                DotSpace.s4,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: ComicInfo(
                  details: comicDetails,
                  chaptersLoading: chaptersLoading,
                  // A merged comic names its first source and counts the
                  // rest; the merge sheet lists them.
                  source: switch (_bookmark) {
                    final b? when b.isMerged =>
                      '${context.sourceNameOf(b.sourceKeys.first)} '
                          '+${b.sourceKeys.length - 1}',
                    _ => context.sourceLabelOf(widget.slug),
                  },
                  onGenreTap: _exploreGenre,
                  canTapGenre: (genre) =>
                      _features?.genreFilter(genre.slug, genre.name) != null,
                ),
              ),
            ),
            ComicChapters(
              comicDetails: comicDetails,
              loading: chaptersLoading || _sourceLoading,
              onOpenChapter: (chapter) => _read(comicDetails, chapter.slug),
              onToggleSelected: _toggleSelected,
              isSelected: _isSelected,
              isSelecting: _selected.isNotEmpty,
              onScanlators: _scanlators.isEmpty ? null : _pickScanlator,
              sources: switch (_bookmark) {
                final b? when b.isMerged => b.sourceKeys,
                _ => const [],
              },
              source: _chapterSource,
              sourceChapters: _sourceLoading
                  ? const []
                  : _sourceChapters[_chapterSource],
              onPickSource: _pickChapterSource,
              keepDuplicates: _bookmark?.keepDuplicates ?? false,
              onKeepDuplicates: _setKeepDuplicates,
            ),
          ],
          ComicDetailsNoInternet() => [
            SliverToBoxAdapter(child: EmptyState.offline(onAction: _load)),
          ],
          ComicDetailsError(:final message) => [
            SliverToBoxAdapter(
              child: SourceError(
                message: message,
                sourceId: _sourceId,
                onRetry: _load,
              ),
            ),
          ],
          ComicDetailsInitial() ||
          ComicDetailsLoading() => [SliverToBoxAdapter(child: _loadingTitle())],
        };

  /// Title from the previous screen while the details load, with a loader
  /// unless [loading] is false.
  Widget _loadingTitle({bool loading = true}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DotSpace.s4,
        DotSpace.s5,
        DotSpace.s4,
        0,
      ),
      child: Column(
        children: [
          ComicTitle(widget.title),
          if (loading) ...[
            const SizedBox(height: DotSpace.s6),
            const DotLoader(),
          ],
        ],
      ),
    );
  }
}

class SelectedChapter {
  const SelectedChapter({required this.slug, required this.chapterNumber});

  final String slug;
  final String chapterNumber;
}
