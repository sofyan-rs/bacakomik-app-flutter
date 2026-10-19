import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_app_bar.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_chapters.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_cover.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_info.dart';
import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';
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
  List<SelectedChapter> _selectedChapters = [];

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
      final index = _selectedChapters.indexWhere((s) => s.slug == chapter.slug);
      index >= 0
          ? _selectedChapters.removeAt(index)
          : _selectedChapters.add(chapter);
    });
  }

  bool _isSelected(String slug) => _selectedChapters.any((c) => c.slug == slug);

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

  void _share(String title) {
    SharePlus.instance.share(
      ShareParams(text: '$title — ${AppText.shareSuffix}', subject: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComicDetailsBloc, ComicDetailsState>(
      builder: (context, state) {
        final details = state is ComicDetailsLoaded ? state.comicDetails : null;
        return PopScope(
          canPop: _selectedChapters.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _selectedChapters = []);
          },
          child: Scaffold(
            bottomNavigationBar: details == null
                ? null
                : ComicAppBar(
                    comicSlug: widget.slug,
                    comicDetails: details,
                    selectedChapters: _selectedChapters,
                    selectAllChapter: (all) =>
                        setState(() => _selectedChapters = all),
                    unselectAllChapter: () =>
                        setState(() => _selectedChapters = []),
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
        sliver: SliverToBoxAdapter(child: ComicInfo(details: comicDetails)),
      ),
      ComicChapters(
        comicDetails: comicDetails,
        onOpenChapter: (chapter) => _read(comicDetails, chapter.slug),
        onToggleSelected: _toggleSelected,
        isSelected: _isSelected,
        isSelecting: _selectedChapters.isNotEmpty,
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
    final c = Dotline.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DotSpace.s4,
        DotSpace.s5,
        DotSpace.s4,
        0,
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: DotlineText.title.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
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
