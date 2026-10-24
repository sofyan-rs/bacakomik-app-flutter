import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/deep_links.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_app_bar.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_chapters.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_cover.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_info.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_title.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    context.read<ComicDetailsBloc>().add(ComicDetailsRequested(widget.slug));
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

  /// Explore filtered by [genre] alone, in this comic's source, on top of
  /// the tabs.
  void _exploreGenre(Genre genre) {
    final source = ComicKey.sourceOf(widget.slug);
    context.read<FilterCubit>().showGenre(source, genre.slug);
    context.read<SourcesCubit>().select(source);
    RootTabsScope.read(context).openExploreFiltered();
    Navigator.of(context).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComicDetailsBloc, ComicDetailsState>(
      builder: (context, state) {
        final details = state is ComicDetailsLoaded ? state.comicDetails : null;
        return PopScope(
          canPop: _selected.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _setSelected(const []);
          },
          child: Scaffold(
            bottomNavigationBar: details == null
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
                        actions: [
                          RoundIconButton(
                            icon: LucideIcons300.share2,
                            semanticLabel: AppText.share,
                            iconSize: DotSize.iconSmall,
                            onTap: () => _share(details?.title ?? widget.title),
                          ),
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

  List<Widget> _body(ComicDetailsState state) => switch (state) {
    ComicDetailsLoaded(:final comicDetails) => [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          DotSpace.s4,
          DotSpace.s5,
          DotSpace.s4,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: ComicInfo(details: comicDetails, onGenreTap: _exploreGenre),
        ),
      ),
      ComicChapters(
        comicDetails: comicDetails,
        onOpenChapter: (chapter) => _read(comicDetails, chapter.slug),
        onToggleSelected: _toggleSelected,
        isSelected: _isSelected,
        isSelecting: _selected.isNotEmpty,
      ),
    ],
    ComicDetailsNoInternet() => [
      SliverToBoxAdapter(child: EmptyState.offline(onAction: _load)),
    ],
    ComicDetailsError(:final message) => [
      SliverToBoxAdapter(
        child: EmptyState(
          icon: LucideIcons300.bug,
          title: AppText.error,
          message: message,
          actionLabel: AppText.retry,
          onAction: _load,
        ),
      ),
    ],
    ComicDetailsInitial() ||
    ComicDetailsLoading() => [SliverToBoxAdapter(child: _loadingTitle())],
  };

  /// Title from the previous screen while the details load.
  Widget _loadingTitle() {
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
          const SizedBox(height: DotSpace.s6),
          const DotLoader(),
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
