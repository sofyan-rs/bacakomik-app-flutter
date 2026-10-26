import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/presentation/widgets/comic_card.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Cover grid used by Explore, search and bookmarks: 3 columns on phones,
/// more on wide screens (cells stay about 150 wide). Each cell is a 2:3
/// cover plus [textHeight] of text under it.
class CoverGridSliver extends StatelessWidget {
  const CoverGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.textHeight = ComicCard.textHeight,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double textHeight;

  static const _maxCellWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / _maxCellWidth).floor().clamp(3, 8);
          final cellWidth = (width - DotSpace.s3 * (columns - 1)) / columns;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: DotSpace.s3,
              mainAxisSpacing: DotSpace.s5,
              mainAxisExtent: cellWidth * 3 / 2 + textHeight,
            ),
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
            ),
          );
        },
      ),
    );
  }
}

/// [CoverGridSliver] of [ComicCard]s.
class ComicGridSliver extends StatelessWidget {
  const ComicGridSliver({super.key, required this.comics});

  final List<Comic> comics;

  @override
  Widget build(BuildContext context) {
    return CoverGridSliver(
      itemCount: comics.length,
      textHeight: comics.any((c) => ComicCard.hasChapter(c.latestChapter))
          ? ComicCard.textHeight
          : ComicCard.textHeightWithoutChapter,
      itemBuilder: (context, index) {
        final comic = comics[index];
        return ComicCard(
          title: comic.title,
          cover: comic.coverImg,
          chapter: comic.latestChapter,
          type: comic.type,
          slug: comic.slug,
        );
      },
    );
  }
}

/// Loads the next page when [controller] nears the end, up to [maxPage].
/// Call [reset] when the first page is requested again.
class NextPageTrigger {
  NextPageTrigger({
    required this.controller,
    required this.onNextPage,
    required this.isLoading,
    this.maxPage = 10,
  }) {
    controller.addListener(_onScroll);
  }

  final ScrollController controller;
  final void Function(int page) onNextPage;
  final bool Function() isLoading;
  final int maxPage;

  var _page = 1;

  void reset() => _page = 1;

  void _onScroll() {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels < position.maxScrollExtent - 300) return;
    if (isLoading() || _page >= maxPage) return;
    _page++;
    onNextPage(_page);
  }
}

/// Loader shown under a list while the next page loads.
class LoadMoreSliver extends StatelessWidget {
  const LoadMoreSliver({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: visible
          ? const Padding(
              padding: EdgeInsets.all(DotSpace.s5),
              child: Center(child: DotLoader()),
            )
          : const SizedBox(height: DotSpace.s4),
    );
  }
}
